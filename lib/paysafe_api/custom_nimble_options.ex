defmodule PaysafeAPI.CustomNimbleOptions do
  def ip_address(value) when is_binary(value) do
    case :inet.parse_address(to_charlist(value)) do
      {:ok, ip_address} -> ip_address(ip_address)
      {:error, :einval} -> {:error, "expected an ip address but got #{inspect(value)}"}
    end
  end

  def ip_address(value) when is_tuple(value) do
    ip_address =
      value
      |> :inet.ntoa()
      |> to_string()

    {:ok, ip_address}
  end
end
