defmodule ExHal.Link do
  @moduledoc """
   A Link is a directed reference from one resource to another resource. They
    are found in the `_links` and `_embedded` sections of a HAL document
  """

  alias ExHal.{Document, NsReg}

  defstruct [:rel, :href, :templated, :name, :target]

  @doc """
    Build new link struct from _links entry.
  """
  def from_links_entry(rel, a_map) do
    href = Map.fetch!(a_map, "href")
    templated = Map.get(a_map, "templated", false)
    name = Map.get(a_map, "name", nil)

    %__MODULE__{rel: rel, href: href, templated: templated, name: name}
  end

  @doc """
    Build new link struct from embedded doc.
  """
  def from_embedded(rel, embedded_doc) do
    {:ok, href} = ExHal.url(embedded_doc, fn _doc -> {:ok, nil} end)

    %__MODULE__{rel: rel, href: href, templated: false, target: embedded_doc}
  end

  @doc """
    Returns target url, expanded with `vars` if any are provided.

    Returns `{:ok, "fully_qualified_url"}`
            `:error` if link target is anonymous
  """
  def target_url(a_link, vars \\ %{}) do
    case a_link do
      %{href: nil} ->
        :error

      %{templated: true} ->
        {:ok, UriTemplate.expand(a_link.href, vars)}

      _ ->
        {:ok, a_link.href}
    end
  end

  @doc """
    Returns target url, expanded with `vars` if any are provided.

    Returns `"fully_qualified_url"` or raises exception
  """
  def target_url!(a_link, vars \\ %{}) do
    {:ok, url} = target_url(a_link, vars)

    url
  end

  @doc """
    Expands "curie"d link rels using the namespaces found in the `curies` link.

    Returns `[%Link{}, ...]` a link struct for each possible variation of the input link
  """
  def expand_curie(link, namespaces) do
    NsReg.variations(namespaces, link.rel)
    |> Enum.map(fn rel -> %{link | rel: rel} end)
  end

  def embedded?(link) do
    !!link.target
  end

  @doc """
  **Deprecated**
  See `to_json_map/1`
  """
  def to_json_hash(link), do: to_json_map(link)

  @doc """
  Returns a map that matches the shape of the intended JSON output.
  """
  def to_json_map(link) do
    if embedded?(link) do
      Document.to_json_hash(link.target)
    else
      %{"href" => link.href}
      |> add_templated(link)
      |> add_name(link)
    end
  end

  defp add_templated(json_map, %{templated: true}) do
    Map.merge(json_map, %{"templated" => true})
  end

  defp add_templated(json_map, _), do: json_map

  defp add_name(json_map, %{name: name}) when is_binary(name) do
    Map.merge(json_map, %{"name" => name})
  end

  defp add_name(json_map, _), do: json_map
end
