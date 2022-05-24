defmodule EthClient.Contract do
  @moduledoc """
  """

  alias EthClient.ABI

  defstruct [:address, :functions]

  def get_functions, do: EthClient.Context.contract.functions

  def get_functions(address_or_path) do
    with {:ok, abi} <- ABI.get(address_or_path) do
    #  abi |> IO.inspect(label: "ordenanza")
      parse_abi(abi)
    end
  end

  defp parse_abi(abi), do: parse_abi(abi, %{})

  defp parse_abi([], acc), do: {:ok, acc}

  defp parse_abi([%{"type" => "function", "name" => name} = method_map | tail], acc) do
    method = %{
      name: name,
      state_mutability: method_map["stateMutability"],
      inputs: Enum.map(method_map["inputs"], fn input -> input["name"] end),
      # What's the difference between type and internal type?
      input_types: Enum.map(method_map["inputs"], fn input -> input["name"] end)
    }

    name_snake_case = String.to_atom(Macro.underscore(method_map["name"]))
    function = build_function(method)
    # TODO: use hashes to make the function call
    acc = Map.put(acc, name_snake_case, Code.eval_quoted(function) |> elem(0))

    parse_abi(tail, acc)
  end

  defp parse_abi([%{"type" => "function", "selector" => selector} = method_map | tail], acc) do
    method = %{
      selector: String.to_atom(selector),
      state_mutability: method_map["stateMutability"],
      inputs: Enum.map(method_map["inputs"], fn input -> input["name"] end),
    }

    function = build_function_by_hash(method)

    selector_atom = String.to_atom(Macro.underscore(method_map["selector"]))
    acc = Map.put(acc, selector_atom, Code.eval_quoted(function) |> elem(0))

    parse_abi(tail, acc)
  end

  defp parse_abi([_head | tail], acc) do
    parse_abi(tail, acc)
  end

  defp build_function_by_hash(%{selector: selector, state_mutability: mutability} = method)
      when mutability in ["pure", "view"] do
    # TODO: use param encoding to encode things here
    args = Macro.generate_arguments(length(method.inputs), __MODULE__)

    quote do
      fn types, unquote_splicing(args) ->
        EthClient.call_by_selector(unquote(selector), types, unquote(args))
      end
    end
  end

  defp build_function_by_hash(%{selector: selector} = method) do
    args = Macro.generate_arguments(length(method.inputs), __MODULE__)
    # TODO: use param encoding to encode things here

    quote do
      fn types, unquote_splicing(args), amount ->
        EthClient.invoke_by_selector(unquote(selector), types, unquote(args), amount)
      end
    end
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
