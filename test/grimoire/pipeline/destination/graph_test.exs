defmodule Grimoire.Pipeline.Destination.GraphTest do
  use ExUnit.Case, async: true
  import RDF.Sigils

  alias Grimoire.Pipeline.Destination.GraphPusher

  @tag :push_test
  test "formats triples and sends them via HTTP POST" do
    bypass = Bypass.open()

    test_endpoint = "http://localhost:#{bypass.port}/sparql"

    triples = [
      RDF.triple(
        ~I<urn://testSubject>,
        ~I<urn://dataPred>,
        ~L"object"
      ),
      RDF.triple(
        ~I<urn://testSubject>,
        ~I<urn://objPred>,
        ~I<urn://testObject>
      )
    ]

    Bypass.expect(bypass, fn conn ->
      {:ok, body, _conn} = Plug.Conn.read_body(conn)
      expected = "<urn://testSubject> <urn://dataPred> \"object\" .\n<urn://testSubject> <urn://objPred> <urn://testObject> .\n"
      assert String.contains?(body, expected)
      Plug.Conn.resp(conn, 200, "OK")
    end)

    GraphPusher.push([[triples]], test_endpoint)
  end
end
