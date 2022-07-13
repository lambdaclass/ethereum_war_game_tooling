defmodule EthClient.Contract do
  @moduledoc false

  alias EthClient.ABI
  alias EthClient.Contract.Opcodes
  alias EthClient.Rpc

  defstruct [:address, :functions]
  def get_functions(address_or_path) do
    with {:ok, abi} <- ABI.get(address_or_path) do
      parse_abi(abi)
    end
  end

  @doc """
  Using the contract in the context, returns the current state of the contract.
  """
  def state(contract_address) do
    with {:ok, abi} <- ABI.get(contract_address) do
      state_from_abi(abi)
    end
  end

  defp state_from_abi(abi) do
    Enum.reduce(abi, %{}, fn operation, acc ->
      if is_contract_state?(operation) do
        %{"name" => name} = operation
        {:ok, value} = EthClient.call("#{name}()", [])
        Map.put(acc, name, value)
      else
        acc
      end
    end)
  end

  defp is_contract_state?(%{"inputs" => [], "stateMutability" => "view", "type" => "function"}),
    do: true

  defp is_contract_state?(_operation), do: false

  def to_opcodes do
    EthClient.Context.contract().address
    |> contract_to_opcodes!()
  end

  def contract_to_opcodes!(address) when is_binary(address) do
    {:ok, code} = Rpc.get_code(address)
    Opcodes.bytecode_to_opcodes(code)
  end

  defp parse_abi(abi), do: parse_abi(abi, %{})

  defp parse_abi([], acc), do: {:ok, acc}

  defp parse_abi([%{"type" => "function"} = method_map | tail], acc) do
    method = %{
      name: String.to_atom(method_map["name"]),
      state_mutability: method_map["stateMutability"],
      inputs: Enum.map(method_map["inputs"], fn input -> input["name"] end),
      # What's the difference between type and internal type?
      input_types: Enum.map(method_map["inputs"], fn input -> input["internalType"] end)
    }

    name_snake_case = String.to_atom(Macro.underscore(method_map["name"]))
    function = build_function(method)
    acc = Map.put(acc, name_snake_case, Code.eval_quoted(function) |> elem(0))

    parse_abi(tail, acc)
  end

  defp parse_abi([_head | tail], acc) do
    parse_abi(tail, acc)
  end

  defp build_function(%{state_mutability: mutability} = method)
       when mutability in ["pure", "view"] do
    args = Macro.generate_arguments(length(method.inputs), __MODULE__)
    method_signature = "#{method.name}(#{Enum.join(method.input_types, ",")})"

    quote do
      fn unquote_splicing(args) ->
        EthClient.call(unquote(method_signature), unquote(args))
      end
    end
  end

  defp build_function(method) do
    args = Macro.generate_arguments(length(method.inputs), __MODULE__)
    method_signature = "#{method.name}(#{Enum.join(method.input_types, ",")})"

    quote do
      fn unquote_splicing(args), amount ->
        EthClient.invoke(unquote(method_signature), unquote(args), amount)
      end
    end
  end
end
