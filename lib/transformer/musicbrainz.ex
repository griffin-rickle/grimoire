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
    Enum.map(api_response, &album_to_triples/1)
  end

  def album_to_triples(record) do
    filename = String.replace(Map.get(record, "title", UUID.uuid4()), " ", "_")
    File.write("/tmp/#{filename}.json", Jason.encode!(record))
  end
end
