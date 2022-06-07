defmodule EthClient.NodesList.Storage do
  @moduledoc """
  Module for handling nodes list storage.
  """

  def new(name) do
    :ets.new(name, [:named_table, :public, read_concurrency: true])
  end

  def lookup(storage, network) do
    with [{^network, nodes}] <- :ets.lookup(storage, network) do
      nodes
    end
  end

  def insert(storage, network, new_node) do
    network_nodes = lookup(storage, network)
    :ets.insert(storage, {network, [new_node | network_nodes]})
  end

  def delete(storage, network) do
    :ets.delete(storage, network)
  end
end
