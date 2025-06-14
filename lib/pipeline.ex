require Logger
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
      {headers, data_stream} =
        File.stream!(path)
        |> CsvStream.stream()
    
      tasks =
        data_stream
        |> Stream.map(fn x -> Enum.zip(headers, x) |> Map.new() end)
        |> Stream.map(&CsvToRdf.to_triples(&1, subject_key))
        |> Stream.chunk_every(batch_size)
        |> Enum.map(fn batch ->
          Task.Supervisor.async(Grimoire.TaskSupervisor, fn ->
            start = System.monotonic_time(:millisecond)

            GraphPusher.push(batch, nil)
            
            duration = System.monotonic_time(:millisecond) - start
            Logger.info("Pushed batch of #{length(batch)} triples in #{duration}ms")
          end)
        end)
    
      Enum.each(tasks, fn task ->
        Task.await(task, 60_000)
      end)
    
      {:stop, :normal, state}
  end
end
