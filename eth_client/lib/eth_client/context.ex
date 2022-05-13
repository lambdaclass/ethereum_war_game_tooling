defmodule EthClient.Context do
  use Agent

  alias EthClient.Account
  alias EthClient.Contract
  require Logger

  def start_link(%{chain_id: _chain_id, rpc_host: _rpc_host, user_account: %Account{}} = config) do
    Agent.start_link(fn -> config end, name: __MODULE__)
  end

  def all, do: Agent.get(__MODULE__, & &1)
  def rpc_host, do: get(:rpc_host)
  def chain_id, do: get(:chain_id)
  def user_account, do: get(:user_account)
  def contract, do: get(:contract)
  def etherscan_api_key, do: get(:etherscan_api_key)

  def set_rpc_host(new_host), do: set(:rpc_host, new_host)
  def set_chain_id(new_chain_id), do: set(:chain_id, new_chain_id)
  def set_user_account(new_user_account), do: set(:user_account, new_user_account)

  def set_contract_address(new_address) do
    IEx.configure(default_prompt: "#{String.slice(new_address, 0..5)}>")

    set(:contract, Map.put(get(:contract), :address, new_address))
  end

  def set_contract(new_address) do
    set_contract_address(new_address)

    case Contract.get_functions(new_address) do
      {:ok, functions} ->
        set_contract_functions(functions)

      error ->
        Logger.error("Could not fetch the contract's abi from Etherscan. Error: #{error}")
    end
  end

  def set_contract_functions(api), do: set(:contract, Map.put(get(:contract), :functions, api))
  def set_etherscan_api_key(new_key), do: set(:etherscan_api_key, new_key)

  defp get(key) do
    Agent.get(__MODULE__, & &1)
    |> Map.get(key)
  end

  defp set(key, value) do
    Agent.update(__MODULE__, fn config ->
      Map.put(config, key, value)
    end)
  end
end
