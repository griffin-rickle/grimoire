alias Grimoire.Transformer.Musicbrainz, as: MBTX
alias Grimoire.Fetcher.MusicBrainz, as: MBF
defmodule Grimoire do
  @moduledoc """
  Documentation for `Grimoire`.
  """

  @doc """
  Hello world.
  """
  def main(_args) do
    parent = self()
    tx_pid = MBTX.start(parent)
    fetch_pid = MBF.start(parent)
    send(fetch_pid, {:musicbrainz, "technical death metal", tx_pid})
    receive do
      {:done, _pid, count} -> IO.puts("Finished #{count} recordings")
      {:error, _pid, reason} -> IO.puts("Error: #{inspect(reason)}")
    end
  end
end
