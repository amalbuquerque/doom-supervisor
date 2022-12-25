defmodule DoomSupervisor.Zlib do
  @moduledoc """
  Module to wrap the Zlib for compress and uncompress.

  To decompress compressed payload logged by Doom:

  ```
  hex_compressed_payload = "0578DA6362DCF3C92D23352727BF3CBF282785819901093032010092BE063A"

  # drop the first byte, "05" (it's what indicates the payload is compressed)
  "05" <> hex_compressed_payload = hex_compressed_payload

  compressed = :binary.decode_hex(hex_compressed_payload)

  [uncompressed] = DoomSupervisor.Zlib.uncompress(compressed)
  [
    <<2, 1, 188, 242, 70, 104, 101, 108, 108, 111, 119, 111, 114, 108, 100, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2>>
  ]

  IO.inspect("helloworld", binaries: :as_binaries)
  <<104, 101, 108, 108, 111, 119, 111, 114, 108, 100>>

  byte_size(uncompressed)
  31
  ```

  Note the `helloworld` NetEvent message sent from the 6th byte onwards.

  We have 5 bytes before the payload:

  ```
  <<2, 1, 188, 242, 70>>
  ```

  We have 16 bytes after the payload:

  ```
  <<0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2>>
  ```
  """

  @doc """
  Z=zlib:open(),
  zlib:deflateInit(Z),
  CData=zlib:deflate(Z2, lists:seq(1,100), finish),
  zlib:deflateEnd(Z).

  compressed = DoomSupervisor.Zlib.compress("foobar")
  """
  def compress(data, level \\ :default) do
    z_instance = :zlib.open()
    # default compression level
    :ok = :zlib.deflateInit(z_instance, level)

    compressed_data = :zlib.deflate(z_instance, data, :finish)

    :zlib.deflateEnd(z_instance)

    compressed_data
  end

  @doc """
  Z=zlib:open(),
  zlib:inflateInit(Z),
  Data=zlib:Inflate(Z, CData),
  zlib:inflateEnd(Z).

  data = DoomSupervisor.Zlib.uncompress(compressed)
  """
  def uncompress(compressed) do
    z_instance = :zlib.open()

    :ok = :zlib.inflateInit(z_instance)

    data = :zlib.inflate(z_instance, compressed)

    :zlib.inflateEnd(z_instance)

    data
  end
end
