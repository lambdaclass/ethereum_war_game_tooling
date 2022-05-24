defmodule EthClient.NodesList do
  @moduledoc """
  Retrieve a nodes list for a specific network. Right now, only supports getting a list
  by DNS.
  """
  use GenServer

  alias EthClient.NodesList.DNS, as: NodesListDNS

  @type network :: :mainnet | :ropsten | :rinkeby | :goerli

  def start_link(storage_name) do
    GenServer.start_link(__MODULE__, storage_name, name: __MODULE__)
  end

  @spec update_using_dns(network()) :: :ok | {:error, term()}
  def update_using_dns(network) do
    GenServer.call(__MODULE__, {:update_using_dns, network})
  end

  def get(network) do
    GenServer.call(__MODULE__, {:get, network})
  end

  ## Server callbacks

  @impl true
  def init(storage_name) do
    nodes = :ets.new(storage_name, [:named_table, :public, read_concurrency: true])
    dns_supervisor_name = NodesListDNS.supervisor_name()
    Task.Supervisor.start_link(name: dns_supervisor_name)
    {:ok, nodes}
  end

  @impl true
  def handle_call({:update_using_dns, network}, _from, nodes) do
    result =
      with {:ok, enr_root} <- NodesListDNS.get_root(network) do
        NodesListDNS.search_for_nodes(network, nodes, enr_root)
      end

    {:reply, result, nodes}
  end

  @impl true
  def handle_call({:get, network}, _from, nodes) do
    result = NodesListDNS.get_nodes(network, nodes)

    {:reply, result, nodes}
  end
end
