defmodule DoomSupervisor.GameStarter do
  @moduledoc """
  This module serves to start the Doom game with the right options.
  """
  require Logger

  defp stdbuf_path() do
    System.find_executable("stdbuf")
  end

  # Three ways to locate the gzdoom (get it from zdoom.org) binary:
  defp game_binary_path() do
    System.get_env("GZDOOM") || System.find_executable("gzdoom") || raise "Couldn't find gzdoom"
  end

  defp base_dir() do
    File.cwd!()
    |> Path.absname()
  end

  defp game_params() do
    [
      "-host",
      "1",
      "-deathmatch",
      "+developer",
      "1",
      "+sv_cheats",
      "1",
      "+vid_fullscreen",
      "0",
      "+vid_activeinbackground",
      "1",
      "-warp",
      "01",
      "-iwad",
      "DOOM2.wad",
      "-file",
      Path.join(base_dir(), "pk3"),
      "-nomonsters"
    ]
  end

  @doc """
  Starts the Doom game and returns a `port`.

  iex> DoomSupervisor.GameStarter.call(keep_corpses: true)

  iex> DoomSupervisor.GameStarter.call(keep_corpses: false)
  """
  @spec call(Keyword.t()) :: port()
  def call(opts) do
    game_params = game_params() ++ extra_params(opts)

    case stdbuf_path() do
      nil ->
        Port.open({:spawn_executable, game_binary_path()}, [:binary, :line, args: game_params])

      stdbuf ->
        Port.open({:spawn_executable, stdbuf}, [
          :binary,
          :line,
          args: ["-oL", game_binary_path() | game_params]
        ])
    end
  end

  defp extra_params([]), do: []
  defp extra_params([{:keep_corpses, true} | rest]), do: extra_params(rest)

  defp extra_params([{:keep_corpses, false} | rest]) do
    ["-file", Path.join(base_dir(), "wads/fading_corpses.wad") | extra_params(rest)]
  end

  defp extra_params([{:udp_port, port} | rest]) do
    ["-port", "#{port}" | extra_params(rest)]
  end

  defp extra_params([other | rest]) do
    Logger.error("Invalid option: #{inspect(other)}")
    extra_params(rest)
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
