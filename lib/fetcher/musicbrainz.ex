require Logger
defmodule Grimoire.Fetcher.MusicBrainz do
  @base_url "https://musicbrainz.org/ws/2"

  def start(parent) do
    spawn(fn -> loop(parent) end)
  end
  defp loop(parent) do
    receive do
      { :musicbrainz, genre, transform_pid} ->
        try_fetch(parent, genre, transform_pid)
        loop(parent)
      { :musicbrainz, genre, transform_pid, offset} ->
        try_fetch(parent, genre, transform_pid, offset)
        loop(parent)
    end
  end

  defp try_fetch(parent, genre, transform_pid, offset \\ nil) do
    query = URI.encode("tag:#{genre}")
    url = case offset do
      nil -> "#{@base_url}/recording?query=#{query}&fmt=json"
      _ -> "#{@base_url}/recording?query=#{query}&fmt=json&offset=#{offset}"
    end

    headers = [
      {'User-Agent', 'Grimoire/0.1 (rickleg93@gmail.com)'}
    ]

    case fetch(url, headers, 3) do
      {:ok, {count, recordings}} ->
        send(transform_pid, {:writer, "/opt/grimoire-data/musicbrainz/", recordings, "$.id", :musicbrainz, offset})
        num_processed = length(recordings)
        new_offset = offset + num_processed
        send(parent, {:fetch_count, :musicbrainz, new_offset})

        if new_offset < count do
          Process.sleep(1000)
          try_fetch(parent, genre, transform_pid, new_offset)
        else
          send(parent, {:fetch_done, :musicbrainz, count})
        end

      {:error, reason} ->
        send(parent, {:fetch_error, :musicbrainz, reason})
    end
  end

  defp fetch(_url, _headers, 0) do {:error, :max_retries_exceeded} end

  defp fetch(url, headers, retries_left) do
    case :httpc.request(:get, {to_charlist(url), headers}, [], []) do
      {:ok, {{_, 200, 'OK'}, _resp_headers, body}} ->
        api_response = Jason.decode!(body)
        %{ "count" => count, "recordings" => recordings } = api_response
        {:ok, {count, recordings}}
      {:ok, {{_, status, _}, _, _}} ->
        {:error, "HTTP status #{status}"}

      {:error, reason} ->
        Logger.warning("Request failed: #{inspect(reason)}. Retrying...")
        Process.sleep(2000)
        fetch(url, headers, retries_left - 1)
    end
  end
end
