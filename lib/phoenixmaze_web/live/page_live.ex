defmodule PhoenixmazeWeb.PageLive do
  use PhoenixmazeWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto text-center mt-20">
      <div class="bg-black bg-opacity-50 rounded-2xl p-10 max-w-xl mx-auto">
        <h1 class="text-5xl font-bold mb-10 text-green-500 tracking-wider">MAZE ADVENTURE</h1>
        <div class="space-y-6">
          <p class="text-green-300 text-xl mb-6">
            Start your maze adventure through 20 challenging levels!
          </p>
          <div class="flex flex-col space-y-4">
            <button
              phx-click="start_maze"
              class="bg-green-600 text-white text-xl px-8 py-4 rounded-lg hover:bg-green-700 transition-colors duration-300 transform hover:scale-105 shadow-lg hover:shadow-green-500/50"
            >
              Start Level 1
            </button>
          </div>
          <div class="mt-10 text-green-400 text-sm">
            <p>Navigate through increasingly complex mazes</p>
            <p>Starting from 5x5 up to 25x25</p>
            <p>Complete all 20 levels to become a maze master!</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("start_maze", _params, socket) do
    {:noreply, push_navigate(socket, to: "/maze?level=1")}
  end
end
