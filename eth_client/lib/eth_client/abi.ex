defmodule EthClient.ABI do

    def get(address), do: get_etherscan(address)

    def get_etherscan(address) do
        api_key = Application.fetch_env!(:eth_client, :etherscan)
        url = "https://api.etherscan.io/api?module=contract&action=getabi&address=#{address}&apikey=#{api_key}"

        {:ok, rsp} = Tesla.get(url)
        {:ok, result} = handle_response(rsp)
        Jason.decode!(result)
    end

    defp handle_response(rsp) do
        case Jason.decode!(rsp.body) do
            %{"result" => result} ->
                {:ok, result}

            %{"error" => error} ->
                {:error, error}
        end
    end
end
