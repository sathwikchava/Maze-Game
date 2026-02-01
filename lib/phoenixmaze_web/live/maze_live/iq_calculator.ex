defmodule PhoenixmazeWeb.MazeLive.IQCalculator do
  @moduledoc """
  Calculates player IQ based on maze performance metrics over 5-level intervals.
  """

  @base_score 100
  @min_iq 70
  @max_iq 130
  @iq_range @max_iq - @min_iq

  @type level_performance :: %{
    completion_time: float(),
    steps_taken: integer(),
    optimal_path_length: integer(),
    maze_size: integer()
  }

  @type performance_metrics :: %{
    avg_completion_time: float(),
    avg_steps: float(),
    optimal_paths_ratio: float(),
    completed_levels: integer(),
    total_levels: integer(),
    avg_maze_size: float()
  }

  @type score_breakdown :: %{
    time_score: float(),
    step_score: float(),
    completion_score: float(),
    complexity_bonus: float(),
    raw_score: float()
  }

  @doc """
  Calculates IQ score based on player performance over multiple levels.
  Returns a map containing the IQ score, detailed breakdown, and performance metrics.
  """
  @spec calculate_iq([level_performance()]) ::
    %{
      iq_score: integer(),
      breakdown: score_breakdown(),
      metrics: performance_metrics()
    }
  def calculate_iq(performances) when is_list(performances) do
    metrics = calculate_performance_metrics(performances)

    # Calculate individual components
    time_score = calculate_time_score(metrics.avg_completion_time, metrics.avg_maze_size)
    step_score = calculate_step_score(metrics.avg_steps, metrics.optimal_paths_ratio)
    completion_score = calculate_completion_score(metrics.completed_levels, metrics.total_levels)
    complexity_bonus = calculate_complexity_bonus(metrics.avg_maze_size)

    # Calculate raw score
    raw_score = @base_score + time_score + step_score + completion_score + complexity_bonus

    # Calculate final IQ
    iq_score = normalize_iq(raw_score)

    # Return detailed breakdown
    %{
      iq_score: iq_score,
      breakdown: %{
        time_score: time_score,
        step_score: step_score,
        completion_score: completion_score,
        complexity_bonus: complexity_bonus,
        raw_score: raw_score
      },
      metrics: metrics
    }
  end

  @doc """
  Calculates score based on completion time efficiency.
  """
  @spec calculate_time_score(float(), float()) :: float()
  def calculate_time_score(avg_time, avg_maze_size) do
    expected_time = avg_maze_size * 1.5  # Expected 1.5 seconds per cell
    time_ratio = avg_time / expected_time

    cond do
      time_ratio < 0.5 -> 30.0  # Exceptional performance
      time_ratio < 1.0 -> 25.0  # Very good performance
      time_ratio < 1.5 -> 20.0  # Good performance
      time_ratio < 2.0 -> 15.0  # Average performance
      time_ratio < 3.0 -> 10.0  # Below average
      true -> 5.0              # Needs improvement
    end
  end

  @doc """
  Calculates score based on movement efficiency.
  """
  @spec calculate_step_score(float(), float()) :: float()
  def calculate_step_score(avg_steps, optimal_paths_ratio) do
    efficiency_ratio = optimal_paths_ratio / avg_steps

    cond do
      efficiency_ratio > 0.95 -> 30.0  # Nearly perfect path finding
      efficiency_ratio > 0.85 -> 25.0  # Excellent path finding
      efficiency_ratio > 0.75 -> 20.0  # Good path finding
      efficiency_ratio > 0.65 -> 15.0  # Average path finding
      efficiency_ratio > 0.55 -> 10.0  # Below average
      true -> 5.0                     # Needs improvement
    end
  end

  @doc """
  Calculates score based on level completion rate.
  """
  @spec calculate_completion_score(integer(), integer()) :: float()
  def calculate_completion_score(completed, total) do
    (completed / total) * 20.0
  end

  @doc """
  Calculates bonus points based on maze complexity.
  """
  @spec calculate_complexity_bonus(float()) :: float()
  def calculate_complexity_bonus(avg_maze_size) do
    cond do
      avg_maze_size > 400 -> 20.0  # Very complex mazes (20x20)
      avg_maze_size > 225 -> 15.0  # Complex mazes (15x15)
      avg_maze_size > 100 -> 10.0  # Moderate complexity (10x10)
      avg_maze_size > 25 -> 5.0    # Simple mazes (5x5)
      true -> 0.0                  # Very simple mazes
    end
  end

  @doc """
  Calculates average performance metrics across multiple levels.
  """
  @spec calculate_performance_metrics([level_performance()]) :: performance_metrics()
  def calculate_performance_metrics([]), do: %{
    avg_completion_time: 0,
    avg_steps: 0,
    optimal_paths_ratio: 0,
    completed_levels: 0,
    total_levels: 5,
    avg_maze_size: 0
  }

  def calculate_performance_metrics(performances) do
    count = length(performances)

    sums = Enum.reduce(performances, %{
      total_time: 0,
      total_steps: 0,
      total_optimal: 0,
      total_size: 0
    }, fn perf, acc ->
      %{
        total_time: acc.total_time + perf.completion_time,
        total_steps: acc.total_steps + perf.steps_taken,
        total_optimal: acc.total_optimal + perf.optimal_path_length,
        total_size: acc.total_size + perf.maze_size
      }
    end)

    %{
      avg_completion_time: sums.total_time / count,
      avg_steps: sums.total_steps / count,
      optimal_paths_ratio: sums.total_optimal / sums.total_steps,
      completed_levels: count,
      total_levels: 5,
      avg_maze_size: sums.total_size / count
    }
  end

  @doc """
  Normalizes raw score to IQ scale (70-130).
  """
  @spec normalize_iq(float()) :: integer()
  def normalize_iq(raw_score) do
    normalized = @min_iq + (raw_score * @iq_range / 200)
    normalized
    |> max(@min_iq)
    |> min(@max_iq)
    |> round()
  end
end
