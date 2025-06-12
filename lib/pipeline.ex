alias Grimoire.Pipeline.Destination.GraphPusher
alias Grimoire.Pipeline.Source.CsvStream
alias Grimoire.Pipeline.Transform.CsvToRdf
defmodule Grimoire.Pipeline do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(csv_path: path, batch_size: batch_size, subject_key: subject_key) do
    send(self(), {:start_pipeline, path, batch_size, subject_key})
    {:ok, %{}}
  end

  @impl true
  def handle_info({:start_pipeline, path, batch_size, subject_key}, state) do
    {headers, data_stream} = File.stream!(path)
      |> CsvStream.stream()
    
    data_stream
      |> Stream.map(fn x -> Enum.zip(headers, x) |> Map.new() end)
      |> Stream.map(&CsvToRdf.to_triples(&1, subject_key))
      |> Stream.chunk_every(batch_size)
      |> Task.async_stream(&GraphPusher.push(&1, nil), max_concurrency: 4)
      |> Stream.run()

    {:stop, :normal, state}
  end
end
