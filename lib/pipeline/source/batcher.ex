require Logger
defmodule Grimoire.Pipeline.Source.Batcher do
  alias Grimoire.Pipeline.Transform.CsvToRdf
  use GenStage

  def start_link(batch_size), do: GenStage.start_link(__MODULE__, batch_size, name: __MODULE__)

  def init(batch_size), do:
    {:producer_consumer, {[], batch_size}, subscribe_to: [{CsvToRdf, max_demand: 500, min_demand: 100}]}

  def handle_events(triples, _from, {buf, batch_size}) do
    Logger.debug("Handling events in Batcher")
    all = buf ++ triples

    # {batches, remainder} = Enum.split(all, div(length(all), batch_size)*batch_size)
    #
    # groups = for chunk <- Enum.chunk_every(batches, batch_size), do: chunk
    # {:noreply, groups, {remainder, batch_size}}

    groups = Enum.chunk_every(all, batch_size)
    {emit, [remainder]} = Enum.split(groups, -1)
    {:noreply, emit, {remainder, batch_size}}
  end
end
