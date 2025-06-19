defmodule Grimoire.Stages.Source.CSV_Source do
  alias Grimoire.Util.CSV_File
  require Logger
  use GenStage
  def start_link(opts) do
    [name: name, csv_path: csv_path] = opts
    GenStage.start_link(__MODULE__, {:producer, csv_path: csv_path}, name: name)
  end

  @impl true
  def init({:producer, csv_path: csv_path}) do
    Logger.info("#{inspect(csv_path)}")
    data_stream = File.stream!(csv_path)
    |> CSV_File.stream_with_headers()

    {:producer, %{data_stream: data_stream}}
  end
  
  @impl true
  def handle_demand(demand, %{data_stream: data_stream} = state) when demand > 0 do
    Logger.debug("Handling demand in Musicbrainz pipeline source")
    events = Enum.take(data_stream, demand)
    new_stream = Stream.drop(data_stream, demand)

    {:noreply, events, %{state | data_stream: new_stream}}
  end
end
