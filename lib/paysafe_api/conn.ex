defmodule PaysafeAPI.Conn do
  @moduledoc """
  A connection holds basic authentication credentails which would usually be
  duplicated between API requests.
  """

  @test_base_url "https://api.test.paysafe.com"
  @production_base_url "https://api.paysafe.com"

  @schema [
    account_id: [
      type: :string,
      required: true
    ],
    api_key: [
      type: :string,
      required: true
    ],
    env: [
      type: {:one_of, [:test, :production]},
      default: :production
    ]
  ]

  defstruct [:account_id, :api_key, :env]

  @doc """
  Create a new connection.

  Supported options:
  #{NimbleOptions.docs(@schema)}
  """
  def new(opts) do
    opts = NimbleOptions.validate!(opts, @schema)

    struct(__MODULE__, opts)
  end

  def base_url(:test), do: @test_base_url
  def base_url(:production), do: @production_base_url

  def build_url(%__MODULE__{} = conn, path), do: base_url(conn.env) <> path
end
