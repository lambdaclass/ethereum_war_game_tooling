defmodule EthClient.NodesList do
  @moduledoc """
  Retrieve a nodes list for a specific network. Right now, only supports getting a list
  by DNS.
  """

  alias DNS.Record
  alias DNS.Resource

  @type network :: :mainnet | :ropsten | :rinkeby | :goerli

  @spec get_by_dns(network()) :: Record.t()
  def get_by_dns(network) do
    %Record{anlist: [%Resource{data: [enrtree_data]}]} =
      network
      |> get_domain_name()
      |> DNS.query(:txt)

    enrtree_data
  end

  @spec get_domain_name(network()) :: String.t()
  defp get_domain_name(:mainnet), do: "all.mainnet.ethdisco.net"
  defp get_domain_name(:ropsten), do: "all.ropsten.ethdisco.net"
  defp get_domain_name(:rinkeby), do: "all.rinkeby.ethdisco.net"
  defp get_domain_name(:goerli), do: "all.goerli.ethdisco.net"
end
