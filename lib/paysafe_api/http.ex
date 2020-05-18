defmodule PaysafeAPI.HTTP do
  alias PaysafeAPI.Conn
  alias PaysafeAPI.Error

  def post(name, %Conn{} = conn, path, body, opts \\ []) when is_binary(path) and is_list(body) do
    body = body |> camel_case_keys() |> to_map() |> Jason.encode!()

    request(name, conn, :post, path, body, opts)
  end

  defp request(name, conn, method, path, body, opts) do
    url = Conn.build_url(conn, path)

    headers = [
      {"Authorization", "Basic #{conn.api_key}"},
      {"Content-Type", "application/json"}
    ]

    name
    |> PaysafeAPI.finch_name()
    |> Finch.request(method, url, headers, body, opts)
    |> handle_response()
  end

  defp handle_response({:ok, %Finch.Response{status: 200} = response}) do
    body =
      response.body
      |> Jason.decode!()
      |> snake_case_keys()
      |> cast_values()
      |> to_map()

    {:ok, body}
  end

  defp handle_response({:ok, %Finch.Response{status: status_code} = response})
       when status_code >= 400 and status_code <= 499 do
    {:ok, body} = Jason.decode(response.body)
    code = get_in(body, ~w(error code))
    message = get_in(body, ~w(error message))

    {:error, Error.exception([code, message, response])}
  end

  defp camel_case_keys(body) do
    Enum.map(body, fn
      {key, value} when is_list(value) -> {to_camel_case(key), camel_case_keys(value)}
      {key, value} -> {to_camel_case(key), value}
    end)
  end

  defp to_camel_case(key) when is_atom(key), do: to_camel_case(Atom.to_string(key))

  defp to_camel_case(key) when is_binary(key) do
    key = key |> String.split("_") |> Enum.map(&to_title_case/1) |> Enum.join("")

    with <<char::utf8, rest::binary>> <- key do
      String.downcase(<<char::utf8>>) <> rest
    end
  end

  defp to_title_case(<<char::utf8, rest::binary>>) do
    String.upcase(<<char::utf8>>) <> String.downcase(rest)
  end

  defp to_map(body) do
    Enum.reduce(body, %{}, fn {key, value}, acc -> Map.put(acc, key, do_to_map(key, value)) end)
  end

  defp do_to_map("links", links) do
    Enum.map(links, &Map.new/1)
  end

  defp do_to_map(_key, value) when is_list(value) do
    to_map(value)
  end

  defp do_to_map(_key, value) do
    value
  end

  defp snake_case_keys(payload) do
    Enum.map(payload, fn
      value when is_map(value) -> snake_case_keys(value)
      {key, value} when is_list(value) -> {to_snake_case(key), snake_case_keys(value)}
      {key, value} -> {to_snake_case(key), value}
    end)
  end

  defp to_snake_case(key) when is_binary(key) do
    Macro.underscore(key)
  end

  defp cast_values(payload) do
    Enum.map(payload, fn
      value when is_list(value) -> cast_values(value)
      {key, value} when is_list(value) -> {key, cast_values(value)}
      {key, value} -> {key, transform_value(key, value)}
    end)
  end

  defp transform_value("txn_time", utc_time) do
    {:ok, datetime, 0} = DateTime.from_iso8601(utc_time)

    datetime
  end

  defp transform_value(_key, value), do: value
end
