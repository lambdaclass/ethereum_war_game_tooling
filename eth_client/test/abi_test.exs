defmodule EthClientTest.ABI do
  use ExUnit.Case
  doctest EthClient
  alias EthClient.ABI
  alias EthClient.Context

  @bin "../contracts/src/bin/Storage.bin"
  @abi "../contracts/src/bin/Storage.abi"

  setup_all do
    # Context.set_chain_id(4)
    # Context.set_rpc_host("")
    contract = EthClient.deploy(@bin, @abi)
    :ok
  end

  describe "get/1" do
    test "[SUCCESS] Get an ABI by an abi path", %{} do
      result = ABI.get(@abi)

      assert {:ok,
              [
                %{
                  "inputs" => [],
                  "name" => "retrieve",
                  "outputs" => [
                    %{"internalType" => "uint256", "name" => "", "type" => "uint256"}
                  ],
                  "stateMutability" => "view",
                  "type" => "function"
                },
                %{
                  "inputs" => [
                    %{"internalType" => "uint256", "name" => "num", "type" => "uint256"}
                  ],
                  "name" => "store",
                  "outputs" => [],
                  "stateMutability" => "nonpayable",
                  "type" => "function"
                },
                %{
                  "inputs" => [],
                  "name" => "test_function",
                  "outputs" => [
                    %{"internalType" => "uint256", "name" => "", "type" => "uint256"}
                  ],
                  "stateMutability" => "pure",
                  "type" => "function"
                }
              ]} == result
    end

    test "[SUCCESS] Get an ABI by an ABI address" do
      address = Context.user_account().address

      assert {:ok, _response} = ABI.get(address)
    end

    test "[FAILURE] Get an ABI by an invalid ABI address" do
      address = '0x0'

      assert_raise MatchError, fn ->
        ABI.get(address)
      end
    end
  end
end
