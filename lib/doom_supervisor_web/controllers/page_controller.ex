defmodule DoomSupervisorWeb.PageController do
  use DoomSupervisorWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
