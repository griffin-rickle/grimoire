defmodule Grimoire.Fetcher.MusicBrainz do
  @base_url "https://musicbrainz.org/ws/2"

  def start(parent) do
    spawn(fn -> loop(parent) end)
  end
  defp loop(parent) do
    receive do
      { :musicbrainz, genre, transform_pid } ->
        fetch_all(parent, genre, transform_pid, 0)
        loop(parent)
    end
  end

  defp fetch_all(parent, genre, transform_pid, offset) do
    case fetch(genre, offset) do
      {:ok, {count, recordings}} ->
        send(transform_pid, {:musicbrainz, recordings})

        num_processed = length(recordings)
        new_offset = offset + num_processed

        if new_offset < count do
          Process.sleep(1000)
          fetch_all(parent, genre, transform_pid, new_offset)
        else
          send(parent, {:done, self(), count})
        end

      {:error, reason} ->
        send(parent, {:error, self(), reason})
    end
  end

  def fetch(genre, offset \\ nil) do
    query = URI.encode("tag:#{genre}")
    url = case offset do
      nil -> "#{@base_url}/recording?query=#{query}&fmt=json"
      _ -> "#{@base_url}/recording?query=#{query}&fmt=json&offset=#{offset}"
    end

    headers = [
      {'User-Agent', 'Grimoire/0.1 (rickleg93@gmail.com)'}
    ]

    case :httpc.request(:get, {to_charlist(url), headers}, [], []) do
      {:ok, {{_, 200, 'OK'}, _resp_headers, body}} ->
        api_response = Jason.decode!(body)
        %{ "count" => count, "recordings" => recordings } = api_response
        # TODO: THIS IS SENDING TO PID 0???
        # * 1st argument: invalid destination

        # (erts 14.2.5.9) :erlang.send(0, [%{"artist-credit" =>  ...
        # send(transform_pid, {:musicbrainz, recordings})
        {:ok, {count, recordings}}
      {:ok, {{_, status, _}, _, _}} ->
        {:error, "HTTP status #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
