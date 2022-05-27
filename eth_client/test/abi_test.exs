defmodule EthClientTest.ABI do
  use ExUnit.Case
  doctest EthClient
  alias EthClient.ABI
  alias EthClient.Context

  @bin "../contracts/src/bin/Storage.bin"
  @abi "../contracts/src/bin/Storage.abi"

  # setup_all do
  #   EthClient.deploy(@bin, @abi)
  #   :ok
  # end

  describe "get/1" do
    @tag bin: @bin, abi: @abi
    test "[SUCCESS] Get an ABI by an abi path", %{} do
      abi_path = @abi
      result = ABI.get(abi_path)

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

    @tag bin: @bin, abi: @abi
    test "[SUCCESS] Get an ABI by an ABI address" do

      contract = Context.contract()
      address = contract.address

      result = ABI.get(address)

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
  end

end
