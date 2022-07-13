defmodule EthClient do
  @moduledoc false
  alias EthClient.RawTransaction
  alias EthClient.Rpc

  require Logger

  def deploy(chain_config, bin_path) do
    {:ok, data} = File.read(bin_path)
    data = add_0x(data)
    rpc_url = chain_config.rpc_host

    caller_address = chain_config.user_address

    nonce = nonce(rpc_url, caller_address)
    gas_limit = gas_limit(rpc_url, data, caller_address)

    raw_tx =
      build_raw_tx(
        0,
        nonce,
        gas_limit,
        gas_price(rpc_url),
        chain_config.chain_id,
        data: data
      )

    signed_transaction = sign_transaction(raw_tx, chain_config.user_private_key)
    Rpc.send_raw_transaction(rpc_url, signed_transaction)
  end

  def call(chain_config, contract_address, method, arguments) do
    caller_address = chain_config.user_address

    data =
      ABI.encode(method, arguments)
      |> Base.encode16(case: :lower)
      |> add_0x()

    Rpc.call(
      chain_config.rpc_host,
      %{
        from: caller_address,
        to: contract_address,
        data: data
      }
    )
  end

  def get_balance(chain_config, address) do
    {balance, _lead} =
      Rpc.get_balance(chain_config.rpc_host, address)
      |> remove_leading_0x()
      |> Integer.parse(16)

    wei_to_ether(balance)
  end

  def invoke(chain_config, contract_address, method, arguments, amount \\ 0) do
    caller_address = chain_config.user_address
    rpc_url = chain_config.rpc_host

    data =
      ABI.encode(method, arguments)
      |> Base.encode16(case: :lower)
      |> add_0x()

    ## This is assuming the caller passes `amount` in eth
    amount = floor(amount * 1_000_000_000_000_000_000)

    nonce = nonce(rpc_url, caller_address)
    # How do I calculate gas limits appropiately?
    gas_limit = gas_limit(rpc_url, data, caller_address, contract_address) * 2

    raw_tx =
      build_raw_tx(amount, nonce, gas_limit, gas_price(rpc_url), chain_config.chain_id,
        recipient: contract_address,
        data: data
      )


    signed_transaction = sign_transaction(raw_tx, chain_config.user_private_key)
    Rpc.send_raw_transaction(rpc_url, signed_transaction)
  end

  def contract_deploy?(chain_config, transaction) when is_number(transaction) do
    transaction_hex_string = transaction
    |> Integer.to_string(16)
    |> add_0x

    contract_deploy?(chain_config, transaction_hex_string)
  end

  def contract_deploy?(chain_config, transaction) when is_binary(transaction) do
    case Rpc.get_transaction_receipt(chain_config.rpc_host, transaction) do
      {:ok, %{"contractAddress" => nil}} -> false
      {:ok, %{"contractAddress" => _}} -> true
      {:error, msg} -> {:error, msg}
    end
  end

  defp nonce(rpc_url, address) do
    {nonce, ""} =
      Rpc.get_transaction_count(rpc_url, address)
      |> remove_leading_0x()
      |> Integer.parse(16)

    nonce
  end

  defp gas_limit(rpc_url, data, caller_address, recipient_address \\ nil) do
    {gas, ""} =
      Rpc.estimate_gas(
        rpc_url,
        %{
          from: caller_address,
          to: recipient_address,
          data: data
        }
      )
      |> remove_leading_0x()
      |> Integer.parse(16)

    gas
  end

  defp gas_price(rpc_url) do
    {gas_price, ""} =
      Rpc.gas_price(rpc_url)
      |> remove_leading_0x()
      |> Integer.parse(16)

    gas_price
  end

  defp remove_leading_0x({:ok, "0x" <> data}), do: data
  defp add_0x(data), do: "0x" <> data

  defp wei_to_ether(amount), do: amount / 1.0e19

  defp build_raw_tx(amount, nonce, gas_limit, gas_price, chain_id, opts) do
    recipient = opts[:recipient]
    data = opts[:data]

    nonce
    |> RawTransaction.new(amount, gas_limit, gas_price, chain_id, recipient: recipient, data: data)
    |> ExRLP.encode(encoding: :hex)
  end

  use Rustler, otp_app: :eth_client, crate: "ethclient_signer"

  def sign_transaction(_raw_transaction, _private_key), do: :erlang.nif_error(:nif_not_loaded)
end
