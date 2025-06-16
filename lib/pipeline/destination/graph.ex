require Logger
defmodule Grimoire.Pipeline.Destination.GraphPusher do
  use Retry
  use GenStage
  alias Grimoire.Pipeline.Source.Batcher
  require Logger

  @endpoint "http://localhost:3030/mb/data"
  @auth {"Authorization", "Basic " <> Base.encode64("admin:")}

  def start_link(opts), do: GenStage.start_link(__MODULE__, opts, name: __MODULE__)

  def init(rate_config) do
    {:consumer, rate_config, subscribe_to: [{Batcher, max_demand: 5000, min_demand: 2500}]}
  end

  def handle_events(batches, _from, rate) do
    Logger.debug("Handling events in GraphPusher")
    Enum.each(batches, fn batch ->
      start = System.monotonic_time(:millisecond)
      push(batch, nil)

      duration = System.monotonic_time(:millisecond) - start
      Logger.info("Batch of #{length(batch)} pushed in #{duration} ms")

      # if duration < rate.min_interval do
      #   sleep = rate.min_interval - duration
      #   Logger.debug("sleeping for #{inspect(sleep)}")
      #   :timer.sleep(sleep)
      # end
    end)
    {:noreply, [], rate}
  end

  def push(triples, endpoint) when is_binary(endpoint) do
    push_to_endpoint(triples, endpoint)
  end

  def push(triples, endpoint) when is_nil(endpoint) do
    push_to_endpoint(triples, @endpoint)
  end

  defp triple_to_string({s, p, o}) do
    subject = "<#{to_string(s)}>"
    predicate = "<#{to_string(p)}>"
  
    object =
      case o do
        %RDF.Literal{} -> "\"#{RDF.Literal.value(o)}\""
        iri when is_struct(iri, RDF.IRI) -> "<#{to_string(iri)}>"
        other -> to_string(other)
      end
  
    "#{subject} #{predicate} #{object} ."
  end

  defp push_to_endpoint(triples, endpoint) do
    flat_triples = List.flatten(triples)
      |> Enum.map(&triple_to_string(&1))
      |> Enum.join("\n")

    # retry with: exponential_backoff() |> randomize |> expiry(10_000), rescue_only: [Req.TransportError] do
       Req.post!(
         url: endpoint,
         finch: GrimoireFinch,
         headers: [@auth, {"Content-Type", "text/turtle; charset=utf-8"}],
         body: flat_triples
         # connect_options: [timeout: 15_000],
         # receive_timeout: 30_000,
         # pool_timeout: 10_000
       )
    Logger.debug("GraphPusher finished sending triples!")
    # end
  end
end

