defmodule DoomSupervisor.GameServer do
  @moduledoc """
  GenServer responsible to manage the game port and interact with it.

  Remember, to reset the map, you can use `changemap *` within the game's console.

  Use it like:

  ```
  {:ok, game_server} = DoomSupervisor.GameServer.start_link([])

  DoomSupervisor.GameServer.start_game()
  DoomSupervisor.GameServer.start_game(keep_corpses: true)

  DoomSupervisor.GameServer.spawn_monster(:zombie_man, "id123")
  DoomSupervisor.GameServer.spawn_monster(:shotgun_guy, "id123")
  DoomSupervisor.GameServer.spawn_monster(:zombie_man, "id456")

  {:ok, supervisor} = DoomSupervisor.Supervision.Supervisor.start_link(:demon, 8, :one_for_one)
  {:ok, supervisor} = DoomSupervisor.Supervision.Supervisor.start_link(:demon, 8, :one_for_all)
  {:ok, supervisor} = DoomSupervisor.Supervision.Supervisor.start_link(:demon, 8, :rest_for_one)
  Supervisor.stop(supervisor, :shutdown)

  all_monster_pids = for i <- 1..8, do: DoomSupervisor.Supervision.Registry.whereis_name({:demon, i}) |> inspect()

  Enum.each(all_monster_pids, &DoomSupervisor.GameServer.kill_monster_by_pid/1)

  DoomSupervisor.GameServer.get_player_position()
  ```
  """

  alias DoomSupervisor.Actions
  alias DoomSupervisor.Actions.Position
  alias DoomSupervisor.Game
  alias DoomSupervisor.GameStarter
  alias DoomSupervisor.Netevent
  alias DoomSupervisor.Supervision.Monster

  require Logger

  use GenServer

  @name __MODULE__
  @prefix "**ELIXIR**"
  @localhost "127.0.0.1"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(_) do
    {:ok, %Game{}}
  end

  def start_game(opts \\ []) do
    GenServer.call(@name, {:start_game, opts})
  end

  @doc """
  Spawns a monster near the player.

  Note that it might be a wall position, not allowing the monster to move.

  DoomSupervisor.GameServer.spawn_monster(:cacodemon, "id123")
  DoomSupervisor.GameServer.spawn_monster(:imp, "id456")
  DoomSupervisor.GameServer.spawn_monster(:zombie_man, "id456")
  DoomSupervisor.GameServer.spawn_monster(:mancubus, "id456")
  DoomSupervisor.GameServer.spawn_monster(:hell_knight, "id456")
  """
  def spawn_monster(monster, identifier) do
    payload = Actions.spawn_monster(monster, identifier)

    GenServer.call(@name, {:send_netevent, payload})
  end

  @doc """
  Kills a monster by pid.

  DoomSupervisor.GameServer.kill_monster_by_pid("id123")
  DoomSupervisor.GameServer.kill_monster_by_pid("id456")
  """
  def kill_monster_by_pid(identifier) do
    payload = Actions.kill_monster_by_identifier(identifier)

    GenServer.call(@name, {:send_netevent, payload})
  end

  @doc """
  Gets player position.

  DoomSupervisor.GameServer.get_player_position()
  """
  def get_player_position do
    payload = Actions.get_player_position()

    GenServer.call(@name, {:send_netevent, payload})
  end

  @doc """
  Spawns monster at a given position.

  DoomSupervisor.GameServer.spawn_monster_at(:demon, "id123", {699, 752, 56})
  DoomSupervisor.GameServer.spawn_monster_at(:demon, "id123", {747, 139, -32})
  DoomSupervisor.GameServer.spawn_monster_at(:imp, "id123", {747, 139, -32})
  """
  def spawn_monster_at(monster, identifier, {_x, _y, _z} = position) do
    position = Position.from_tuple(position)
    payload = Actions.spawn_monster_at(monster, identifier, position)

    GenServer.call(@name, {:send_netevent, payload})
  end

  @doc """
  Spawns a supervised monster to illustrate a given supervision strategy.

  Depending on the monster number, it will spawn a monster on the corresponding map position.

  Use it like this:

  ```
  DoomSupervisor.GameServer.spawn_supervised_monster(:demon, 8, "pid8")
  DoomSupervisor.GameServer.spawn_supervised_monster(:demon, 3, "pid3")
  DoomSupervisor.GameServer.spawn_supervised_monster(:cacodemon, 2, "pid2")
  DoomSupervisor.GameServer.spawn_supervised_monster(:zombie_man, 1, "pid1")
  ```
  """
  def spawn_supervised_monster(monster, number, identifier) when number in 1..8 do
    position = supervised_position(number)

    Logger.info(
      "Spawning supervised #{monster} no.#{number}, identifier=#{inspect(identifier)}..."
    )

    spawn_monster_at(monster, inspect(identifier), position)
  end

  def track_process(pid) do
    GenServer.call(@name, {:track_process, pid})
  end

  @impl true
  def handle_call({:start_game, opts}, _from, state) do
    port = GameStarter.call(opts)

    {:reply, :ok, %{state | port: port, started: true}}
  end

  @impl true
  def handle_call({:send_netevent, _payload}, _from, %{started: false} = state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:send_netevent, payload}, _from, %{started: true, udp_port: udp_port} = state) do
    Netevent.send_netevent(payload, @localhost, udp_port)

    {:reply, :ok, state}
  end

  @doc """
  Tracking processes once they are registered so that we know once they are killed.

  Check the {:DOWN, ...} handler below.
  """
  @impl true
  def handle_call({:track_process, pid}, _from, state) do
    Process.monitor(pid)

    {:reply, :ok, state}
  end

  @doc """
  :DOWN handler for processes/monsters that were killed in game.pid()

  Since they were killed in game, we don't need to kill them there again and we simple NOOP.
  """
  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, :killed_in_game}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    Logger.info(
      "Process #{inspect(pid)} died due to #{reason}. Killing the corresponding monster..."
    )

    pid
    |> inspect()
    |> Actions.kill_monster_by_identifier()
    |> Netevent.send_netevent(@localhost, state.udp_port)

    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:data, @prefix <> data}}, %{port: port} = state) do
    Logger.info("************* #{data}")

    state =
      data
      |> String.trim()
      |> handle_game_output(state)

    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    Logger.info(data)

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  # [info] *************  Elixir UDP port on: 6764
  defp handle_game_output("Elixir UDP port on: " <> udp_port, state) do
    {udp_port, _rest} = Integer.parse(udp_port)

    Logger.info("Game is listening on port: #{udp_port}")

    %{state | udp_port: udp_port}
  end

  # [info] *************  #PID<0.514.0> Demon died/spawned at (950, -199, -32)
  defp handle_game_output("#PID<" <> _rest = payload, state) do
    [string_pid, _monster, event | _] = String.split(payload, " ")

    with "died" <- event,
         pid = pid_from_string(string_pid),
         true <- Process.alive?(pid) do
      Monster.kill(pid, :killed_in_game)
    end

    state
  end

  defp handle_game_output(_output, state), do: state

  defp supervised_position(number) do
    x_step = 100
    x_offset = (number - 1) * x_step

    {1050 - x_offset, -199, -32}
  end

  # turns "#PID<0.514.0>" string into correct PID
  defp pid_from_string("#PID" <> wrapped_pid = _string_pid) do
    wrapped_pid
    |> String.trim_leading("<")
    |> String.trim_trailing(">")
    |> IEx.Helpers.pid()
  end
end
