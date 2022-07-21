defmodule EthClient.RawTransaction do
  @moduledoc """
  `nonce`, `amount`, `gas_price` and `gas_limit` are meant to be 256 bit unsigned integers,
  but the RLP library we use handles it already.
  `recipient` is a 160 bits (20 bytes) hash. ExRLP also handles that.
  """
  defstruct [
    :chain_id,
    :nonce,
    :max_priority_fee_per_gas,
    :max_fee_per_gas,
    :gas_limit,
    :recipient,
    :amount,
    :data,
    :access_list
  ]

  def new(
        chain_id,
        nonce,
        max_priority_fee_per_gas,
        max_fee_per_gas,
        gas_limit,
        amount,
        opts \\ []
      ) do
    recipient = opts[:recipient]
    data = opts[:data]
    {:ok, parsed_access_list} = parse_access_list(opts[:access_list])

    %__MODULE__{
      recipient: parse_recipient(recipient),
      nonce: nonce,
      amount: amount,
      gas_limit: gas_limit,
      max_priority_fee_per_gas: max_priority_fee_per_gas,
      max_fee_per_gas: max_fee_per_gas,
      data: parse_data(data),
      chain_id: chain_id,
      access_list: parsed_access_list
    }
  end

  defp parse_access_list(nil), do: {:ok, []}

  defp parse_access_list(access_list) do
    parse_access_list(access_list, [])
  end

  defp parse_access_list([], acc), do: {:ok, acc}

  defp parse_access_list([head | tail], acc) do
    [address | storage_keys_list] = head
    address_hex = decode16(address)

    storage_keys_hex =
      case storage_keys_list do
        [storage_keys] ->
          Enum.map(storage_keys, fn storage_key ->
            decode16(storage_key)
          end)

        [] ->
          []
      end

    acc = List.insert_at(acc, -1, List.insert_at([address_hex], -1, storage_keys_hex))
    parse_access_list(tail, acc)
  end

  defp parse_recipient(nil), do: []
  defp parse_recipient(recipient), do: decode16(recipient)

  defp parse_data(nil), do: []
  defp parse_data(data), do: decode16(data)

  defp decode16("0x" <> data), do: Base.decode16!(data, case: :mixed)
  defp decode16(data), do: Base.decode16!(data, case: :mixed)

  defimpl ExRLP.Encode, for: EthClient.RawTransaction do
    alias ExRLP.Encode

    def encode(raw_transaction, options \\ []) do
      raw_transaction
      |> to_list()
      |> Encode.encode(options)
    end

    defp to_list(raw_transaction) do
      # NOTE: The order of fields here is PARAMOUNT. If you rearrange them
      # the RLP encoding will be incorrect.
      [
        :chain_id,
        :nonce,
        :max_priority_fee_per_gas,
        :max_fee_per_gas,
        :gas_limit,
        :recipient,
        :amount,
        :data,
        :access_list
      ]
      |> Enum.map(fn field ->
        Map.get(raw_transaction, field)
      end)
    end
  end
end
