require Logger
defmodule Grimoire do
  @moduledoc """
  Documentation for `Grimoire`.
  """

  @doc """
  Hello world.
  """
  def main(_args) do
    Application.ensure_all_started(:retry)
    IO.puts("In grimoire.ex main")
  end

end
