defmodule EthClient do
  @moduledoc false
  alias EthClient.Context
  alias EthClient.Contract
  alias EthClient.RawTransaction
  alias EthClient.Rpc

  require Logger

  @etherscan_supported_chains %{
    1 => "",
    3 => "ropsten.",
    4 => "rinkeby."
  }

  @supported_chains ["ropsten", "rinkeby", "mainnet"]

  @chain_id_by_name %{"mainnet" => 1, "ropsten" => 3, "rinkeby" => 4}

  @local_host_chain_id 1234
  @local_host_rpc "http://localhost:8545"

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
      |> IO.inspect(label: "send_raw_transaction")

    Logger.info("Deployment transaction accepted by the network, tx_hash: #{tx_hash}")
    Logger.info("Waiting for confirmation...")

    {:ok, transaction} = Rpc.wait_for_confirmation(tx_hash)

    contract_address = transaction["contractAddress"]

    Context.set_contract_address(contract_address)
    Logger.info("Contract deployed, address: #{contract_address} Current contract updated")

    log_transaction_info(@etherscan_supported_chains[Context.chain_id()], contract_address)
  end

  def deploy(bin_path, abi_path) do
    deploy(bin_path)
    {:ok, api} = Contract.get_functions(abi_path)
    Context.set_contract_functions(api)

    Context.contract()
  end

  def call(method, arguments) do
    data =
      ABI.encode(method, arguments)
      |> Base.encode16(case: :lower)
      |> add_0x()

    %{
      from: Context.user_account().address,
      to: Context.contract().address,
      data: data
    }
    |> Rpc.call()
  end

  def get_balance(address) do
    {balance, _lead} =
      Rpc.get_balance(address)
      |> remove_leading_0x()
      |> Integer.parse(16)

    wei_to_ether(balance)
  end

  def invoke(method, arguments, amount \\ 0) do
    data =
      ABI.encode(method, arguments)
      |> Base.encode16(case: :lower)
      |> add_0x()

    caller = Context.user_account()
    caller_address = String.downcase(caller.address)
    contract_address = Context.contract().address

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

    log_transaction_info(@etherscan_supported_chains[Context.chain_id()], contract_address)

    {:ok, tx_hash}
  end

  def contract_deploy?(transaction) when is_number(transaction) do
    transaction
    |> Integer.to_string(16)
    |> add_0x
    |> contract_deploy?()
  end

  def contract_deploy?(transaction) when is_binary(transaction) do
    case Rpc.get_transaction_receipt(transaction) do
      {:ok, %{"contractAddress" => nil}} -> false
      {:ok, %{"contractAddress" => _}} -> true
      {:error, msg} -> {:error, msg}
    end
  end

  def set_chain(chain_name) when chain_name in @supported_chains do
    infura_api_key = Context.infura_api_key()
    Context.set_rpc_host("https://#{chain_name}.infura.io/v3/#{infura_api_key}")
    Context.set_chain_id(@chain_id_by_name[chain_name])
  end

  def set_chain("local") do
    Context.set_rpc_host(@local_host_rpc)
    Context.set_chain_id(@local_host_chain_id)
  end

  def set_chain(chain_name) do
    Logger.info("#{chain_name} is not a supported chain.")
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

  defp wei_to_ether(amount), do: amount / 1.0e19

  defp build_raw_tx(amount, nonce, gas_limit, gas_price, opts) do
    recipient = opts[:recipient]
    data = opts[:data]
    chain_id = Context.chain_id()

    nonce
    |> RawTransaction.new(amount, gas_limit, gas_price, chain_id, recipient: recipient, data: data)
    |> ExRLP.encode(encoding: :hex)
  end

  defp log_transaction_info(nil, _contract_address), do: nil

  defp log_transaction_info(chain, contract_address),
    do: Logger.info("Check it out here: https://#{chain}etherscan.io/address/#{contract_address}")

  use Rustler, otp_app: :eth_client, crate: "ethclient_signer"

  def sign_transaction(_raw_transaction, _private_key), do: :erlang.nif_error(:nif_not_loaded)
end
