defmodule EthClient.Contract.Opcodes do
  alias EthClient.Rpc
  # Temporary storage for the opcodes,
  # should I improve this?
  @opcodes "./opcodes.json"
           |> Path.expand()
           |> File.read!()
           |> Jason.decode!()
           |> Enum.reduce(%{}, fn %{"Hex" => hex, "Name" => name}, map_acum ->
             case name do
               "*invalid*" -> map_acum
               _ -> Map.put(map_acum, hex, name)
             end
           end)

  @moduledoc """
   This module provides a function to turn any valid EVM byte code
   into opcodes and a function to retrieve a contract and turn it into
   its opcodes.
  """
  def bytecode_to_opcodes(code) when is_binary(code) do
    parse_code(code, [])
  end


  # First remove the leading 0x,
  # upcase to keep it consistent with the JSON.
  defp parse_code(<<"0x", rest::binary>>, []) do
    rest
    |> String.upcase()
    |> parse_code([])
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
  defp parse_code(<<opcode::binary-size(2), rest::binary>>, acum) do
    case Map.get(@opcodes, opcode) do
      nil ->
        parse_code(rest, ["#{opcode} opcode is unknown" | acum])

      <<"PUSH", n::binary>> ->
        {arguments, rest} = fetch_arguments(rest, n, :push)
        parse_code(rest, ["PUSH 0x#{arguments}" | acum])

      instruction ->
        parse_code(rest, [instruction | acum])
    end
  end

  # When this matches, we have finished parsing the string.
  defp parse_code(_, acum) do
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
