defmodule Grimoire.Pipelines.Musicbrainz do
  use GenServer
  require Logger
  alias Grimoire.Config.PipelineConfig
  alias Grimoire.Stages.Source.CSV_Source
  alias Grimoire.Stages.Transform.To_RDF
  alias Grimoire.Stages.Batcher
  alias Grimoire.Stages.Destination.Graph

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, opts)

  @impl true
  def init(_opts) do
    Logger.info("Starting musicbrainz pipeline")

    config = PipelineConfig.load(:musicbrainz)
    Logger.debug("CSV Path: #{config.csv_path}")
    Logger.debug("Batch Size: #{config.batch_size}")

    children = [
      {CSV_Source, [name: :csv_source, csv_path: config.csv_path]},
      {To_RDF, [name: :to_rdf]},
      {Batcher, [name: :batcher, batch_size: config.batch_size]},
      {Graph, [name: :graph]}
    ]
    opts = [strategy: :one_for_one, name: Grimoire.PipelineSupervisor]
    {:ok, _pid} = Supervisor.start_link(children, opts)
    # Start the pipeline stages dynamically

    # Dynamically subscribe the pipeline
    Logger.info("Subscribing pipeline stages...")
    GenStage.sync_subscribe(:to_rdf, to: :csv_source, max_demand: 10_000, min_demand: 7500)
    GenStage.sync_subscribe(:batcher, to: :to_rdf, max_demand: 10_000, min_demand: 7500)
    GenStage.sync_subscribe(:graph, to: :batcher, max_demand: 10_000, min_demand: 7500)
    Logger.info("Finished subscribing pipeline stages...")

    Logger.info("Source: #{inspect(Process.whereis(:csv_source))}")
    Logger.info("To_RDF: #{inspect(Process.whereis(:to_rdf))}")
    Logger.info("batcher: #{inspect(Process.whereis(:batcher))}")
    Logger.info("graph: #{inspect(Process.whereis(:graph))}")
    # Monitor all stages
    refs = monitor_all_stages([:csv_source, :to_rdf, :batcher, :graph])
    {:ok, %{refs: refs}}
  end

  defp monitor_all_stages(names) do
    Enum.map(names, fn name ->
      pid = Process.whereis(name)
      ref = Process.monitor(pid)
      {ref, name}
    end)
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, %{refs: refs} = state) do
    case Enum.find(refs, fn {r, _name} -> r == ref end) do
      {^ref, name} ->
        Logger.info("Pipeline stage #{inspect(name)} exited with reason: #{inspect(reason)}")
        new_refs = Enum.reject(refs, fn {r, _} -> r == ref end)

        if new_refs == [] do
          Logger.info("All pipeline stages have exited. Shutting down Musicbrainz pipeline.")
          {:stop, :normal, %{state | refs: []}}
        else
          {:noreply, %{state | refs: new_refs}}
        end

      nil ->
        Logger.warning("Received :DOWN for unknown ref #{inspect(ref)}")
        {:noreply, state}
    end
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.info("Musicbrainz pipeline has completed. Application will shut down.")
    :ok
  end
end
