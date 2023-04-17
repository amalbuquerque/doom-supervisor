defmodule DoomSupervisorWeb.CurrentUser do
  @moduledoc """
  Checks whether there's already a "doom_user_id" cookie.

  If not, it generates a new user ID value and sets it as the "doom_user_id" cookie.

  It then uses it as the current user ID, placing it on the `conn.assigns.current_user_id`.
  """

  @behaviour Plug

  alias Plug.Conn

  @cookie_user_id_key "doom_supervisor_user_id"
  @current_user_session_key "current_user_id"

  @impl true
  def init(_) do
    []
  end

  @impl true
  def call(conn, _opts) do
    conn = Plug.Conn.fetch_cookies(conn)

    case conn.cookies[@cookie_user_id_key] do
      nil ->
        set_new_user_id_cookie(conn)

      user_id ->
        store_user_id(conn, user_id)
    end
  end

  defp set_new_user_id_cookie(conn) do
    new_user_id = :crypto.strong_rand_bytes(16) |> Base.encode32(padding: false)

    conn
    |> Conn.put_resp_cookie(@cookie_user_id_key, new_user_id)
    |> store_user_id(new_user_id)
  end

  defp store_user_id(conn, user_id) do
    conn
    |> Conn.put_session(@current_user_session_key, user_id)
    |> Conn.assign(:current_user_id, user_id)
  end
end
