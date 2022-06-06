defmodule EthClientTest.Rpc do
  use ExUnit.Case
  alias EthClient.Context
  alias EthClient.Rpc
  alias EthClient
  @bin_path "../contracts/src/bin/Storage.bin"

  defp add_0x(data), do: "0x" <> data

  def transaction_deploy() do
    :ok = EthClient.set_chain("local")
    {:ok, data} = File.read(@bin_path)
    data = add_0x(data)

    caller = Context.user_account()
    caller_address = String.downcase(caller.address)
    contract_address = Context.contract().address

    nonce = EthClient.nonce(caller.address)
    gas_limit = EthClient.gas_limit(data, caller_address)

    raw_tx =
      EthClient.build_raw_tx(
        0,
        nonce,
        gas_limit,
        EthClient.gas_price(),
        data: data
      )

    tx_hash = EthClient.sign_transaction(raw_tx, caller.private_key) |> IO.inspect(label: "TX HAAAAAAAAAAASH")

      %{
        data: data,
        caller: caller,
        caller_address: caller_address,
        contract_address: contract_address,
        nonce: nonce,
        gas_limit: gas_limit,
        raw_tx: raw_tx,
        tx_hash: tx_hash
      }
  end

  setup_all do
    transaction_deploy()
  end

  describe "Rpc Module" do
    test "[SUCCESS] Send raw transaction", state do
      assert {:ok, tx_hash} = Rpc.send_raw_transaction(state[:tx_hash])
    end

    test "[SUCCESS] Estimate Gas", state do
      transaction_map = %{data: state[:data], from: state[:caller_address], to: nil}
      assert {:ok, gas} = Rpc.estimate_gas(transaction_map)
    end

    test "[SUCCESS] Get Transaction Count", state do
      assert {:ok, count} = Rpc.get_transaction_count(state[:caller_address])
    end

    test "[SUCCESS] Gas Price" do
      assert {:ok, price} = Rpc.gas_price()
    end

    test "[SUCCESS] Get Transaction by Hash" do
      assert {:ok, %{}} = Rpc.get_transaction_by_hash("0xf6bebadd44e6d5e1446f6456ae4c4fcb8309631747714199e505aa4cec1c2019")
    end

    test "[SUCCESS] Get Transaction Receipt" do
      assert {:ok, %{}} = Rpc.get_transaction_receipt("0xf6bebadd44e6d5e1446f6456ae4c4fcb8309631747714199e505aa4cec1c2019")
    end

    test "[SUCCESS] Get Code", state do
      assert {:ok, "0x"} = Rpc.get_code(state[:caller_address])
    end

    test "[SUCCESS] Get Call", state do
      call_map = %{}
      assert {:ok, "0x"} = Rpc.call(call_map)
    end

    test "[SUCCESS] Get Logs" do
      assert {:ok, []} = Rpc.get_logs(%{})
    end

    test "[SUCCESS] Get Balance", state do
      assert {:ok, balance} = Rpc.get_balance(state[:caller_address])
    end
  end
end
