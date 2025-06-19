# Grimoire

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `grimoire` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:grimoire, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/grimoire>.

## Running the Musicbrainz Pipeline

```bash
export TRIPLE_STORE_ENDPOINT="http://localhost:3030/mb/data"
export TRIPLE_STORE_BASIC="$(echo -n 'admin:secret' | base64)"
```

