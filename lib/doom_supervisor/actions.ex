defmodule DoomSupervisor.Actions do
  @moduledoc """
  Module responsible for creating the network payload that will be sent to the game.

  Valid messages:
    - Spawning a monster;
    - Killing a monster.
  """

  @padding "\0"
  @payload_length 50

  @allowed_monsters [
    :cacodemon
  ]

  def spawn_monster(monster, identifier) when monster in @allowed_monsters do
    build_payload("spawn", monster, identifier)
  end

  def build_payload(action, monster, identifier) do
    [action, monster, identifier]
    |> Enum.join(":")
    |> String.pad_trailing(@payload_length, @padding)
  end
end
