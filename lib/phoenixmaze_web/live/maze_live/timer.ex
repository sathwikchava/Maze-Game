defmodule PhoenixmazeWeb.MazeLive.Timer do
  def calculate_timer_values(current_countdown, interval) do
    new_countdown = max(0, current_countdown - 1)
    total_time = div(interval, 1000)
    percentage = new_countdown / total_time * 100

    color =
      cond do
        percentage > 75 -> "green"
        percentage > 50 -> "yellow"
        percentage > 25 -> "orange"
        true -> "red"
      end

    {new_countdown, percentage, color}
  end
end
