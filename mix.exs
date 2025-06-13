defmodule Grimoire.MixProject do
  use Mix.Project

  def project do
    [
      app: :grimoire,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Grimoire],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :public_key, :retry]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rdf, "~> 2.1"},
      {:exjsonpath, "~> 0.1"},
      {:elixir_uuid, "~> 1.2"},
      {:nimble_csv, "~> 1.2"},
      {:sparql_client, "~> 0.3"},
      {:req, "~> 0.4"},
      {:bypass, "~> 2.1", only: :test},
      {:retry, "~> 0.18"},
    ]
  end
end
