require Logger
defmodule Grimoire.Pipeline.Transform.CsvToRdf do
  alias RDF.{IRI, Literal, Triple}

  def to_triples(record, subject_key) do
    subject_value = Map.get(record, subject_key)
    subject = IRI.new("http://grimoire.grifflab.media/resource/#{URI.encode(subject_value)}")

    record
    |> Enum.reject(fn {k, _v} -> k == subject_key end)
    |> Enum.map(fn {predicate, object} ->
      Triple.new(subject, IRI.new("http://grimoire.grifflab.media/#{predicate}"), parse_object(object))
    end)
  end

  defp parse_object(o) do
    if String.starts_with?(o, "http") do
      IRI.new(o)
    else
      Literal.new(o)
    end
  end
end
