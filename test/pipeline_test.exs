defmodule GrimoireTest do
  alias Grimoire.Pipeline.Destination.GraphPusher
  alias Grimoire.Pipeline
  use ExUnit.Case
  doctest Grimoire

  test "whole pipeline" do
    {:ok, pid} = Pipeline.start_link(csv_path: "/opt/grimoire-data/musicbrainz-canonical-dump-20250603-080003/canonical/canonical_musicbrainz_data.csv", batch_size: 100, subject_key: "release_mbid")
    ref = Process.monitor(pid)

    # Wait for the pipeline to exit normally (or timeout if something's wrong)
    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        IO.puts("Pipeline finished successfully.")
    after
      :infinity ->
        flunk("Pipeline did not complete in time")
    end
  end
end
