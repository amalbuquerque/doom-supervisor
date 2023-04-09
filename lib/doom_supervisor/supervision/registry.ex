defmodule DoomSupervisor.Supervision.Registry do
  @doc """
  Wrapper around Registry that we use to know when:
  - A process was spawned (since its name was registered)
  - A process was killed (since its name was unregistered)

  Use it like this:
  ```
  pid = DoomSupervisor.Supervision.Registry.whereis_name({:demon, 2})

  DoomSupervisor.Supervision.Monster.kill({:demon, 2})
  DoomSupervisor.Supervision.Monster.kill({:demon, 2}, :normal)
  ```
  """

  alias DoomSupervisor.GameServer

  require Logger

  @registry_name Application.compile_env(:doom_supervisor, :registry_name)

  def register_name(name, pid) do
    Logger.info("Registering #{inspect(pid)} as #{inspect(name)}...")

    case name do
      {monster, supervised_number} when is_integer(supervised_number) ->
        GameServer.spawn_supervised_monster(monster, supervised_number, pid)

      {monster, _unique_id} ->
        GameServer.spawn_monster(monster, pid)
    end

    GameServer.track_process(pid)
    Registry.register_name({@registry_name, name}, pid)
  end

  def unregister_name(name) do
    pid = whereis_name(name)

    Logger.info("*Un*registering #{inspect(pid)} as #{inspect(name)}...")

    Registry.unregister_name({@registry_name, name})
  end

  def whereis_name(name) do
    Registry.whereis_name({@registry_name, name})
  end

  def send(name, message) do
    Registry.send({@registry_name, name}, message)
  end
end
