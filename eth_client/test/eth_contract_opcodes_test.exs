defmodule EthClientTest.Contract.Opcodes do
  use ExUnit.Case
  doctest EthClient
  alias EthClient.Account
  alias EthClient.Context
  alias EthClient.Contract.Opcodes
  import ExUnit.CaptureIO

  @bin "../contracts/src/bin/Storage.bin"
  @abi "../contracts/src/bin/Storage.abi"
  @ops "../contracts/src/bin/storage_opcodes.txt"

  describe "bytecode_to_opcodes" do
    test "[SUCCESS] retrieve and match the opcodes of storage contract" do
      ops = File.read!(@ops)
      bin = File.read!(@bin) |> add_0x()
      assert ops == capture_io(fn -> Opcodes.bytecode_to_opcodes(bin) end)
    end
  end

  def add_0x(data), do: "0x" <> data
end
