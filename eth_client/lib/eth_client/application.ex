defmodule EthClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias EthClient.Account
  alias EthClient.Contract

  @impl true
  def start(_type, _args) do
    initial_context = get_initial_context()

    children = [
      {EthClient.Context, initial_context}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EthClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get_initial_context() do
    {chain_id, _} = "ETH_CHAIN_ID"
         |> System.fetch_env!()
         |> Integer.parse()

    %{
      chain_id: chain_id,
      rpc_host: System.fetch_env!("ETH_RPC_HOST"),
      user_account: %Account{
        address: System.fetch_env!("ETH_USER_ADDRESS"),
        private_key: System.fetch_env!("ETH_USER_PK"),
      },
      etherscan_api_key: System.fetch_env!("ETH_API_KEY"),
      contract: %Contract{address: System.fetch_env!("ETH_CONTRACT"), functions: nil}
    }
  end
end
