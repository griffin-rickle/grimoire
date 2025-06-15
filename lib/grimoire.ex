require Logger
defmodule Grimoire do
  @moduledoc """
  Documentation for `Grimoire`.
  """
alias Grimoire.Pipeline.Destination.GraphPusher
alias Grimoire.Pipeline.Source.Batcher
alias Grimoire.Pipeline.Transform.CsvToRdf
alias Grimoire.Pipeline

  @doc """
  Hello world.
  """
  def main(_args) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)
    Application.ensure_all_started(:public_key)
    Application.ensure_all_started(:retry)

    {:ok, _} = Finch.start_link(
      name: GrimoireFinch,
      pools: %{
        default: [size: 100, count: 10]
      }
    )

    consumer = start_pipeline(
      "/opt/grimoire-data/musicbrainz-canonical-dump-20250603-080003/canonical/canonical_musicbrainz_data.csv",
      1000,
      120
    )

    ref = Process.monitor(consumer)

    receive do
      {:DOWN, ^ref, :process, ^consumer, reason} ->
        Logger.info("Pipeline finished with reason: #{inspect(reason)}")
        :ok
    end
  end

  def start_pipeline(path, batch_size, rpm_target) do
    rate = %{min_interval: div(60_000_000, rpm_target)} # μs between batches
    {:ok, producer} = Pipeline.start_link(path)
    {:ok, transformer} = CsvToRdf.start_link()
    {:ok, batcher} = Batcher.start_link(batch_size)
    {:ok, consumer} = GraphPusher.start_link(rate)
  
    GenStage.sync_subscribe(transformer, to: producer)
    GenStage.sync_subscribe(batcher, to: transformer)
    GenStage.sync_subscribe(consumer, to: batcher)

    consumer
  end
end
