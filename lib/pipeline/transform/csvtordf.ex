require Logger
defmodule Grimoire.Pipeline.Transform.CsvToRdf do
  use GenStage
  alias Grimoire.Pipeline
  alias RDF.{IRI, Literal, Triple}

  def start_link(), do: GenStage.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: {:producer_consumer, :ok, subscribe_to: [Pipeline]}

  def handle_events(lines, _from, state) do
    triples = Enum.map(lines, &to_triples(&1, "recording_mbid"))
    {:noreply, List.flatten(triples), state}
  end

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
    escaped =
      o
      |> String.replace("\\", "\\\\")  # Escape backslashes
      |> String.replace("\"", "\\\"")  # Escape double quotes
    if String.starts_with?(o, "http") do
      IRI.new(escaped)
    else
      Literal.new(escaped)
    end
  end
end
