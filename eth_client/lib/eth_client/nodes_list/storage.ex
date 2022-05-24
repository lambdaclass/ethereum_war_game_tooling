defmodule EthClient.NodesList.Storage do
  @moduledoc """
  Module for handling nodes list storage.
  """
  @spec new(atom) :: :ets.tid()
  def new(name) do
    :ets.new(name, [:named_table, :public, read_concurrency: true])
  end

  @spec lookup(:ets.tid(), String.t()) :: [tuple()]
  def lookup(storage, network) do
    :ets.lookup(storage, network)
  end

  def insert(storage, network, new_node) do
    network_nodes =
      case lookup(storage, network) do
        [{_, result}] -> result
        [] -> []
      end

    :ets.insert(storage, {network, [new_node | network_nodes]})
  end
end
