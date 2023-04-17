defmodule DoomSupervisor.Supervision.DynamicControl do
  alias DoomSupervisor.Actions
  alias DoomSupervisor.Supervision.Registry, as: MonsterRegistry

  @doc """
  Searches the DoomSupervisor.Actions.allowed_monsters/0 list.
  """
  def monster_pid(user_id) do
    user_id
    |> possible_process_names()
    |> Enum.map(&MonsterRegistry.whereis_name/1)
    |> Enum.find(&is_pid/1)
  end

  defp possible_process_names(user_id) do
    Enum.map(Actions.allowed_monsters(), &{&1, user_id})
  end
end
