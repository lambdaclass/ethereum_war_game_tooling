defmodule EthClient.Contract do
  @moduledoc """
  """

  alias EthClient.ABI

  defstruct [:address, :functions]

  def get_functions, do: EthClient.Context.contract().functions

  def get_functions(address_or_path) do
    with {:ok, abi} <- ABI.get(address_or_path) do
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
      input_types: Enum.map(method_map["inputs"], fn input -> input["internalType"] end)
    }

    name_snake_case = String.to_atom(Macro.underscore(name))
    function = build_function(method)
    acc = Map.put(acc, name_snake_case, Code.eval_quoted(function) |> elem(0))

    parse_abi(tail, acc)
  end

  defp parse_abi([%{function: name} = method_map | tail], acc) do
    function = build_function_by_hash(method_map)

    selector_atom =
      name
      |> Macro.underscore()
      |> String.to_atom()

      {term, _bind} = Code.eval_quoted(function)
      acc = Map.put(acc, selector_atom, term)

    parse_abi(tail, acc)
  end

  defp parse_abi([%{type: _function, method_id: selector} = method_map | tail], acc) do
    function = build_function_by_hash(method_map)

    selector_atom =
      selector
      |> String.to_atom()

      {term, _bind} = Code.eval_quoted(function)
      acc = Map.put(acc, selector_atom, term)

    parse_abi(tail, acc)
  end

  defp parse_abi([_head | tail], acc) do
    parse_abi(tail, acc)
  end

  defp build_function_by_hash(%{method_id: _selector, state_mutability: mutability} = method)
       when mutability in ["pure", "view"] do
    args =
      method.types
      |> length()
      |> Macro.generate_arguments(__MODULE__)

    bound_method = Macro.escape(method)

    quote do
      fn unquote_splicing(args) ->
        EthClient.call_by_selector(unquote(bound_method), unquote(args))
      end
    end
  end

  defp build_function_by_hash(%{method_id: _selector} = method) do
    args =
      method
      |> Map.get(:types)
      |> length()
      |> Macro.generate_arguments(__MODULE__)

    bound_method = Macro.escape(method)

    quote do
      fn unquote_splicing(args), amount ->
        EthClient.invoke_by_selector(unquote(bound_method), unquote(args), amount)
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
