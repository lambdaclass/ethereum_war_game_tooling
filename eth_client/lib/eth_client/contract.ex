defmodule EthClient.Contract do
  @moduledoc """
  """

  alias EthClient.ABI

  defstruct [:address, :functions]

  def get_functions(address_or_path) do
    with {:ok, abi} <- ABI.get(address_or_path) do
      parse_abi(abi)
    end
  end

  defp parse_abi(abi), do: parse_abi(abi, %{})

  defp parse_abi([], acc), do: {:ok, acc}

  defp parse_abi([%{"type" => "function"} = method_map | tail], acc) do
    method = %{
      name: String.to_atom(Macro.underscore(method_map["name"])),
      state_mutability: method_map["stateMutability"],
      inputs: Enum.map(method_map["inputs"], fn input -> input["name"] end),
      # What's the difference between type and internal type?
      input_types: Enum.map(method_map["inputs"], fn input -> input["internalType"] end)
    }

    function = build_function(method)
    acc = Map.put(acc, method.name, Code.eval_quoted(function) |> elem(0))

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