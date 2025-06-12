defmodule Grimoire.Pipeline.Source.CsvStreamTest do
  alias Grimoire.Pipeline.Source.CsvStream

  use ExUnit.Case
  
  @csv """
  id,name
  1,Alice
  2,Bob
  """

  @tag :csv_source
  test "parses header and returns data stream" do
    {:ok, stream} = @csv
      |> StringIO.open()


    {header, data_stream} = stream
      |> IO.binstream(:line)
      |> CsvStream.stream()

    assert header == ["id", "name"]

    rows = Enum.to_list(data_stream)
    assert rows == [["1", "Alice"], ["2", "Bob"]]
  end
end
