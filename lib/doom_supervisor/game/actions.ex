defmodule DoomSupervisor.Actions do
  @moduledoc """
  Module responsible for creating the network payload that will be sent to the game.

  Valid messages:
    - Spawning a monster;
    - Killing a monster.

  Check monsters list here: https://zdoom.org/wiki/Classes:Doom
  """

  defmodule Position do
    @moduledoc false

    @___ "notUsed"

    defstruct [:x, :y, :z]

    def from_tuple({x, y, z}), do: %__MODULE__{x: x, y: y, z: z}

    def new(x, y, z), do: %__MODULE__{x: x, y: y, z: z}

    def to_payload(%__MODULE__{} = position) do
      position
      |> Map.from_struct()
      |> Map.values()
      |> Enum.join(",")
      |> then(&"(#{&1})")
    end

    def to_payload(_), do: @___
  end

  @padding "\0"
  @payload_length 50

  @monsters [
    cacodemon: "Cacodemon",
    demon: "Demon",
    imp: "DoomImp",
    cyberdemon: "Cyberdemon",
    zombie_man: "ZombieMan",
    shotgun_guy: "ShotgunGuy",
    mancubus: "Fatso",
    hell_knight: "HellKnight"
  ]

  @allowed_monsters Keyword.keys(@monsters)

  @___ "notUsed"

  @doc """
  Returns something like: `"spawn:cacodemon:pid123:notUsed"`
  """
  def spawn_monster(monster, identifier) when monster in @allowed_monsters do
    build_payload("spawn", Keyword.fetch!(@monsters, monster), identifier, @___)
  end

  @doc """
  Returns something like: `"spawn_at:demon:pid456:(x,y,z)"`
  """
  def spawn_monster_at(monster, identifier, %Position{} = position)
      when monster in @allowed_monsters do
    build_payload("spawn_at", Keyword.fetch!(@monsters, monster), identifier, position)
  end

  @doc """
  Returns something like: `"kill:notUsed:pid789:notUsed"`
  """
  def kill_monster_by_identifier(identifier) do
    build_payload("kill", @___, identifier, @___)
  end

  @doc """
  Returns something like: `"get_pos:notUsed:notUsed:notUsed"`
  """
  def get_player_position do
    build_payload("get_pos", @___, @___, @___)
  end

  def build_payload(action, monster, identifier, position) do
    position = Position.to_payload(position)

    [action, monster, identifier, position]
    |> Enum.join(":")
    |> String.pad_trailing(@payload_length, @padding)
  end
end
