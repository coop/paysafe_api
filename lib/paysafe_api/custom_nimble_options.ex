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

  def country(value) do
    if is_binary(value) && String.length(value) == 2 do
      {:ok, String.upcase(value)}
    else
      {:error, "expected a 2 character country but got #{inspect(value)}"}
    end
  end

  def state(value) do
    if is_binary(value) && String.length(value) == 2 do
      {:ok, String.upcase(value)}
    else
      {:error, "expected a 2 character state but got #{inspect(value)}"}
    end
  end
end
