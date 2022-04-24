defmodule EthClient do
  @moduledoc """
  """
  alias EthClient.Rpc
  alias EthClient.Context
  alias EthClient.RawTransaction

  require Logger

  # TODO:
  # Modify the code so that the only thing we do in Rust is the EC signature and Keccak hashing
  # View the state of a contract (all its variables, etc). This will require parsing the ABI
  # Obtain the ABI of a deployed contract
  # Add the ability to check if a transaction is a contract deployment or not
  # Check balance
  # Fix gas limit
  # Change shell text based on context
  # Get list of nodes

  def deploy(bin_path) do
    {:ok, data} = File.read(bin_path)
    data = add_0x(data)

    caller = Context.user_account()
    caller_address = String.downcase(caller.address)

    nonce = nonce(caller.address)
    gas_limit = gas_limit(data, caller_address)

    raw_tx =
      build_raw_tx(
        0,
        nonce,
        gas_limit,
        gas_price(),
        data: data
      )

    {:ok, tx_hash} =
      sign_transaction(raw_tx, caller.private_key)
      |> Rpc.send_raw_transaction()

    Logger.info("Deployment transaction accepted by the network, tx_hash: #{tx_hash}")
    Logger.info("Waiting for confirmation...")

    {:ok, transaction} = Rpc.wait_for_confirmation(tx_hash)

    contract_address = transaction["contractAddress"]

    Context.set_current_contract(contract_address)
    Logger.info("Contract deployed, address: #{contract_address} Current contract updated")
  end

  def call(method, arguments) do
    data =
      ABI.encode(method, arguments)
      |> Base.encode16(case: :lower)
      |> add_0x()

    %{
      from: Context.user_account().address,
      to: Context.current_contract(),
      data: data
    }
    |> Rpc.call()
  end

  def invoke(method, arguments, amount) do
    data =
      ABI.encode(method, arguments)
      |> Base.encode16(case: :lower)
      |> add_0x()

    caller = Context.user_account()
    caller_address = String.downcase(caller.address)
    contract_address = Context.current_contract()

    ## This is assuming the caller passes `amount` in eth
    amount = floor(amount * 1_000_000_000_000_000_000)

    nonce = nonce(caller.address)
    # How do I calculate gas limits appropiately?
    gas_limit = gas_limit(data, caller_address, contract_address) * 2

    raw_tx =
      build_raw_tx(amount, nonce, gas_limit, gas_price(),
        recipient: contract_address,
        data: data
      )

    {:ok, tx_hash} =
      sign_transaction(raw_tx, caller.private_key)
      |> Rpc.send_raw_transaction()

    Logger.info("Transaction accepted by the network, tx_hash: #{tx_hash}")
    Logger.info("Waiting for confirmation...")

    {:ok, _transaction} = Rpc.wait_for_confirmation(tx_hash)

    Logger.info("Transaction confirmed!")

    {:ok, tx_hash}
  end

  defp nonce(address) do
    {nonce, ""} =
      Rpc.get_transaction_count(address)
      |> remove_leading_0x()
      |> Integer.parse(16)

    nonce
  end

  defp gas_limit(data, caller_address, recipient_address \\ nil) do
    {gas, ""} =
      %{
        from: caller_address,
        to: recipient_address,
        data: data
      }
      |> Rpc.estimate_gas()
      |> remove_leading_0x()
      |> Integer.parse(16)

    gas
  end

  defp gas_price do
    {gas_price, ""} =
      Rpc.gas_price()
      |> remove_leading_0x()
      |> Integer.parse(16)

    gas_price
  end

  defp remove_leading_0x({:ok, "0x" <> data}), do: data
  defp add_0x(data), do: "0x" <> data

  defp build_raw_tx(amount, nonce, gas_limit, gas_price, opts) do
    recipient = opts[:recipient]
    data = opts[:data]
    chain_id = Context.chain_id()

    nonce
    |> RawTransaction.new(amount, gas_limit, gas_price, chain_id, recipient: recipient, data: data)
    |> ExRLP.encode(encoding: :hex)
  end

  use Rustler, otp_app: :eth_client, crate: "ethclient_signer"

  def sign_transaction(_raw_transaction, _private_key), do: :erlang.nif_error(:nif_not_loaded)
end