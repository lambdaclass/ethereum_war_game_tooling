defmodule EthClient.NodesList.DNS do
  @moduledoc """
  Module for handling storage list retrieval using DNS.
  """
  alias EthClient.NodesList
  alias EthClient.NodesList.Storage

  @enr_prefix "enr:"
  @enrtree_branch_prefix "enrtree-branch:"
  @attempts 100
  @waiting_time_ms 500

  def start_searching_for_nodes(network, storage, enr_root) do
    Storage.delete(storage, network)
    search = Task.async(fn -> get_children(network, storage, enr_root) end)
    Task.await(search, NodesList.search_timeout())
  end

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

  def get_nodes(network, storage), do: Storage.lookup(storage, network)

  defp get_children(network, storage, branch) do
    branch_domain_name = branch <> "." <> get_domain_name(network)
    {:ok, response_split} = wait_to_resolve(branch_domain_name)
    response = Enum.join(response_split)
    parse_child(network, storage, response)
  end

  defp parse_child(network, storage, @enr_prefix <> new_node) do
    decoded_node =
      new_node
      |> Base.url_decode64!(padding: false)
      |> ExRLP.decode()

    Storage.insert(storage, network, decoded_node)
    :ok
  end

  defp parse_child(network, storage, @enrtree_branch_prefix <> branches) do
    branches
    |> String.split(",")
    |> Enum.map(fn branch ->
      Task.async(fn -> get_children(network, storage, branch) end)
    end)
    |> Task.await_many(NodesList.search_timeout())

    :ok
  end

  defp parse_child(_, _, response) do
    {:error,
     "Neither #{@enr_prefix} nor #{@enrtree_branch_prefix} is in DNS response: #{response}"}
  end

  defp wait_to_resolve(domain_name), do: wait_to_resolve(domain_name, @attempts)

  defp wait_to_resolve(domain_name, 0), do: {:error, "Cannot resolve #{domain_name}"}

  defp wait_to_resolve(domain_name, attempts) do
    response =
      try do
        try_to_resolve(domain_name, :start)
      rescue
        Socket.Error -> {:error, attempts}
      end

    try_to_resolve(domain_name, response)
  end

  defp try_to_resolve(domain_name, :start), do: DNS.resolve(domain_name, :txt)

  defp try_to_resolve(domain_name, {:error, attempts}) do
    Process.sleep(@waiting_time_ms)
    wait_to_resolve(domain_name, attempts - 1)
  end

  defp try_to_resolve(_domain_name, {:ok, _} = success), do: success

  @spec get_domain_name(NodesList.network()) :: String.t()
  defp get_domain_name(:mainnet), do: "all.mainnet.ethdisco.net"
  defp get_domain_name(:ropsten), do: "all.ropsten.ethdisco.net"
  defp get_domain_name(:rinkeby), do: "all.rinkeby.ethdisco.net"
  defp get_domain_name(:goerli), do: "all.goerli.ethdisco.net"
end
