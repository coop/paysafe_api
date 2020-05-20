defmodule PaysafeAPI do
  @moduledoc """
  HTTP interactions with the Paysafe REST API.

  https://developer.paysafe.com/en/
  """

  defmodule Error do
    defexception [:response, :message, :code]

    @impl Exception
    def exception([code, message, response]) do
      %__MODULE__{code: code, message: message, response: response}
    end
  end

  use Supervisor

  alias __MODULE__.HTTP
  alias __MODULE__.Conn
  alias __MODULE__.CustomNimbleOptions

  @start_link_schema [
    name: [
      type: :atom,
      required: true
    ],
    test: [
      type: :keyword_list,
      required: false
    ],
    production: [
      type: :keyword_list,
      required: false
    ]
  ]

  @doc """
  Statrt the Supervisor.

  Supported options:
  #{NimbleOptions.docs(@start_link_schema)}

  The options for both environments are passed to `Finch.start_link/1`.
  """
  def start_link(opts) do
    opts = NimbleOptions.validate!(opts, @start_link_schema)
    name = Keyword.get(opts, :name)

    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @create_authorization_schema [
    card: [
      type: :non_empty_keyword_list,
      required: true,
      doc: "The payment token that represents the card used for the request.",
      keys: [
        payment_token: [
          required: true,
          type: :string,
          doc: "Either a single use token OR a vaulted card."
        ],
        cvv: [
          required: false,
          type: :string,
          doc:
            "The 3 or 4-digit security code that appears on the card following the card number."
        ]
      ]
    ],
    merchant_ref_num: [
      type: :string,
      required: true,
      doc:
        "The reference number from your system to be stored against the authorization in Paysafe."
    ],
    amount: [
      type: :pos_integer,
      required: true,
      doc: "The value of the authorization in cents."
    ],
    settle_with_auth: [
      type: :boolean,
      default: true,
      doc:
        "This indicates whether the request is an Authorization only (no Settlement), or a Purchase (Authorization and Settlement)."
    ],
    customer_ip: [
      type: {:custom, CustomNimbleOptions, :ip_address, []},
      required: false,
      doc: "The IP address of the customer."
    ],
    profile: [
      type: :keyword_list,
      required: false,
      doc: "Some details about the customer.",
      keys: [
        first_name: [
          required: false,
          type: :string
        ],
        last_name: [
          required: false,
          type: :string
        ],
        email: [
          required: false,
          type: :string
        ]
      ]
    ],
    billing_details: [
      type: :keyword_list,
      required: false,
      doc: "The billing address of the customer.",
      keys: [
        street: [
          required: false,
          type: :string
        ],
        street2: [
          required: false,
          type: :string
        ],
        city: [
          required: false,
          type: :string
        ],
        state: [
          required: false,
          type: {:custom, CustomNimbleOptions, :country, []}
        ],
        country: [
          required: false,
          type: {:custom, CustomNimbleOptions, :country, []}
        ],
        zip: [
          required: false,
          type: :string
        ],
        phone: [
          required: false,
          type: :string
        ]
      ]
    ],
    dup_check: [
      type: :boolean,
      default: false,
      doc: "Validates that the merchant_ref_number is unique within the last 90 days."
    ],
    description: [
      type: :string,
      required: false,
      doc: "The description of the transaction."
    ]
  ]

  @doc """
  Create an authorization.

  https://developer.paysafe.com/en/cards/api/#/auths

  Supported options:
  #{NimbleOptions.docs(@create_authorization_schema)}
  """
  def create_authorization(name, %Conn{} = conn, opts) do
    opts = NimbleOptions.validate!(opts, @create_authorization_schema)
    path = "/cardpayments/v1/accounts/#{conn.account_id}/auths"

    HTTP.post(name, conn, path, opts)
  end

  @impl Supervisor
  def init(opts) do
    {name, opts} = Keyword.pop!(opts, :name)

    children = [
      {Finch, name: finch_name(name), pools: pool_config(opts)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def finch_name(name), do: :"#{name}_finch"

  defp pool_config(opts) do
    Enum.reduce(opts, %{}, fn {env, pool_conf}, conf ->
      Map.put(conf, Conn.base_url(env), pool_conf)
    end)
  end
end
