defmodule EthClient.Contract.Opcodes do
  @moduledoc """
   This module provides a function to turn any valid EVM byte code
   into opcodes and a function to retrieve a contract and turn it into
   its opcodes.
  """
  def bytecode_to_opcodes(code) when is_binary(code) do
    parse_code(code, [])
  end

  defp get_opcodes do
    opcodes_from_file!()
    |> parse_opcodes()
  end

  defp opcodes_from_file! do
    "./opcodes.json"
    |> Path.expand()
    |> File.read!()
  end

  defp parse_opcodes(codes) do
    codes
    |> Jason.decode!()
    |> filter_invalid()
  end

  defp filter_invalid(code_list) do
    Enum.reduce(code_list, fn
      %{"Hex" => _hex, "Name" => name}, acc when name == "*invalid*" -> acc
      %{"Hex" => hex, "Name" => name}, acc -> Map.put(acc, hex, name)
    end)
  end

  # First remove the leading 0x,
  # upcase to keep it consistent with the JSON.
  defp parse_code(<<"0x", rest::binary>>, []) do
    rest
    |> String.upcase()
    |> parse_code([], get_opcodes())
  end

  # Opcodes are base16 numbers ranging from
  # 00 up to FF, they come inside a string,
  # so we match them every 2 characters and
  # check the instruction matching those two characters
  # Let's say we have FFAAFF, this function clause
  # would match like this:
  # opcode = "FF"
  # rest = "AAFF"
  # And FF matches with the "SELFDESTRUCT" instruction.
  defp parse_code(<<opcode::binary-size(2), rest::binary>>, acum, opcodes) do
    case Map.get(opcodes, opcode) do
      nil ->
        parse_code(rest, ["#{opcode} opcode is unknown" | acum], opcodes)

      <<"PUSH", n::binary>> ->
        {arguments, rest} = fetch_arguments(rest, n, :push)
        parse_code(rest, ["PUSH 0x#{arguments}" | acum], opcodes)

      instruction ->
        parse_code(rest, [instruction | acum], opcodes)
    end
  end

  # When this matches, we have finished parsing the string.
  defp parse_code(_, acum, _) do
    acum
    |> Enum.reverse()
    |> Enum.with_index(fn string, index -> "[#{index}] " <> string end)
    |> Enum.join("\n")
    |> IO.puts()
  end

  defp fetch_arguments(code, n, :push) when is_binary(n) do
    chars_to_fetch = String.to_integer(n) * 2
    <<arguments::binary-size(chars_to_fetch), rest::binary>> = code
    {arguments, rest}
  end
end
