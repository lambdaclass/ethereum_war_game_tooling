defmodule EthClient.Rpc do
  @moduledoc false

  alias EthClient.Context
  use Tesla

  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  @tx_confirmation_waiting_time 1_000

  def send_raw_transaction(raw_tx), do: send_request("eth_sendRawTransaction", [raw_tx])
  def estimate_gas(transaction_map), do: send_request("eth_estimateGas", [transaction_map])

  def get_transaction_count(address),
    do: send_request("eth_getTransactionCount", [address, "latest"])

  def gas_price, do: send_request("eth_gasPrice", [])

  def create_access_list(transaction_map),
    do: send_request("eth_createAccessList", [transaction_map])

  def max_priority_fee_per_gas, do: send_request("eth_maxPriorityFeePerGas", [])
  def get_transaction_by_hash(tx_hash), do: send_request("eth_getTransactionByHash", [tx_hash])
  def get_transaction_receipt(tx_hash), do: send_request("eth_getTransactionReceipt", [tx_hash])

  def get_code(contract) do
    {:ok, result} = send_request("eth_getCode", [contract, "latest"])

    case result do
      "0x" -> {:error, "The contract you are trying to get the code is not deployed"}
      _valid -> {:ok, result}
    end
  end

  def call(call_map), do: send_request("eth_call", [call_map, "latest"])

  def get_logs(log_map), do: send_request("eth_getLogs", [log_map])

  def wait_for_confirmation(tx_hash) do
    attempts = 100
    wait_for_tx(tx_hash, nil, attempts)
  end

  def get_balance(address), do: send_request("eth_getBalance", [address, "latest"])

  defp wait_for_tx(_tx_hash, nil, 0) do
    {:error, :transaction_not_mined}
  end

  defp wait_for_tx(tx_hash, nil, attempts) do
    Process.sleep(@tx_confirmation_waiting_time)
    {:ok, transaction} = get_transaction_by_hash(tx_hash)
    block_number = transaction["blockNumber"]

    wait_for_tx(tx_hash, block_number, attempts - 1)
  end

  defp wait_for_tx(tx_hash, _block_number, _attempts) do
    get_transaction_receipt(tx_hash)
  end

  defp send_request(method, args) do
    payload = build_payload(method, args)

    {:ok, rsp} =
      case Context.net_proxy() do
        :tor ->
          tor_connection(payload)

        _none ->
          post(Context.rpc_host(), payload)
      end

    handle_response(rsp)
  end

  defp tor_connection(payload) do
    post(Context.rpc_host(), payload,
      opts: [adapter: [proxy: {:socks5, '127.0.0.1', 9050}, recv_timeout: 60_000]]
    )
  end

  defp build_payload(method, params) do
    %{
      jsonrpc: "2.0",
      id: Enum.random(1..9_999_999),
      method: method,
      params: params
    }
    |> Jason.encode!()
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
