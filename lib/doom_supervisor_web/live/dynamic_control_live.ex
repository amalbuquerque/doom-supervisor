defmodule DoomSupervisorWeb.DynamicControlLive do
  use DoomSupervisorWeb, :live_view

  alias DoomSupervisor.GameServer
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

  def handle_event("spawn_" <> monster, _value, %{assigns: %{can_spawn: true}} = socket) do
    monster_class = String.to_existing_atom(monster)

    {:ok, pid} = DynamicControl.dynamic_spawn(monster_class, socket.assigns.user_id)

    Process.monitor(pid)

    socket =
      socket
      |> assign(:monster, pid)
      |> assign(:can_spawn, false)

    {:noreply, socket}
  end

  def handle_event("spawn_demon", _value, socket), do: {:noreply, socket}

  def handle_event("kill_own_monster", _value, %{assigns: %{monster: pid}} = socket)
      when is_pid(pid) do
    GameServer.kill_monster_by_pid(pid)

    # no need to change the socket state
    # let's allow the :DOWN handler to do that
    {:noreply, socket}
  end

  def handle_event("kill_own_monster", _value, socket), do: {:noreply, socket}

  def handle_info({:DOWN, _ref, :process, _pid, :killed_in_game}, socket) do
    socket =
      socket
      |> assign(:monster, nil)
      |> assign(:can_spawn, true)

    {:noreply, socket}
  end
end
