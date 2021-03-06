defmodule PaysafeAPI.MixProject do
  use Mix.Project

  def project do
    [
      app: :paysafe_api,
      version: "1.0.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.5"},
      {:jason, "~> 1.2"},
      {:nimble_options, "~> 0.3"}
    ]
  end
end
