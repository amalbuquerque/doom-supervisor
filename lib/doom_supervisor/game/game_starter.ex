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
    System.get_env("DOOM") || System.find_executable("zandronum-server") || Path.join([System.user_home!(), "zandronum", "zandronum-server"])
  end

  defp game_client_binary_path() do
    String.replace_suffix(game_binary_path(), "-server", "")
  end

  defp base_dir() do
    File.cwd!()
    |> Path.absname()
  end

  defp game_params() do
    [
      "-stdout",
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
    server_params = game_params ++ ["-host", "2"]
    client_params = ["-connect", "127.0.0.1:#{Keyword.get(opts, :udp_port, 10666)}"]

    server = case stdbuf_path() do
      nil ->
        Port.open({:spawn_executable, game_binary_path()}, [:binary, :line, args: server_params])

      stdbuf ->
        Port.open({:spawn_executable, stdbuf}, [
          :binary,
          :line,
          args: ["-oL", game_binary_path() | server_params]
        ])
    end

    _client = Port.open({:spawn_executable, game_client_binary_path()}, [:binary, :line, args: client_params])
    server
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
