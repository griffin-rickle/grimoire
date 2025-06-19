require Logger
defmodule Grimoire.Util.CSV_File do

  def stream_with_headers(stream) do
    header = stream
      |> Stream.take(1)
      |> Enum.to_list()
      |> List.first()
      |> String.trim_trailing("\n")
      |> NimbleCSV.RFC4180.parse_string(skip_headers: false)
      |> Enum.to_list()
      |> List.first()

    # Can't skip headers here because we already consumed the first row of the stream when getting the headers
    data_stream = stream
      |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
      |> Stream.map(fn x -> Enum.zip(header, x) |> Map.new() end)

    data_stream
  end 
end

