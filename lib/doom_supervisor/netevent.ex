defmodule DoomSupervisor.Netevent do
  @moduledoc """
  Module that abstracts reading and sending ZDoom NetEvent payloads.

  It does the low-level communication with the game through an UDP port
  opened beforehand.
  """

  alias DoomSupervisor.Zlib

  @client_udp_range 49152..65535

  @doc """
  Expects the payload formatted in hex with its prefix,
  to understand whether the payload is compressed or not.
  """
  def decode_netevent("05" <> compressed_payload) do
    compressed = :binary.decode_hex(compressed_payload)

    [uncompressed] = Zlib.uncompress(compressed)

    uncompressed
  end

  def decode_netevent(<<_prefix::16-bits>> <> payload) do
    :binary.decode_hex(payload)
  end

  @doc """
  Expects the payload as a string, and will return the compressed payload, including the compressed prefix, as a bitstring, ready to be sent with UDP.
  """
  def encode_netevent(payload) when is_binary(payload) do
    # TODO: Need to understand how to wrap the payload with header and padding, before compressing it
    raise "Not implemented yet"
  end

  @doc """
  Sends payload to a given UDP host:port.

  Sending a compressed NetEvent that was copied from the ZDoom logs (note the payload as the leading `05` byte):

  ```
  hex_compressed_payload = "0578DA6362DCF3C92D23352727BF3CBF282785819901093032010092BE063A"

  compressed = :binary.decode_hex(hex_compressed_payload)

  DoomSupervisor.Netevent.send_netevent(compressed, "127.0.0.1", 5029)
  DoomSupervisor.Netevent.send_netevent(compressed, "127.0.0.1", 42259)
  DoomSupervisor.Netevent.send_netevent("helloworld", "127.0.0.1", 6754)


  # Guest sending PreGamePacket to join:
  # PREFAKE = 0x30 (defined as `#define PRE_FAKE 0x30`)
  # PRE_CONNECT = 0 (first int enum value)
  # we now PreGamePacket has size of 2 bytes (check PreSend call)
  payload = :binary.decode_hex("3000")

  {:ok, client_socket} = DoomSupervisor.Netevent.send_netevent(payload, "127.0.0.1", 6742)
  flush() # to receive the response

  # we then need to send back the ack (check https://github.com/amalbuquerque/gzdoom/blob/c7e425f759b41994424ffb20c0fc1522daa9e162/src/common/engine/i_net.cpp#L656)
  # if (packet.Fake == PRE_FAKE && packet.Message == PRE_ALLHEREACK)
  # PREFAKE = 0x30 (defined as `#define PRE_FAKE 0x30`)
  # PRE_ALLHEREACK = 6 (seventh int enum value)
  ack_payload = :binary.decode_hex("3006")
  ack_payload = :binary.decode_hex("3001")

  :gen_udp.send(client_socket, ack_payload)
  {:ok, client_socket} = DoomSupervisor.Netevent.send_netevent(ack_payload, "127.0.0.1", 5029)

  # The PREGET packets sent by Guest to host when joining (3000, 3006, 3001, 3006, 3001), the suffix is exactly the same here:
  # PRINT: PREGET!!! 3000 0001F87F00005014BEB9F77F0000C3094E00F87F0000F78F9B7FBE88C441A81DBEB9F77F0000000000000000000000000000000000007014BEB9F77F000099773300
  # PRINT: PREGET!!! 3006 0001F87F00005014BEB9F77F0000C3094E00F87F0000F78F9B7FBE88C441A81DBEB9F77F0000000000000000000000000000000000007014BEB9F77F000099773300
  # PRINT: PREGET!!! 3001 0001F87F00005014BEB9F77F0000C3094E00F87F0000F78F9B7FBE88C441A81DBEB9F77F0000000000000000000000000000000000007014BEB9F77F000099773300
  # PRINT: PREGET!!! 3006 0001F87F00005014BEB9F77F0000C3094E00F87F0000F78F9B7FBE88C441A81DBEB9F77F0000000000000000000000000000000000007014BEB9F77F000099773300
  # PRINT: PREGET!!! 3001 0001F87F00005014BEB9F77F0000C3094E00F87F0000F78F9B7FBE88C441A81DBEB9F77F0000000000000000000000000000000000007014BEB9F77F000099773300

  # What I'm sending manually with Elixir (3000, 3006):
  # PRINT: PREGET!!! 3000
  # 0001F87F00005034F6AFF77F0000C3094E00F87F00002934FF4CBE88C441A83DF6AFF77F0000000000000000000000000000000000007034F6AFF77F000099773300
  # PRINT: PREGET!!! 3006
  # 0001F87F00005034F6AFF77F0000C3094E00F87F0000FC39D458BE88C441A83DF6AFF77F0000000000000000000000000000000000007034F6AFF77F000099773300
  ```

  ```
  DEM_NETEVENT
  s = ReadString(stream);
  int argn = ReadByte(stream);
  int arg[3] = { 0, 0, 0 };
  for (int i = 0; i < 3; i++)
      arg[i] = ReadLong(stream);
  bool manual = !!ReadByte(stream);
  ```

  The network packet starts with the message, ends with `\0` as a proper
  string, then it's argn (an int, 16-bits, 2 bytes), 3 args that are long (each long is 32-bits, 4 bytes)
  According to: https://en.cppreference.com/w/cpp/language/types
  - message, blablabla\0 (variable size, ends with \0)
  - argn, \0\0 (2 bytes)
  - 3 args, \0\0\0\0 (4 bytes) each
  Example message: "blablabla\0|\0\0|\0\0\0\0|\0\0\0\0|\0\0\0\0" (split with |)
  Example message: "blablabla\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0" (without |)

  The `send_netevent/3` function below is currently spawning a cacodemon.

  ```
  udp_port = 6770
  DoomSupervisor.Netevent.send_netevent("abigmonsterohno:123:456:pid.1.2.3\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", "127.0.0.1", udp_port)
  ```
  """
  def send_netevent(payload, host_ip, port) when is_integer(port) do
    client_port = Enum.random(@client_udp_range)

    open_opts = [:binary, {:active, true}]

    with {:ok, socket} <- :gen_udp.open(client_port, open_opts) do
      send_payload_to_socket(socket, host_ip, port, payload)
    end
  end

  def send_payload_to_socket(socket, host_ip, port, payload) do
    dest_ip = ip_from_ip_string(host_ip)

    :ok = :gen_udp.send(socket, dest_ip, port, payload)

    {:ok, socket}
  end

  defp ip_from_ip_string(ip_string) do
    ip_string
    |> String.split(".")
    |> Enum.map(&Integer.parse/1)
    |> Enum.map(fn
      {number, ""} ->
        number

      _ ->
        raise "Bad IP string"
    end)
    |> List.to_tuple()
  end
end
