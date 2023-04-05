defmodule DoomSupervisor.GameServer do
  @moduledoc """
  GenServer responsible to manage the game port and interact with it.

  Use it like:

  ```
  {:ok, game_server} = DoomSupervisor.GameServer.start_link([])
  DoomSupervisor.GameServer.start_game()
  DoomSupervisor.GameServer.spawn_monster(:zombie_man, "id123")
  DoomSupervisor.GameServer.spawn_monster(:shotgun_guy, "id123")
  DoomSupervisor.GameServer.spawn_monster(:zombie_man, "id456")
  DoomSupervisor.GameServer.get_player_position()
  ```
  """

  alias DoomSupervisor.Actions
  alias DoomSupervisor.Actions.Position
  alias DoomSupervisor.Game
  alias DoomSupervisor.GameStarter
  alias DoomSupervisor.Netevent

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

  def start_game do
    GenServer.call(@name, :start_game)
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
  """
  def spawn_monster_at(monster, identifier, {_x, _y, _z} = position) do
    position = Position.from_tuple(position)
    payload = Actions.spawn_monster_at(monster, identifier, position)

    GenServer.call(@name, {:send_netevent, payload})
  end

  @impl true
  def handle_call(:start_game, _from, state) do
    port = GameStarter.call()

    {:reply, :ok, %{state | port: port}}
  end

  @impl true
  def handle_call({:send_netevent, payload}, _from, %{udp_port: udp_port} = state) do
    Netevent.send_netevent(payload, @localhost, udp_port)

    {:reply, :ok, state}
  end

  @impl true
  def handle_info({port, {:data, @prefix <> data}}, %{port: port} = state) do
    Logger.info("************* #{data}")

    state = data
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

  defp handle_game_output(_output, state), do: state
end
