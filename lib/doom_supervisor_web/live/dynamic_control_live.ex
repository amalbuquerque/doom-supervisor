defmodule DoomSupervisorWeb.DynamicControlLive do
  use DoomSupervisorWeb, :live_view

  alias DoomSupervisor.Supervision.DynamicControl

  require Logger

  def mount(_params, %{"current_user_id" => user_id}, socket) do
    Logger.info("USER #{user_id}")

    existing_process = DynamicControl.monster_pid(user_id)

    socket =
      socket
      |> assign(:can_spawn, is_nil(existing_process))
      |> assign(:user_id, user_id)

    {:ok, socket}
  end

  def handle_event("spawn_demon", _value, socket) do
    # socket.assigns.user_id

    # TODO: Start dynamically-supervised monster

    {:noreply, assign(socket, :can_spawn, false)}
  end

  def handle_event("kill_own_monster", _value, socket) do
    # TODO: Kill the monster

    {:noreply, assign(socket, :can_spawn, true)}
  end
end
