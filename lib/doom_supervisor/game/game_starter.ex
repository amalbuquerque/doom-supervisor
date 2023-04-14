defmodule DoomSupervisor.GameStarter do
  @moduledoc """
  This module serves to start the Doom game with the right options.
  """

  @game_binary_path "/Users/andre/projs/personal/gzdoom/build/Debug/gzdoom.app/Contents/MacOS/gzdoom"
  @game_params [
    "-host",
    "1",
    "-deathmatch",
    "+developer",
    "1",
    "+sv_cheats",
    "1",
    "+vid_fullscreen",
    "0",
    "-warp",
    "01",
    "-iwad",
    "DOOM2.wad",
    "-file",
    "/Users/andre/projs/personal/doom_supervisor/pk3",
    "-nomonsters"
  ]

  @doc """
  Starts the Doom game and returns a `port`.

  iex> DoomSupervisor.GameStarter.call(keep_corpses: true)

  iex> DoomSupervisor.GameStarter.call(keep_corpses: false)
  """
  @spec call(Keyword.t()) :: port()
  def call(opts) do
    game_params =
      case Keyword.get(opts, :keep_corpses, false) do
        true ->
          @game_params

        _ ->
          nil

          @game_params ++
            ["-file", "/Users/andre/projs/personal/doom_supervisor/wads/fading_corpses.wad"]
      end

    Port.open({:spawn_executable, @game_binary_path}, [:binary, args: game_params])
  end

  def receive_stuff(port) do
    receive do
      {^port, {:data, data}} ->
        IO.puts("Received from: #{inspect(port)} the following:\n#{data}")

      other_stuff ->
        IO.puts("Received #{inspect(other_stuff)}")
    end

    receive_stuff(port)
  end
end
