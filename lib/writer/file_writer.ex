
require Logger
defmodule Grimoire.Writer.FileWriter do
  def start(parent) do
    spawn(fn -> loop(parent) end)
  end
  defp loop(parent) do
    receive do
      { :writer, base_dir, records, id_path, fetch_type, offset} ->
        Logger.debug("Write Start")
        send(parent, {:write_start})
        process_albums_response(parent, base_dir, records, id_path)
        send(parent, {:write_done, fetch_type, offset})
        Logger.debug("Write End")
        loop(parent)
      msg ->
        Logger.warning("Writer received a signal it did not recognize")
        Logger.warning(msg)
        loop(parent)
    end
  end

  def process_albums_response(parent, base_dir, api_response, id_path) do
    batch_count = api_response |>
    Enum.map(fn x ->
      Task.async(fn -> write_record(parent, base_dir, x, id_path) end)
    end) |>
    Enum.map(&Task.await/1) |>
    Enum.count
    Logger.debug("Write of #{batch_count} finished")
  end

  def write_record(parent, base_dir, record, id_path) do
    filename = case ExJSONPath.eval(record, id_path) do
      {:ok, v_id} -> v_id
      {:error, reason} -> send(parent, {:write_error, [record], id_path, reason})
    end
    filepath = "#{base_dir}/#{filename}.json"
    File.write("#{filepath}", Jason.encode!(record))
  end
end
