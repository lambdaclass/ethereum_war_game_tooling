defmodule EthClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias EthClient.Account
  alias EthClient.Contract

  @impl true
  def start(_type, _args) do
    initial_context = %{
      chain_id: 1234,
      rpc_host: "http://localhost:8545",
      user_account: %Account{
        address: "0xafb72ccaeb7e22c8a7640f605824b0898424b3da",
        private_key: "e90d75baafee04b3d9941bd8d76abe799b391aec596515dee11a9bd55f05709c"
      },
      etherscan_api_key: nil,
      contract: %Contract{address: nil, functions: nil}
    }

    children = [
      {EthClient.Context, initial_context},
      {EthClient.NodesList, EthClient.NodesList.DNS.Storage}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EthClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
