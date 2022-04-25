defmodule EthClient.Context do
  use Agent

  alias EthClient.Account

  def start_link(%{chain_id: _chain_id, rpc_host: _rpc_host, user_account: %Account{}} = config) do
    Agent.start_link(fn -> config end, name: __MODULE__)
  end

  def all, do: Agent.get(__MODULE__, & &1)

  def rpc_host do
    Agent.get(__MODULE__, & &1)
    |> Map.get(:rpc_host)
  end

  def chain_id do
    Agent.get(__MODULE__, & &1)
    |> Map.get(:chain_id)
  end

  def user_account do
    Agent.get(__MODULE__, & &1)
    |> Map.get(:user_account)
  end

  def current_contract do
    Agent.get(__MODULE__, & &1)
    |> Map.get(:current_contract)
  end

  def set_rpc_host(new_host) do
    Agent.update(__MODULE__, fn config ->
      Map.put(config, :rpc_host, new_host)
    end)
  end

  def set_chain_id(new_chain_id) do
    Agent.update(__MODULE__, fn config ->
      Map.put(config, :chain_id, new_chain_id)
    end)
  end

  def set_user_account(new_user_account) do
    Agent.update(__MODULE__, fn config ->
      Map.put(config, :user_account, new_user_account)
    end)
  end

  def set_current_contract(new_contract) do
    Agent.update(__MODULE__, fn config ->
      Map.put(config, :current_contract, new_contract)
    end)
  end
end
