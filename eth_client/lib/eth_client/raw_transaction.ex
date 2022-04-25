defmodule EthClient.RawTransaction do
  @moduledoc """
  `nonce`, `amount`, `gas_price` and `gas_limit` are meant to be 256 bit unsigned integers,
  but the RLP library we use handles it already.
  `recipient` is a 160 bits (20 bytes) hash. ExRLP also handles that.
  """
  @enforce_keys [:nonce, :gas_price, :gas_limit, :amount]
  defstruct [:nonce, :gas_price, :gas_limit, :recipient, :amount, :data, :chain_id]

  def new(nonce, amount, gas_limit, gas_price, chain_id, opts \\ []) do
    recipient = opts[:recipient]
    data = opts[:data]

    %__MODULE__{
      recipient: parse_recipient(recipient),
      nonce: nonce,
      amount: amount,
      gas_limit: gas_limit,
      gas_price: gas_price,
      data: parse_data(data),
      chain_id: chain_id
    }
  end

  defp parse_recipient(nil), do: []
  defp parse_recipient("0x" <> recipient), do: Base.decode16!(recipient, case: :mixed)
  defp parse_recipient(recipient), do: Base.decode16!(recipient, case: :mixed)

  defp parse_data(nil), do: []
  defp parse_data("0x" <> data), do: Base.decode16!(data, case: :mixed)
  defp parse_data(data), do: Base.decode16!(data, case: :mixed)

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
      [:nonce, :gas_price, :gas_limit, :recipient, :amount, :data, :chain_id]
      |> Enum.map(fn field ->
        Map.get(raw_transaction, field)
      end)
    end
  end
end
