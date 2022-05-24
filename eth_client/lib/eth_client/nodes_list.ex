defmodule EthClient.NodesList do
  @moduledoc """
  Retrieve a storage list for a specific network. Right now, only supports getting a list
  by DNS.
  """
  use GenServer

  alias EthClient.NodesList.DNS, as: NodesListDNS
  alias EthClient.NodesList.Storage

  @type network :: :mainnet | :ropsten | :rinkeby | :goerli

  def start_link(storage_name) do
    GenServer.start_link(__MODULE__, storage_name, name: __MODULE__)
  end

  @spec update_using_dns(network()) :: :ok | {:error, term()}
  def update_using_dns(network) do
    GenServer.call(__MODULE__, {:update_using_dns, network}, search_timeout())
  end

  @spec get(network()) :: :ok | {:error, term()}
  def get(network) do
    GenServer.call(__MODULE__, {:get, network})
  end

  def search_timeout, do: 20_000

  ## Server callbacks

  @impl true
  def init(storage_name) do
    storage = Storage.new(storage_name)
    {:ok, storage}
  end

  @impl true
  def handle_call({:update_using_dns, network}, _from, storage) do
    result =
      with {:ok, enr_root} <- NodesListDNS.get_root(network) do
        NodesListDNS.start_searching_for_nodes(network, storage, enr_root)
      end

    {:reply, result, storage}
  end

  @impl true
  def handle_call({:get, network}, _from, storage) do
    result = NodesListDNS.get_nodes(network, storage)

    {:reply, result, storage}
  end
end
