defmodule EthClientTest do
  use ExUnit.Case
  doctest EthClient
  alias EthClient.Context
  alias EthClient.Account

  @bin "../contracts/src/bin/Storage.bin"
  @abi "../contracts/src/bin/Storage.abi"

  describe "Ethereum war tooling functions" do
    test "Deploy" do
      bin = @bin
      abi = @abi

      contract = EthClient.deploy(bin, abi)
      assert contract == EthClient.Context.contract()
    end

    test "Invoke" do
      bin = @bin
      abi = @abi

      contract = EthClient.deploy(bin, abi)
      {:ok, tx_ans} = EthClient.invoke("store(uint256)", [3], 0)
      assert tx_ans != nil
    end

    test "Call" do
      bin = @bin
      abi = @abi

      contract = EthClient.deploy(bin, abi)
      {:ok, res} = EthClient.call("retrieve()", [])
      assert res == "0x0000000000000000000000000000000000000000000000000000000000000000"
      {:ok, res} = EthClient.call("test_function()", [])
      assert res == "0x0000000000000000000000000000000000000000000000000000000000000001"
    end

    test "Balance" do
      bin = @bin
      abi = @abi

      contract = EthClient.deploy(bin, abi)

      assert 0.0 == EthClient.get_balance(contract.address)
    end
  end
end
