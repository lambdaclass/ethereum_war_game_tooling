defmodule EthClient.NodesList.DNS do
  @moduledoc """
  Module for handling storage list retrieval using DNS.
  """
  alias EthClient.NodesList
  alias EthClient.NodesList.Storage

  @enr_prefix "enr:"
  @enrtree_branch_prefix "enrtree-branch:"

  def search_for_nodes(network, storage, enr_root) do
    supervisor_name()
    |> Task.Supervisor.start_child(fn ->
      get_children(network, storage, enr_root)
    end)
  end

  def supervisor_name, do: EthClient.NodesList.DNS.Supervisor

  @spec get_root(NodesList.network()) :: {:ok, String.t()} | {:error, term()}
  def get_root(network) do
    {:ok, response_split} =
      network
      |> get_domain_name()
      |> DNS.resolve(:txt)

    response = Enum.join(response_split)

    case Regex.run(~r/^enrtree-root:v1 e=([\w\d]+) .*$/, response) do
      [^response, enr_root] -> {:ok, enr_root}
      nil -> {:error, "enr_root not found in DNS response: #{response}"}
    end
  end

  @spec get_nodes(NodesList.network(), :ets.tid()) :: [tuple()]
  def get_nodes(network, storage), do: Storage.lookup(storage, network)

  @spec get_children(NodesList.network(), atom(), String.t()) :: :ok | {:error, term()}
  defp get_children(network, storage, branch) do
    branch_domain_name = branch <> "." <> get_domain_name(network)
    {:ok, response_split} = DNS.resolve(branch_domain_name, :txt)
    response = Enum.join(response_split)
    parse_child(network, storage, response)
  end

  @spec parse_child(NodesList.network(), atom(), String.t()) :: :ok | {:error, term()}
  defp parse_child(network, storage, @enr_prefix <> new_node) do
    Storage.insert(storage, network, new_node)
  end

  defp parse_child(network, storage, @enrtree_branch_prefix <> branches) do
    branches_split = String.split(branches, ",")
    get_children_branches(network, storage, branches_split)
  end

  defp parse_child(_, _, response) do
    {:error,
     "Neither #{@enr_prefix} nor #{@enrtree_branch_prefix} is in DNS response: #{response}"}
  end

  @spec get_children_branches(NodesList.network(), atom(), [String.t()]) :: :ok | {:error, term()}
  defp get_children_branches(_network, _, []), do: :ok

  defp get_children_branches(network, storage, [first_branch | rest]) do
    {:ok, _pid} = search_for_nodes(network, storage, first_branch)
    get_children_branches(network, storage, rest)
  end

  @spec get_domain_name(NodesList.network()) :: String.t()
  defp get_domain_name(:mainnet), do: "all.mainnet.ethdisco.net"
  defp get_domain_name(:ropsten), do: "all.ropsten.ethdisco.net"
  defp get_domain_name(:rinkeby), do: "all.rinkeby.ethdisco.net"
  defp get_domain_name(:goerli), do: "all.goerli.ethdisco.net"
end
