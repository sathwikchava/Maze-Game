defmodule PhoenixmazeWeb.MazeLive.MazeLogic do
  @moduledoc """
  Contains the maze movement logic, timer updates, maze generation, and pathfinding.
  """

  defstruct [
    :maze,
    :rows,
    :cols,
    :object_position,
    :countdown,
    :timer_percentage,
    :timer_color,
    :game_won,
    :ghost_position,
    :player_points,
    :ghost_points,
    :winner
  ]

  @type t :: %__MODULE__{
          maze: list(list(tuple())),
          rows: integer(),
          cols: integer(),
          object_position: {integer(), integer()},
          countdown: integer(),
          timer_percentage: float(),
          timer_color: String.t(),
          game_won: boolean(),
          ghost_position: {integer(), integer()},
          player_points: integer(),
          ghost_points: integer(),
          winner: atom()
        }

        def calculate_new_position(key, {row, col}, maze, rows, cols) do
          current_cell = get_cell(maze, row, col)

          new_position =
            case key do
              "ArrowUp" when row > 0 ->
                if not elem(current_cell, 0), do: {row - 1, col}, else: {row, col}

              "ArrowDown" when row < rows - 1 ->
                if not elem(current_cell, 3), do: {row + 1, col}, else: {row, col}

              "ArrowLeft" when col > 0 ->
                if not elem(current_cell, 2), do: {row, col - 1}, else: {row, col}

              "ArrowRight" when col < cols - 1 ->
                if not elem(current_cell, 1), do: {row, col + 1}, else: {row, col}

              _ ->
                {row, col}
            end

          # Add logging to help diagnose
          IO.puts("Move input: #{key}")
          IO.puts("Current position: {#{row}, #{col}}")
          IO.puts("New position: #{inspect(new_position)}")

          new_position
        end

  def get_cell(maze, row, col) do
    maze |> Enum.at(row) |> Enum.at(col)
  end

  def generate_maze_from_gen(row, col) do
    Phoenixmaze.MazeGen.generate_new_maze(row, col)
    |> Phoenixmaze.MazeGen.format_walls()
  end

  def find_path(maze, start_pos, end_pos, rows, cols) do
    queue = :queue.from_list([{start_pos, [start_pos]}])
    visited = MapSet.new([start_pos])

    do_find_path(queue, visited, maze, end_pos, rows, cols)
  end

  defp do_find_path(queue, visited, maze, end_pos, rows, cols) do
    case :queue.out(queue) do
      {{:value, {current_pos, path}}, queue_rest} ->
        if current_pos == end_pos do
          {:ok, path}
        else
          neighbors = get_valid_neighbors(current_pos, maze, rows, cols)
          unvisited_neighbors = Enum.filter(neighbors, &(!MapSet.member?(visited, &1)))

          new_queue = Enum.reduce(unvisited_neighbors, queue_rest, fn pos, acc ->
            :queue.in({pos, path ++ [pos]}, acc)
          end)

          new_visited = Enum.reduce(unvisited_neighbors, visited, &MapSet.put(&2, &1))
          do_find_path(new_queue, new_visited, maze, end_pos, rows, cols)
        end

      {:empty, _} ->
        {:error, :no_path}
    end
  end

  defp get_valid_neighbors({row, col}, maze, rows, cols) do
    current_cell = get_cell(maze, row, col)

    [
      if(not elem(current_cell, 0) and row > 0, do: {row - 1, col}),
      if(not elem(current_cell, 3) and row < rows - 1, do: {row + 1, col}),
      if(not elem(current_cell, 2) and col > 0, do: {row, col - 1}),
      if(not elem(current_cell, 1) and col < cols - 1, do: {row, col + 1})
    ]
    |> Enum.filter(&(&1 != nil))
  end

  def is_valid_move(maze, {current_row, current_col}, {next_row, next_col}, rows, cols) do
    cond do
      next_row < 0 or next_row >= rows or next_col < 0 or next_col >= cols ->
        false

      true ->
        current_cell = get_cell(maze, current_row, current_col)

        cond do
          next_row < current_row -> not elem(current_cell, 0)
          next_row > current_row -> not elem(current_cell, 3)
          next_col < current_col -> not elem(current_cell, 2)
          next_col > current_col -> not elem(current_cell, 1)
          true -> false
        end
    end
  end

  def reset_game(state, maze, interval) do
    %{
      state
      | maze: maze,
        object_position: {0, 0},
        countdown: div(interval, 1000),
        timer_percentage: 100,
        timer_color: "green",
        game_won: false,
        player_points: 0,
        ghost_points: 0
    }
  end

  def update_timer(state, new_countdown, interval) do
    percentage = new_countdown / div(interval, 1000) * 100
    color = get_timer_color(new_countdown)
    %{state | countdown: new_countdown, timer_percentage: percentage, timer_color: color}
  end

  defp get_timer_color(countdown) do
    cond do
      countdown > 10 -> "green"
      countdown > 5 -> "orange"
      true -> "red"
    end
  end
end
