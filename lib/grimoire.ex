alias Grimoire.Writer.FileWriter, as: Writer
alias Grimoire.Fetcher.MusicBrainz, as: MBF
require Logger
defmodule Grimoire do
  @moduledoc """
  Documentation for `Grimoire`.
  """

  @doc """
  Hello world.
  """
  def main(_args) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)
    Application.ensure_all_started(:public_key)
    parent = self()
    write_pid = Writer.start(parent)
    fetch_pid = MBF.start(parent)

    offset = get_offset()
    send(fetch_pid, {:musicbrainz, "technical death metal", write_pid, offset})
    Logger.info("Starting fetch at offset #{offset}")

    wait_for_messages(%{fetch_done: false, offset: offset, write_done: false})
  end

  defp wait_for_messages(%{fetch_done: true, offset: _, write_done: true}), do: :ok

  defp wait_for_messages(state) do
    receive do
      {:fetch_count, fetch_source, count} -> 
        Logger.debug("Successfully fetched #{count} from #{fetch_source}")
        wait_for_messages(state)
      {:fetch_done, fetch_source, count} ->
        Logger.info("Finished fetching #{count} records from #{fetch_source}")
        wait_for_messages(%{state | fetch_done: true})
      {:fetch_error, fetch_type, reason} ->
        Logger.error("Fetching error reported from #{fetch_type}: #{reason}")
        Process.sleep(2000)
      {:write_start} ->
        wait_for_messages(%{state | write_done: false})
      {:write_done, fetch_type, offset} -> 
        Logger.info("Finished writing batch with offset #{offset}.")
        record_batch_success(fetch_type, offset)
        wait_for_messages(%{state | write_done: true, offset: offset})
      {:write_error, record, id_path, error} ->
        Logger.error("Writing records failed; error: #{error}")
        System.halt()
    end
  end

  defp get_offset() do
    case File.read("/opt/grimoire-data/musicbrainz/.offset") do
      {:ok, file_contents} -> 
        case Integer.parse(file_contents) do
          {offset, _} -> offset
        end
      {:error, reason} -> 
        Logger.warning("Error reading offset file: #{reason}")
        0
    end
  end

  defp record_batch_success(fetch_type, offset) do
    filepath = "/opt/grimoire-data/#{fetch_type}/.offset"
    Logger.debug("Recording batch success: #{offset}, #{filepath}")
    File.touch(filepath)
    case File.write(filepath, Integer.to_string(offset)) do
      {:error, reason} -> Logger.error("Could not write offset to #{filepath}: #{reason}")
      _ -> :ok
    end
  end
end
