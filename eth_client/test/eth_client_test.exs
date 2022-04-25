defmodule EthClientTest do
  use ExUnit.Case
  doctest EthClient

  test "greets the world" do
    assert EthClient.hello() == :world
  end
end
