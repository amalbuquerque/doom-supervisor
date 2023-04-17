defmodule DoomSupervisor.Supervision.Supervisor do
  @moduledoc """
  Monster supervisor.

  It requires the monster, number of monsters and supervision strategy.


  Use it like this:

  ```
  {:ok, supervisor} = DoomSupervisor.Supervision.Supervisor.start_link(:demon, 8, :one_for_one)
  {:ok, supervisor} = DoomSupervisor.Supervision.Supervisor.start_link(:cacodemon, 3, :one_for_one)
  {:ok, supervisor} = DoomSupervisor.Supervision.Supervisor.start_link(:demon, 1, :one_for_one)

  Supervisor.stop(supervisor)
  ```
  """

  use Supervisor

  alias DoomSupervisor.Supervision.Monster

  def start_link(monster, how_many, strategy) do
    Supervisor.start_link(__MODULE__, {monster, how_many, strategy},
      name: process_name(monster, strategy)
    )
  end

  @impl true
  def init({monster, how_many, strategy}) do
    children =
      for i <- 1..how_many do
        monster_name = {monster, i}

        monster_child_spec(monster_name)
      end

    Supervisor.init(children, strategy: strategy)
  end

  @doc """
  Gets monster child spec.

  Use it like:
  ```
  DoomSupervisor.Supervision.Supervisor.child_spec({:zombie_man, "abc_user_id"})
  ```
  """
  def monster_child_spec({_monster, _identifier} = monster_name) do
    Supervisor.child_spec({Monster, monster_name}, id: supervision_id(monster_name))
  end

  defp process_name(monster, strategy) do
    [monster, strategy]
    |> Enum.map(&to_string/1)
    |> Enum.map(&Phoenix.Naming.camelize/1)
    |> Enum.reduce(__MODULE__, fn suffix, acc ->
      Module.concat(acc, suffix)
    end)
  end

  defp supervision_id({monster, number}) do
    [to_string(monster), "No#{number}"]
    |> Enum.map(&Phoenix.Naming.camelize/1)
    |> Enum.reduce(__MODULE__, fn suffix, acc ->
      Module.concat(acc, suffix)
    end)
  end
end
