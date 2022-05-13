defmodule EthClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias EthClient.Account
  alias EthClient.Contract

  @impl true
  def start(_type, _args) do
    {chain_id, _} = Integer.parse(System.get_env("ETH_CHAIN_ID", "1234"))

    initial_context = %{
      chain_id: chain_id,
      rpc_host: System.get_env("ETH_RPC_HOST", "http://localhost:8545"),
      user_account: %Account{
        address: System.get_env("ETH_MINER_ADDRESS", "0xafb72ccaeb7e22c8a7640f605824b0898424b3da"),
        private_key: System.get_env("ETH_MINER_PK", "e90d75baafee04b3d9941bd8d76abe799b391aec596515dee11a9bd55f05709c"),
      },
      etherscan_api_key: System.get_env("ETH_API_KEY", nil),
      contract: %Contract{address: System.get_env("ETH_CONTRACT", nil), functions: nil}
    }

    children = [
      {EthClient.Context, initial_context}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EthClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
