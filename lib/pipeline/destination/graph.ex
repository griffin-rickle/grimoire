defmodule Grimoire.Pipeline.Destination.GraphPusher do

  @endpoint "http://localhost:3030/mb/data"
  @auth {"Authorization", "Basic " <> Base.encode64("admin:")}

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
  
    "#{subject} #{predicate} #{object} .\n"
  end

  defp push_to_endpoint(triples, endpoint) do
    flat_triples = List.flatten(triples)
      |> Enum.map(&triple_to_string(&1))

    Req.post!(
      url: endpoint,
      headers: [@auth, {"Content-Type", "application/sparql-update"}],
      body: flat_triples
    )
  end
end

