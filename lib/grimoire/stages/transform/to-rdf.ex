require Logger
defmodule Grimoire.Stages.Transform.To_RDF do
  use GenStage
  alias RDF.{IRI, Literal, Triple}

  def start_link(opts) do 
    [name: name] = opts
    GenStage.start_link(__MODULE__, :ok, name: name)
  end

  def init(:ok) do
    Logger.info("To_RDF Init")
    {:producer_consumer, :ok}
  end

  def handle_events(lines, _from, state) do
    Logger.debug("Handling events in To_RDF")
    triples = Enum.map(lines, &to_triples(&1, "recording_mbid"))
    {:noreply, List.flatten(triples), state}
  end

  def to_triples(record, subject_key) when is_map(record) do
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
