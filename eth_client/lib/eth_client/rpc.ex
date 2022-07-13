defmodule EthClient.Rpc do
  @moduledoc false

  use Tesla

  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  @tx_confirmation_waiting_time 1_000

  def send_raw_transaction(url, raw_tx), do: send_request(url, "eth_sendRawTransaction", [raw_tx])

  def estimate_gas(url, transaction_map),
    do: send_request(url, "eth_estimateGas", [transaction_map])

  def get_transaction_count(url, address),
    do: send_request(url, "eth_getTransactionCount", [address, "latest"])

  def gas_price(url), do: send_request(url, "eth_gasPrice", [])

  def get_transaction_by_hash(url, tx_hash),
    do: send_request(url, "eth_getTransactionByHash", [tx_hash])

  def get_transaction_receipt(url, tx_hash),
    do: send_request(url, "eth_getTransactionReceipt", [tx_hash])

  def get_code(url, contract) do
    {:ok, result} = send_request(url, "eth_getCode", [contract, "latest"])

    case result do
      "0x" -> {:error, "The contract you are trying to get the code is not deployed"}
      _valid -> {:ok, result}
    end
  end

  def call(url, call_map), do: send_request(url, "eth_call", [call_map, "latest"])

  def get_logs(url, log_map), do: send_request(url, "eth_getLogs", [log_map])

  def wait_for_confirmation(url, tx_hash) do
    attempts = 100
    wait_for_tx(url, tx_hash, nil, attempts)
  end

  def get_balance(url, address), do: send_request(url, "eth_getBalance", [address, "latest"])

  defp wait_for_tx(_url, _tx_hash, nil, 0) do
    {:error, :transaction_not_mined}
  end

  defp wait_for_tx(url, tx_hash, nil, attempts) do
    Process.sleep(@tx_confirmation_waiting_time)
    {:ok, transaction} = get_transaction_by_hash(url, tx_hash)
    block_number = transaction["blockNumber"]

    wait_for_tx(url, tx_hash, block_number, attempts - 1)
  end

  defp wait_for_tx(url, tx_hash, _block_number, _attempts) do
    get_transaction_receipt(url, tx_hash)
  end

  defp send_request(url, method, args) do
    payload = build_payload(method, args)

    {:ok, rsp} = post(url, payload)

    handle_response(rsp)
  end

  defp tor_connection(url, payload) do
    post(url, payload,
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
