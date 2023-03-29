defmodule DoomSupervisor.Actions do
  @moduledoc """
  Module responsible for creating the network payload that will be sent to the game.

  Valid messages:
    - Spawning a monster;
    - Killing a monster.

  Check monsters list here: https://zdoom.org/wiki/Classes:Doom
  """

  @padding "\0"
  @payload_length 50

  @monsters [
    cacodemon: "Cacodemon",
    demon: "Demon",
    imp: "DoomImp",
    cyberdemon: "Cyberdemon",
    zombie_man: "ZombieMan",
    mancubus: "Fatso",
    hell_knight: "HellKnight"
  ]

  @allowed_monsters Keyword.keys(@monsters)

  def spawn_monster(monster, identifier) when monster in @allowed_monsters do
    build_payload("spawn", Keyword.fetch!(@monsters, monster), identifier)
  end

  def build_payload(action, monster, identifier) do
    [action, monster, identifier]
    |> Enum.join(":")
    |> String.pad_trailing(@payload_length, @padding)
  end
end
