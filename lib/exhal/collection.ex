defmodule ExHal.Collection do
  @moduledoc """
    Utility functions for dealing with RFC 6473 collections
    """

  alias ExHal.Document
  alias ExHal.ResponseHeader

  @doc """
    Returns a stream that iterate over the collection represented by `a_doc`.
    """
  def to_stream(a_doc) do
    Stream.resource(
      fn -> {:ok, a_doc} end,
      fn follow_result ->
        case follow_result do
          {:error, _} -> {:halt, follow_result}
          {:ok, page} -> page |> expand_page
          {:ok, page, %ResponseHeader{}} -> page |> expand_page
        end
      end,
      fn _ -> nil end
    )
  end

  @doc """
    Returns a string representation of this HAL collection.
  """
  def render!(enum) do
    to_json_hash(enum)
    |> Poison.encode!
  end

  @doc """
    ** Deprecated **
    see `render/1`
  """
  def to_json_hash(enum) do
    %{ "_embedded" => %{"item" => Enum.map(enum, &(Document.to_json_hash(&1)))} }
  end

  defp expand_page(page) do
    {ExHal.follow_links(page, "item", fn _ -> [] end),
      ExHal.follow_link(page, "next", pick_volunteer: true)}
  end
end
