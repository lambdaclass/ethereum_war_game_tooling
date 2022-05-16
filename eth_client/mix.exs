defmodule EthClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :eth_client,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EthClient.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.17"},
      {:ex_abi, "~> 0.5"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:rustler, "~> 0.25.0"},
      {:ex_rlp, "~> 0.5.4"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
