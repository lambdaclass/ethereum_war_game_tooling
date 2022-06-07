defmodule EthClientTest.Rpc do
  use ExUnit.Case
  alias EthClient
  alias EthClient.Context
  alias EthClient.Rpc

  @bin_path "../contracts/src/bin/Storage.bin"

  def transaction_deploy() do
    :ok = EthClient.set_chain("local")
    {:ok, data} = File.read(@bin_path)
    data = "0x" <> data

    caller = Context.user_account()
    caller_address = String.downcase(caller.address)

    %{
      data: data,
      caller_address: caller_address
    }
  end

  setup_all do
    transaction_deploy()
  end

  describe "Rpc Module" do
    test "[SUCCESS] Send raw transaction", state do
      caller = Context.user_account()

      raw_tx =
        EthClient.build_raw_tx(
          0,
          EthClient.nonce(caller.address),
          EthClient.gas_limit(state[:data], caller.address),
          EthClient.gas_price(),
          data: state[:data]
        )

      tx_hash = EthClient.sign_transaction(raw_tx, Context.user_account().private_key)

      {:ok, tx_hash} = Rpc.send_raw_transaction(tx_hash)
      assert tx_hash =~ "0x"
    end

    test "[SUCCESS] Estimate Gas", state do
      transaction_map = %{data: state[:data], from: state[:caller_address], to: nil}
      {:ok, gas} = Rpc.estimate_gas(transaction_map)
      assert gas =~ "0x"
    end

    test "[SUCCESS] Get Transaction Count", state do
      {:ok, count} = Rpc.get_transaction_count(state[:caller_address])
      assert count =~ "0x"
    end

    test "[SUCCESS] Gas Price" do
      {:ok, gas_price} = Rpc.gas_price()
      assert gas_price =~ "0x"
    end

    test "[SUCCESS] Get Transaction by Hash" do
      {:ok, transaction_map} =
        Rpc.get_transaction_by_hash(
          "0xf6bebadd44e6d5e1446f6456ae4c4fcb8309631747714199e505aa4cec1c2019"
        )

      assert %{
               "blockHash" => _,
               "blockNumber" => _,
               "from" => _,
               "gas" => _,
               "gasPrice" => _,
               "hash" => _,
               "input" => _,
               "nonce" => _,
               "r" => _,
               "s" => _,
               "to" => nil,
               "transactionIndex" => _,
               "type" => _,
               "v" => _,
               "value" => _
             } = transaction_map
    end

    test "[SUCCESS] Get Transaction Receipt" do
      {:ok, receipt_map} =
        Rpc.get_transaction_receipt(
          "0xf6bebadd44e6d5e1446f6456ae4c4fcb8309631747714199e505aa4cec1c2019"
        )

      assert %{
               "blockHash" => _blockhash,
               "blockNumber" => _blocknumber,
               "contractAddress" => _contactAdress,
               "cumulativeGasUsed" => _cumulativeGasUsed,
               "effectiveGasPrice" => _effectiveGasPrice,
               "from" => _from,
               "gasUsed" => _gasUser,
               "logs" => [],
               "logsBloom" => _logsBloom,
               "status" => _status,
               "to" => nil,
               "transactionHash" => _transactionHash,
               "transactionIndex" => _transactionIndex,
               "type" => _type
             } = receipt_map
    end

    test "[SUCCESS] Get Code", state do
      assert {:ok, "0x"} == Rpc.get_code(state[:caller_address])
    end

    test "[SUCCESS] Get Call", state do
      call_map = %{}
      assert {:ok, "0x"} == Rpc.call(call_map)
    end

    test "[SUCCESS] Get Logs" do
      assert {:ok, []} = Rpc.get_logs(%{})
    end

    test "[SUCCESS] Get Balance", state do
      {:ok, balance} = Rpc.get_balance(state[:caller_address])
      assert balance =~ "0x"
    end
  end
end
