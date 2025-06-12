alias Grimoire.Pipeline
require Logger
defmodule Grimoire do
  @moduledoc """
  Documentation for `Grimoire`.
  """

  @doc """
  Hello world.
  """
  def main(_args) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)
    Application.ensure_all_started(:public_key)
    Pipeline.init(csv_path: "/opt/grimoire-data/musicbrainz-canonical-dump-20250603-080003/canonical/canonical_musicbrainz_data.csv", batch_size: 100, subject_key: "record_mbid")
  end
end
