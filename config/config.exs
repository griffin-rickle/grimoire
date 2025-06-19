import Config

config :grimoire, Grimoire.Stages.Destination.Graph,
  endpoint: System.get_env("TRIPLE_STORE_ENDPOINT") || "http://localhost:3030/mb/data",
  auth: {"Authorization", "Basic " <> (System.get_env("TRIPLE_STORE_AUTH") || "")}
