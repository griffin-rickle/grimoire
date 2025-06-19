require Logger
defmodule Grimoire.Stages.Batcher do
  use GenStage

  def start_link(opts) do
    [name: name, batch_size: batch_size] = opts
    GenStage.start_link(__MODULE__, batch_size, name: name)
  end

  def init(batch_size) do
    Logger.info("Batcher Init")
    {:producer_consumer, {[], batch_size}}
  end

  def handle_events(triples, _from, {buf, batch_size}) do
    Logger.debug("Handling events in Batcher")
    all = buf ++ triples

    groups = Enum.chunk_every(all, batch_size)
    {emit, [remainder]} = Enum.split(groups, -1)
    {:noreply, emit, {remainder, batch_size}}
  end
end
