defmodule MMDB2Decoder.LookupTree do
  @moduledoc """
  Locates IPs in the lookup tree.
  """

  use Bitwise, only_operators: true

  require Logger

  alias MMDB2Decoder.Metadata
  alias MMDB2Decoder.IP

  @doc """
  Locates the data pointer associated for a given IP.
  """
  @spec locate(tuple, Metadata.t(), binary) :: {non_neg_integer, non_neg_integer}
  def locate({0, 0, 0, 0, 0, 65535, a, b}, meta, tree) do
    locate({a >>> 8, a &&& 0x00FF, b >>> 8, b &&& 0x00FF}, meta, tree)
  end

  def locate({_, _, _, _} = ip, %{ip_version: 6} = meta, tree) do
    IP.encode(ip)
    |> traverse(0, 32, 96, meta, tree)
  end

  def locate({_, _, _, _} = ip, meta, tree) do
    IP.encode(ip)
    |> traverse(0, 32, 0, meta, tree)
  end

  def locate({_, _, _, _, _, _, _, _}, %{ip_version: 4}, _), do: 0

  def locate({_, _, _, _, _, _, _, _} = ip, meta, tree) do
    IP.encode(ip)
    |> traverse(0, 128, 0, meta, tree)
  end

  defp traverse(_, bit, bit_count, node, %{node_count: node_count} = meta, _)
       when is_integer(bit_count) and bit < bit_count and node >= node_count do
    traverse(nil, bit, nil, node, meta, nil)
  end

  defp traverse(path, bit, bit_count, node, %{node_count: node_count} = meta, tree)
       when is_integer(bit_count) and bit < bit_count and node < node_count do
    rest_size = bit_count - bit - 1

    <<_::size(bit), node_bit::size(1), _::size(rest_size)>> = path

    node = read_node(node, node_bit, meta, tree)

    traverse(path, bit + 1, bit_count, node, meta, tree)
  end

  defp traverse(_, bit, _, node, meta, _) do
    node_count = meta.node_count

    cond do
      node > node_count ->
        {node, bit}

      node == node_count ->
        {0, bit}

      true ->
        Logger.error("Invalid node below node_count: #{node}")
        {0, bit}
    end
  end

  defp read_node(node, index, meta, tree) do
    record_size = meta.record_size
    record_half = rem(record_size, 8)
    record_left = record_size - record_half

    node_start = div(node * record_size, 4)
    node_len = div(record_size, 4)
    node_part = binary_part(tree, node_start, node_len)

    <<low::size(record_left), high::size(record_half), right::size(record_size)>> = node_part

    case index do
      0 -> low + (high <<< record_left)
      1 -> right
    end
  end
end
