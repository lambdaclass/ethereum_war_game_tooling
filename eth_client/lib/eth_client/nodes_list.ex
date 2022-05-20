defmodule EthClient.NodesList do
  @moduledoc """
  Retrieve a nodes list for a specific network. Right now, only supports getting a list
  by DNS.
  """

  @type network :: :mainnet | :ropsten | :rinkeby | :goerli

  @enr_prefix "enr:"
  @enrtree_branch_prefix "enrtree-branch:"

  @spec get_by_dns(network()) :: {:ok, String.t()} | {:error, term()}
  def get_by_dns(network) do
    with {:ok, enr_root} <- get_root(network) do
      get_children(network, enr_root)
    end
  end

  @spec get_root(network()) :: {:ok, String.t()} | {:error, term()}
  defp get_root(network) do
    {:ok, response_splitted} =
      network
      |> get_domain_name()
      |> DNS.resolve(:txt)

    response = Enum.join(response_splitted)

    case Regex.run(~r/^enrtree-root:v1 e=([\w\d]+) .*$/, response) do
      [^response, enr_root] -> {:ok, enr_root}
      nil -> {:error, "enr_root not found in DNS response: #{response}"}
    end
  end

  @spec get_children(network(), String.t()) :: {:ok, [String.t()]} | {:error, term()}
  defp get_children(network, branch) do
    branch_domain_name = branch <> "." <> get_domain_name(network)
    {:ok, response_splitted} = DNS.resolve(branch_domain_name, :txt)
    response = Enum.join(response_splitted)

    cond do
      String.starts_with?(response, @enr_prefix) ->
        @enr_prefix <> node = response
        {:ok, [node]}

      String.starts_with?(response, @enrtree_branch_prefix) ->
        @enrtree_branch_prefix <> branches = response
        branches_splitted = String.split(branches, ",")
        get_children_branches(network, branches_splitted, [])

      true ->
        {:error,
         "Neither #{@enr_prefix} nor #{@enrtree_branch_prefix} is in DNS response: #{response}"}
    end
  end

  @spec get_children_branches(network(), [String.t()], [String.t()]) ::
          {:ok, [String.t()]} | {:error, term()}
  defp get_children_branches(_network, [], nodes), do: {:ok, nodes}

  defp get_children_branches(network, branches, nodes) do
    [branch | rest] = branches

    with {:ok, node} <- get_children(network, branch) do
      get_children_branches(network, rest, node ++ nodes)
    else
      {:error, _} = error -> error
    end
  end

  @spec get_domain_name(network()) :: String.t()
  defp get_domain_name(:mainnet), do: "all.mainnet.ethdisco.net"
  defp get_domain_name(:ropsten), do: "all.ropsten.ethdisco.net"
  defp get_domain_name(:rinkeby), do: "all.rinkeby.ethdisco.net"
  defp get_domain_name(:goerli), do: "all.goerli.ethdisco.net"
end
