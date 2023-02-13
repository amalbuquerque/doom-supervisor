defmodule DoomSupervisor.GameServer do
  @moduledoc """
  GenServer responsible to manage the game port and interact with it.

  Use it like:

  ```
  {:ok, game_server} = DoomSupervisor.GameServer.start_link(nil)
  DoomSupervisor.GameServer.start_game()
  ```
  """

  alias DoomSupervisor.Game
  alias DoomSupervisor.GameStarter

  require Logger

  use GenServer

  @name __MODULE__
  @prefix "**ELIXIR**"

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

  @impl true
  def handle_call(:start_game, _from, state) do
    port = GameStarter.call()

    {:reply, :ok, %{state | port: port}}
  end

  @impl true
  def handle_info({port, {:data, @prefix <> data}}, %{port: port} = state) do
    Logger.info("************* #{data}")

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
end
