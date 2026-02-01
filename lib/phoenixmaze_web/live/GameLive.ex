defmodule PhoenixmazeWeb.GameLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div class="game-container">
      <div class="game-header">
        <h1>Welcome to the Maze Game!</h1>
        <p>Get ready to navigate through an exciting maze!</p>
      </div>
      <div class="game-button-container">
        <button
          phx-click="navigate_to_maze"
          class="game-btn game-btn-start"
        >
          Start Game
        </button>
      </div>
    </div>
    """
  end

  @spec handle_event(String.t(), any(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("navigate_to_maze", _params, socket) do
    {:noreply, push_navigate(socket, to: "/maze")}
  end
end
