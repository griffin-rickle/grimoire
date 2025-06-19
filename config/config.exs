import Config

config :grimoire, Grimoire.Stages.Destination.Graph,
  endpoint: System.get_env("TRIPLE_STORE_ENDPOINT") || "http://localhost:3030/mb/data",
  auth: {"Authorization", "Basic " <> (System.get_env("TRIPLE_STORE_AUTH") || "")}

config :grimoire, Grimoire.Pipelines.Musicbrainz,
  csv_path: "/opt/grimoire-data/musicbrainz-canonical-dump-20250603-080003/canonical/canonical_musicbrainz_data.csv",
  batch_size: 10_000
