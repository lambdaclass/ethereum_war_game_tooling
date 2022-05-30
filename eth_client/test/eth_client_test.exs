defmodule EthClientTest do
  use ExUnit.Case
  doctest EthClient

  @bin "../contracts/src/bin/Storage.bin"
  @abi "../contracts/src/bin/Storage.abi"

  setup_all do
    contract = EthClient.deploy(@bin, @abi)
    {:ok, contract: contract}
  end

  describe "deploy/2" do
    test "[SUCCESS] Succesful deploy", %{contract: contract} do
      assert contract == EthClient.Context.contract()
    end
  end

  describe "invoke/3" do
    test "[SUCCESS] invokes a function it returns the transaction hash" do
      {:ok, tx_ans} = EthClient.invoke("store(uint256)", [3], 0)
      assert tx_ans != nil
    end

    test "[FAILURE] invokes a function with incorrect amount of params" do
      assert_raise FunctionClauseError, fn -> EthClient.invoke("store(uint256)", []) end
    end

    test "[FAILURE] invokes a contract function with incorrect params" do
      assert_raise FunctionClauseError, fn -> EthClient.invoke("store(uint256)", [], 0) end
    end
  end

  describe "call/2" do
    test "[SUCCESS] Call" do
      {:ok, res} = EthClient.call("retrieve()", [])
      assert res == "0x0000000000000000000000000000000000000000000000000000000000000003"
      {:ok, res} = EthClient.call("test_function()", [])
      assert res == "0x0000000000000000000000000000000000000000000000000000000000000001"
    end

    test "[FAILURE] calls a function with incorrect amount of params" do
      assert_raise UndefinedFunctionError, fn -> EthClient.call("retrieve()") end
    end

    test "[FAILURE] calls a contract function with incorrect params" do
      assert_raise FunctionClauseError, fn -> EthClient.call("retrieve()", [12]) end
    end
  end

  describe "balance/1" do
    test "[SUCCESS] Balance", %{contract: contract} do
      assert 0.0 == EthClient.get_balance(contract.address)
    end

    test "[FAILURE] unexisting address", %{contract: _contract} do
      assert_raise FunctionClauseError, fn -> EthClient.get_balance("0x123213b") end
    end
  end
end
