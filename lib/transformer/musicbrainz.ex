defmodule Grimoire.Transformer.Musicbrainz do
  def start(parent) do
    spawn(fn -> loop(parent) end)
  end
  defp loop(parent) do
    receive do
      { :musicbrainz, records } ->
        process_albums_response(records)
        loop(parent)
      msg ->
        IO.puts("Musicbrainz Transformer received a signal it did not recognize")
        IO.inspect(msg)
        loop(parent)
    end
  end

  def process_albums_response(api_response) do
    api_response |>
    Enum.map(fn x ->
      Task.async(fn -> album_to_triples(x) end)
    end) |>
    Enum.map(&Task.await/1)
  end

  def album_to_triples(record) do
    filename = String.replace(Map.get(record, "title", UUID.uuid4()), " ", "_") <> "|" <> Map.get(record, "id")
    IO.puts("Writing #{filename}")
    File.write("/tmp/#{filename}.json", Jason.encode!(record))
  end
end
