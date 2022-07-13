defmodule Frontend.Method do
  @moduledoc """
  A struct representing a solidity method.
  """
  # Arguments is a keyword list where the key is the name of the argument
  # and the value is the type
  # The order of elements in this list is VERY important. It corresponds to the order
  # of the arguments in the method, which matters when we construct the transaction to call it.
  # :mutability is what decides whether it's a `call` or an `invoke`
  defstruct [:name, :arguments, :mutability, :outputs]

  def new(name, arguments, mutability, outputs) do
    %__MODULE__{name: name, arguments: arguments, mutability: mutability, outputs: outputs}
  end

  def call(chain_config, contract_address, method, args) do
    method_signature = "#{method.name}(#{Enum.join(Keyword.values(method.arguments), ",")})"
    EthClient.call(chain_config, contract_address, method_signature, args)
  end

  def invoke(chain_config, contract_address, method, args, amount) do
    method_signature = "#{method.name}(#{Enum.join(Keyword.values(method.arguments), ",")})"
    EthClient.invoke(chain_config, contract_address, method_signature, args, amount)
  end
end
