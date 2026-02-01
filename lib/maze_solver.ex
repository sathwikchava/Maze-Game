defmodule MazeSolver do
  @moduledoc """
  Provides A* and backtracking solutions for a maze.

  The maze is assumed to be a list of lists, where each inner list represents a row.
  A cell value of 0 indicates an open space, and 1 indicates a wall.
  """

  defstruct position: nil, g: 0, h: 0, f: 0, parent: nil

  @doc """
  Finds a path from `start` to `goal` using the A* algorithm.

  Returns a list of positions representing the path, or an empty list if no path is found.
  """
  def astar(maze, start, goal) do
    start_node = %MazeSolver{
      position: start,
      g: 0,
      h: heuristic(start, goal),
      f: heuristic(start, goal),
      parent: nil
    }

    goal_node = %MazeSolver{position: goal}
    astar_loop([start_node], [], maze, goal_node)
  end

  defp astar_loop([], _closed_list, _maze, _goal), do: []  # No path found

  defp astar_loop(open_list, closed_list, maze, goal) do
    # Select the node with the lowest f value.
    current_node = Enum.min_by(open_list, & &1.f)

    if current_node.position == goal.position do
      build_path(current_node)
    else
      open_list = List.delete(open_list, current_node)
      closed_list = [current_node | closed_list]

      {open_list, _} =
        Enum.reduce(generate_children(current_node, maze), {open_list, closed_list}, fn child, {open_acc, closed_acc} ->
          if Enum.any?(closed_acc, fn node -> node.position == child.position end) do
            {open_acc, closed_acc}
          else
            tentative_g = current_node.g + 1
            child = %MazeSolver{
              child
              | g: tentative_g,
                h: heuristic(child.position, goal.position),
                f: tentative_g + heuristic(child.position, goal.position),
                parent: current_node
            }

            open_acc =
              case Enum.find(open_acc, fn node -> node.position == child.position end) do
                nil ->
                  [child | open_acc]
                existing_node ->
                  if tentative_g < existing_node.g do
                    List.delete(open_acc, existing_node) |> List.insert_at(0, child)
                  else
                    open_acc
                  end
              end

            {open_acc, closed_acc}
          end
        end)

      astar_loop(open_list, closed_list, maze, goal)
    end
  end

  defp generate_children(node, maze) do
    directions = [{0, -1}, {0, 1}, {-1, 0}, {1, 0}]

    directions
    |> Enum.flat_map(fn {dx, dy} ->
      new_position = {elem(node.position, 0) + dx, elem(node.position, 1) + dy}
      if valid_position?(new_position, maze) do
        [%MazeSolver{parent: node, position: new_position}]
      else
        []
      end
    end)
  end


  defp valid_position?({x, y}, maze) do
    row = Enum.at(maze, x)
    row != nil and
      y >= 0 and y < length(row) and
      Enum.at(row, y) == 0
  end

  defp heuristic({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  defp build_path(node) do
    build_path_helper(node, [])
  end

  defp build_path_helper(nil, path), do: Enum.reverse(path)
  defp build_path_helper(%MazeSolver{parent: parent, position: position}, path) do
    build_path_helper(parent, [position | path])
  end

  @doc """
  Solves the maze using a simple backtracking (depth-first search) algorithm.

  Returns `{:ok, path}` if a path is found, or `:error` if not.
  """
  def backtrack(maze, position, goal, path \\ []) do
    if position == goal do
      {:ok, path ++ [position]}
    else
      {x, y} = position

      # If the cell is a wall, return error.
      if Enum.at(Enum.at(maze, x), y) == 1 do
        :error
      else
        # Mark current cell as visited by setting it to 1.
        maze = mark_visited(maze, position)
        directions = [{0, -1}, {0, 1}, {-1, 0}, {1, 0}]

        Enum.reduce_while(directions, :error, fn {dx, dy}, _acc ->
          new_position = {x + dx, y + dy}

          if valid_position?(new_position, maze) do
            case backtrack(maze, new_position, goal, path ++ [position]) do
              {:ok, result} -> {:halt, {:ok, result}}
              :error -> {:cont, :error}
            end
          else
            {:cont, :error}
          end
        end)
      end
    end
  end

  defp mark_visited(maze, {x, y}) do
    row = Enum.at(maze, x)
    new_row = List.replace_at(row, y, 1)
    List.replace_at(maze, x, new_row)
  end
end
