defmodule EthClient.ABI do
  @moduledoc """
  """
  alias EthClient.Context

  # get whether it's an etherscan-linked bc
  # if it is, use provided ABI
  # elsewise, get ABI through invoking panoramix on rpc provider
  def get("0x" <> _ = address), do: get_etherscan(address)



  def get(abi_path), do: get_local(abi_path)

  defp get_non_etherscan(address) do
  # if it exists, use provided ABI (.bin -> .abi) (?)
  # elsewise, get ABI through invoking panoramix on rpc provider (if possible)

  {path, _} = System.cmd("command", ["-v", "python3"])

  {:ok, python_pid} = :python.start(python: '/opt/homebrew/bin/python3')
  :python.call(python_pid, :'panoramix.decompiler', :decompile_address, [<<address>>])
  :python.stop(python_pid)

  end

  defp get_etherscan(address) do
    api_key = Context.etherscan_api_key()

    {:ok, base_url} = base_url(Context.chain_id())
    url = "#{base_url}/api?module=contract&action=getabi&address=#{address}&apikey=#{api_key}"

    # NOTE: this request breaks if we don't pass the user-agent header
    {:ok, rsp} = Tesla.get(url, headers: [{"user-agent", "Tesla"}])
    {:ok, result} = handle_response(rsp)

    case Jason.decode(result) do
      {:ok, result} ->
        {:ok, result}

      {:error, %{data: "Contract source code not verified"}} ->
        {:error, :abi_unavailable}
    end
  end

  defp get_local(abi_path) do
    {:ok, file} = File.read(abi_path)
    Jason.decode(file)
  end

  defp handle_response(rsp) do
    case Jason.decode!(rsp.body) do
      %{"result" => result} ->
        {:ok, result}

      %{"error" => error} ->
        {:error, error}
    end
  end

  defp base_url(1), do: {:ok, "https://api.etherscan.io"}
  defp base_url(3), do: {:ok, "https://api-ropsten.etherscan.io"}
  defp base_url(4), do: {:ok, "https://api-rinkeby.etherscan.io"}
  defp base_url(5), do: {:ok, "https://api-goerli.etherscan.io"}
  defp base_url(69), do: {:ok, "https://api-kovan.etherscan.io"}
  defp base_url(_chain_id), do: {:error, :unknown_chain_id_for_etherscan}
end
