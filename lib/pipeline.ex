require Logger
alias Grimoire.Pipeline.Source.CsvStream
defmodule Grimoire.Pipeline do
  use GenStage

  def start_link(csv_path) do
    GenStage.start_link(__MODULE__, {:producer, csv_path: csv_path}, name: __MODULE__)
  end

  @impl true
  def init({:producer, csv_path: path}) do
    {headers, data_stream} =
      File.stream!(path)
      |> CsvStream.stream()
  
    {:producer, %{headers: headers, data_stream: data_stream}}
  end

  @impl true
  def handle_demand(demand, %{headers: headers, data_stream: data_stream} = state) when demand > 0 do
    Logger.debug("Handling demand in Pipeline source")
    events = data_stream
      |> Stream.take(demand)
      |> Stream.map(fn x -> Enum.zip(headers, x) |> Map.new() end)
      |> Enum.to_list()
    new_stream = Stream.drop(data_stream, demand)
    {:noreply, events, %{state | data_stream: new_stream}}
  end
end
