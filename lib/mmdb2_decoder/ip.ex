defmodule MMDB2Decoder.IP do
  @moduledoc """
  Encodes and decodes IP tuples into binary representation.
  """

  @doc """
  Encodes IP into binary data.
  """
  def encode({a, b, c, d}) do
    <<a::size(8), b::size(8), c::size(8), d::size(8)>>
  end

  def encode({a, b, c, d, e, f, g, h}) do
    <<
      a::size(16),
      b::size(16),
      c::size(16),
      d::size(16),
      e::size(16),
      f::size(16),
      g::size(16),
      h::size(16)
    >>
  end

  @doc """
  Decodes binary representation of IP into a tuple.
  """
  def decode(<<a::size(8), b::size(8), c::size(8), d::size(8)>>) do
    {a, b, c, d}
  end

  def decode(<<
        a::size(16),
        b::size(16),
        c::size(16),
        d::size(16),
        e::size(16),
        f::size(16),
        g::size(16),
        h::size(16)
      >>) do
    {a, b, c, d, e, f, g, h}
  end

  @doc """
  Returns an ip tuple representing network prefix for this IP,
  given that the prefix occupies `bit` bits.
  """
  def network_prefix(ip, bit) do
    <<net::size(bit), rest::bitstring>> = encode(ip)
    rest_size = bit_size(rest)
    ip_bin = <<net::size(bit), 0::size(rest_size)>>
    decode(ip_bin)
  end
end
