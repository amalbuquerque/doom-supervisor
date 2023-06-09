defmodule DoomSupervisor.Supervision.Monster do
  @moduledoc """
  Basic GenServer that serves as the process that will be represented
  as a monster inside a Doom game.

  It only knows how to start, and provides a convenience `kill/2` function.

  The only thing of remark is that it uses a custom registry to register
  its name once it starts, and to deregister it once it dies.

  Use it like:

  ```
  {:ok, pid} = DoomSupervisor.Supervision.Monster.start_link({:demon, 1})

  ^pid = DoomSupervisor.Supervision.Registry.whereis_name({:demon, 1})

  :ok = DoomSupervisor.Supervision.Monster.kill({:demon, 1}, :normal)

  :undefined = DoomSupervisor.Supervision.Registry.whereis_name({:demon, 1})
  ```
  """

  use GenServer

  require Logger

  alias DoomSupervisor.Supervision.Registry, as: MonsterRegistry

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  @impl true
  def init(name) do
    Logger.info("Starting monster #{inspect(name)}...")
    Process.sleep(500)

    {:ok, []}
  end

  def kill(pid_or_process_name, reason \\ :brutal_kill)

  def kill(pid, reason) when is_pid(pid) do
    GenServer.stop(pid, reason)
  end

  def kill(process_name, reason) do
    process_name
    |> via_tuple()
    |> GenServer.stop(reason)
  end

  defp via_tuple(name), do: {:via, MonsterRegistry, name}
end
