defmodule PhoenixmazeWeb.MazeLive do
  use PhoenixmazeWeb, :live_view
  alias PhoenixmazeWeb.MazeLive.Timer
  alias PhoenixmazeWeb.MazeLive.MazeLogic
  alias PhoenixmazeWeb.MazeLive.IQCalculator
  require Logger

  @interval 15000000_000
  @timer_interval 1_000
  @auto_move_interval 4
  @key_throttle_delay 200

  @level_configs %{
    1 => %{rows: 5, cols: 5},
    2 => %{rows: 6, cols: 6},
    3 => %{rows: 7, cols: 7},
    4 => %{rows: 8, cols: 8},
    5 => %{rows: 9, cols: 9},
    6 => %{rows: 10, cols: 10},
    7 => %{rows: 11, cols: 11},
    8 => %{rows: 12, cols: 12},
    9 => %{rows: 13, cols: 13},
    10 => %{rows: 14, cols: 14},
    11 => %{rows: 15, cols: 15},
    12 => %{rows: 16, cols: 16},
    13 => %{rows: 17, cols: 17},
    14 => %{rows: 18, cols: 18},
    15 => %{rows: 19, cols: 19},
    16 => %{rows: 20, cols: 20},
    17 => %{rows: 21, cols: 21},
    18 => %{rows: 22, cols: 22},
    19 => %{rows: 23, cols: 23},
    20 => %{rows: 25, cols: 25}
  }

  def mount(params, _session, socket) do
    level = (params["level"] || "1") |> String.to_integer()
    %{rows: rows, cols: cols} = Map.get(@level_configs, level, @level_configs[1])

    if connected?(socket) do
      :timer.send_interval(@interval, :regenerate_maze)
      :timer.send_interval(@timer_interval, :tick)
    end

    {:ok,
     assign(socket,
       maze: nil,
       rows: rows,
       cols: cols,
       level: level,
       object_position: nil,
       countdown: nil,
       timer_percentage: nil,
       timer_color: nil,
       maze_dimensions_set: true,
       points: 0,
       show_success: false,
       auto_move: false,
       path: [],
       current_path_index: 0,
       last_move: nil,
       last_move_timestamp: nil,
       steps_taken: 0,
       auto_move_steps: 0,
       start_time: nil,
       solution_time: nil,
       best_time: nil,
       best_steps: nil,
       current_iq: nil,
       last_iq_calculation: 0,
       level_performances: %{},
       auto_move_stats: %{
         steps: nil,
         time: nil
       },
       performance_metrics: %{
         avg_completion_time: 0,
         avg_steps: 0,
         optimal_paths: 0,
         completed_levels: 0,
         total_levels: 25,
         maze_sizes: []
       }
     ) |> generate_initial_maze()}
  end

  def handle_event("move_object", %{"key" => key}, socket) do
    if socket.assigns.auto_move do
      {:noreply, socket}
    else
      current_time = :os.system_time(:millisecond)
      start_time = socket.assigns.start_time || current_time

      can_move =
        is_nil(socket.assigns.last_move_timestamp) or
        current_time - socket.assigns.last_move_timestamp >= @key_throttle_delay

      if socket.assigns.maze_dimensions_set and can_move do
        new_position =
          MazeLogic.calculate_new_position(
            key,
            socket.assigns.object_position,
            socket.assigns.maze,
            socket.assigns.rows,
            socket.assigns.cols
          )

        if new_position != socket.assigns.object_position do
          show_success = new_position == {socket.assigns.rows - 1, socket.assigns.cols - 1}

          points = if show_success do
            base_points = 100 * socket.assigns.level
            time_taken = (current_time - start_time) / 1000
            time_bonus = max(0, round(500 * socket.assigns.level / time_taken))
            steps = socket.assigns.steps_taken + 1
            optimal_steps = length(socket.assigns.path)
            step_bonus = if steps <= optimal_steps * 1.2 do
              round(300 * socket.assigns.level)
            else
              round(100 * socket.assigns.level)
            end
            socket.assigns.points + base_points + time_bonus + step_bonus
          else
            socket.assigns.points
          end

          solution_time = if show_success, do: (current_time - start_time) / 1000, else: nil

          best_time = cond do
            is_nil(socket.assigns.best_time) -> solution_time
            not is_nil(solution_time) and solution_time < socket.assigns.best_time -> solution_time
            true -> socket.assigns.best_time
          end

          steps = socket.assigns.steps_taken + 1
          best_steps = cond do
            is_nil(socket.assigns.best_steps) -> if show_success, do: steps, else: nil
            show_success and steps < socket.assigns.best_steps -> steps
            true -> socket.assigns.best_steps
          end

          {:noreply,
           socket
           |> assign(:object_position, new_position)
           |> assign(:last_move, new_position)
           |> assign(:last_move_timestamp, current_time)
           |> assign(:show_success, show_success)
           |> assign(:points, points)
           |> assign(:steps_taken, steps)
           |> assign(:start_time, start_time)
           |> assign(:solution_time, solution_time)
           |> assign(:best_time, best_time)
           |> assign(:best_steps, best_steps)}
        else
          {:noreply, socket}
        end
      else
        {:noreply, socket}
      end
    end
  end

  def handle_event("toggle_auto_move", _params, socket) do
    if socket.assigns.auto_move do
      {:noreply, assign(socket, auto_move: false)}
    else
      start_time = :os.system_time(:millisecond)
      path = MazeLogic.find_path(
        socket.assigns.maze,
        socket.assigns.object_position,
        {socket.assigns.rows - 1, socket.assigns.cols - 1},
        socket.assigns.rows,
        socket.assigns.cols
      )

      case path do
        {:ok, found_path} ->
          Process.send_after(self(), :auto_move_step, @auto_move_interval)
          {:noreply,
           assign(socket,
             auto_move: true,
             path: found_path,
             current_path_index: 1,
             start_time: start_time,
             auto_move_steps: 0
           )}

        {:error, _reason} ->
          {:noreply, socket}
      end
    end
  end

  def handle_event("next_level", _params, socket) do
    next_level = socket.assigns.level + 1

    level_performance = %{
      completion_time: socket.assigns.solution_time,
      steps_taken: socket.assigns.steps_taken,
      maze_size: socket.assigns.rows * socket.assigns.cols,
      optimal_path: length(socket.assigns.path)
    }

    updated_performances = Map.put(
      socket.assigns.level_performances,
      socket.assigns.level,
      level_performance
    )

    current_level = socket.assigns.level
    {current_iq, last_iq_calculation} = cond do
      rem(current_level, 5) == 0 || current_level == 20 ->
        start_level = max(1, current_level - 4)
        metrics = calculate_performance_metrics(
          updated_performances,
          start_level,
          current_level
        )
        {IQCalculator.calculate_iq(metrics), current_level}
      true ->
        {socket.assigns.current_iq, socket.assigns.last_iq_calculation}
    end

    if next_level <= 20 do
      {:noreply,
       socket
       |> assign(:level_performances, updated_performances)
       |> assign(:current_iq, current_iq)
       |> assign(:last_iq_calculation, last_iq_calculation)
       |> push_navigate(to: "/maze?level=#{next_level}")}
    else
      {:noreply, push_navigate(socket, to: "/")}
    end
  end

  def handle_event("play_again", _params, socket) do
    new_maze = MazeLogic.generate_maze_from_gen(socket.assigns.rows, socket.assigns.cols)

    {:noreply,
     socket
     |> assign(:maze, new_maze)
     |> assign(:object_position, {0, 0})
     |> assign(:countdown, div(@interval, 1000))
     |> assign(:timer_percentage, 100)
     |> assign(:timer_color, "green")
     |> assign(:show_success, false)
     |> assign(:auto_move, false)
     |> assign(:path, [])
     |> assign(:current_path_index, 0)
     |> assign(:last_move, nil)
     |> assign(:last_move_timestamp, nil)
     |> assign(:steps_taken, 0)
     |> assign(:start_time, nil)
     |> assign(:solution_time, nil)}
  end

  def handle_info(:auto_move_step, socket) do
    if socket.assigns.auto_move and socket.assigns.current_path_index < length(socket.assigns.path) do
      next_position = Enum.at(socket.assigns.path, socket.assigns.current_path_index)
      current_time = :os.system_time(:millisecond)

      valid_move = MazeLogic.is_valid_move(
        socket.assigns.maze,
        socket.assigns.object_position,
        next_position,
        socket.assigns.rows,
        socket.assigns.cols
      )

      if valid_move do
        show_success = next_position == {socket.assigns.rows - 1, socket.assigns.cols - 1}
        points = if show_success, do: socket.assigns.points + 1, else: socket.assigns.points

        solution_time = if show_success, do: (current_time - socket.assigns.start_time) / 1000, else: nil
        auto_steps = socket.assigns.auto_move_steps + 1

        auto_move_stats = if show_success do
          %{steps: auto_steps, time: solution_time}
        else
          socket.assigns.auto_move_stats
        end

        if not show_success do
          Process.send_after(self(), :auto_move_step, @auto_move_interval)
        end

        {:noreply,
         socket
         |> assign(:object_position, next_position)
         |> assign(:current_path_index, socket.assigns.current_path_index + 1)
         |> assign(:show_success, show_success)
         |> assign(:points, points)
         |> assign(:auto_move_steps, auto_steps)
         |> assign(:solution_time, solution_time)
         |> assign(:auto_move_stats, auto_move_stats)}
      else
        {:noreply, assign(socket, auto_move: false)}
      end
    else
      {:noreply, assign(socket, auto_move: false)}
    end
  end

  def handle_info(:tick, socket) do
    if socket.assigns.maze_dimensions_set and not is_nil(socket.assigns.countdown) do
      {new_countdown, percentage, color} =
        Timer.calculate_timer_values(socket.assigns.countdown, @interval)

      {:noreply,
       socket
       |> assign(:countdown, new_countdown)
       |> assign(:timer_percentage, percentage)
       |> assign(:timer_color, color)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:regenerate_maze, socket) do
    if socket.assigns.maze_dimensions_set do
      new_maze = MazeLogic.generate_maze_from_gen(socket.assigns.rows, socket.assigns.cols)

      {:noreply,
       socket
       |> assign(:maze, new_maze)
       |> assign(:object_position, {0, 0})
       |> assign(:countdown, div(@interval, 1000))
       |> assign(:timer_percentage, 100)
       |> assign(:timer_color, "green")
       |> assign(:show_success, false)
       |> assign(:auto_move, false)
       |> assign(:path, [])
       |> assign(:current_path_index, 0)
       |> assign(:last_move, nil)
       |> assign(:last_move_timestamp, nil)
       |> assign(:steps_taken, 0)
       |> assign(:start_time, nil)
       |> assign(:solution_time, nil)}
    else
      {:noreply, socket}
    end
  end







  defp generate_initial_maze(socket) do
    maze = MazeLogic.generate_maze_from_gen(socket.assigns.rows, socket.assigns.cols)

    assign(socket,
      maze: maze,
      object_position: {0, 0},
      countdown: div(@interval, 1000),
      timer_percentage: 100,
      timer_color: "green",
      steps_taken: 0,
      start_time: nil,
      solution_time: nil)
  end

  defp calculate_performance_metrics(performances, start_level, end_level) do
    relevant_performances =
      start_level..end_level
      |> Enum.map(&Map.get(performances, &1))
      |> Enum.filter(&(!is_nil(&1)))

    completed_levels = length(relevant_performances)

    if completed_levels > 0 do
      %{
        avg_completion_time: avg_completion_time(relevant_performances),
        avg_steps: avg_steps(relevant_performances),
        optimal_paths: avg_optimal_paths(relevant_performances),
        completed_levels: completed_levels,
        total_levels: 5,
        maze_sizes: Enum.map(relevant_performances, & &1.maze_size)
      }
    else
      %{
        avg_completion_time: 0,
        avg_steps: 0,
        optimal_paths: 0,
        completed_levels: 0,
        total_levels: 5,
        maze_sizes: []
      }
    end
  end

  defp avg_completion_time(performances) do
    times = Enum.map(performances, & &1.completion_time)
    Enum.sum(times) / length(times)
  end

  defp avg_steps(performances) do
    steps = Enum.map(performances, & &1.steps_taken)
    Enum.sum(steps) / length(steps)
  end

  defp avg_optimal_paths(performances) do
    optimal_steps = Enum.map(performances, & &1.optimal_path)
    Enum.sum(optimal_steps) / length(optimal_steps)
  end

end
