defmodule Grimoire.Application do
  @moduledoc false
  alias Grimoire.Pipelines.Musicbrainz
  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: GrimoireFinch, pools: %{default: [size: 100, count: 10]}},
      {Musicbrainz, name: MusicbrainzPipeline},
    ]

    opts = [strategy: :one_for_one, name: Grimoire.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
