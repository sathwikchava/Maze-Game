defmodule PhoenixmazeWeb.PageController do
  use PhoenixmazeWeb, :controller

  def home(conn, _params) do
    # Redirect to the LiveView page
    redirect(conn, to: "/")
  end
end
