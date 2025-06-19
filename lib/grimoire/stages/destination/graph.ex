require Logger
defmodule Grimoire.Stages.Destination.Graph do
  use Retry
  use GenStage
  require Logger

  defp config do
    Application.get_env(:grimoire, __MODULE__)
  end

  def start_link(opts) do
    [name: name] = opts
    GenStage.start_link(__MODULE__, :ok, name: name)
  end

  def init(:ok) do
    Logger.info("Graph Init")
    {:consumer, :ok}
  end

  def handle_events(batches, _from, rate) do
    Logger.debug("Handling events in GraphPusher")
    Enum.each(batches, fn batch ->
      start = System.monotonic_time(:millisecond)
      push(batch, nil)

      duration = System.monotonic_time(:millisecond) - start
      Logger.info("Batch of #{length(batch)} pushed in #{duration} ms")
    end)
    {:noreply, [], rate}
  end

  def push(triples, endpoint) when is_binary(endpoint) do
    push_to_endpoint(triples, endpoint)
  end

  def push(triples, endpoint) when is_nil(endpoint) do
    default_url = Keyword.fetch!(config(), :endpoint)
    push_to_endpoint(triples, default_url)
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
    auth = Keyword.fetch!(config(), :auth)
    flat_triples = List.flatten(triples)
      |> Enum.map(&triple_to_string(&1))
      |> Enum.join("\n")

    try do
      Req.post!(
        url: endpoint,
        finch: GrimoireFinch,
        headers: [auth, {"Content-Type", "text/turtle; charset=utf-8"}],
        body: flat_triples
      )
    rescue
      _ -> Logger.error("An error occurred when pushing to graph!")
    end
  end
end

