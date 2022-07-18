defmodule EthClient.NewRawTransaction do
  @moduledoc """
  `nonce`, `amount`, `gas_price` and `gas_limit` are meant to be 256 bit unsigned integers,
  but the RLP library we use handles it already.
  `recipient` is a 160 bits (20 bytes) hash. ExRLP also handles that.
  """

  # @enforce_keys [:nonce, :gas_price, :gas_limit, :amount]
  # defstruct [:nonce, :gas_price, :gas_limit, :recipient, :amount, :data, :chain_id]

  defstruct [
    :chain_id,
    :nonce,
    :max_priority_fee_per_gas,
    :max_fee_per_gas,
    :gas_limit,
    :destination,
    :amount,
    :data,
    :access_list
  ]

  # transaction_payload = rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination,
  # amount, data, access_list, signature_y_parity, signature_r, signature_s])

  # transaction = transaction_type || transaction_payload

  # The signature_y_parity, signature_r, signature_s elements of this transaction represent
  # a secp256k1 signature over keccak256(0x02 || rlp([chain_id, nonce, max_priority_fee_per_gas,
  # max_fee_per_gas, gas_limit, destination, amount, data, access_list])).

  def new(
        chain_id,
        nonce,
        max_priority_fee_per_gas,
        max_fee_per_gas,
        gas_limit,
        destination,
        amount,
        opts \\ []
      ) do
    access_list = opts[:access_list]
    data = opts[:data]

    %__MODULE__{
      chain_id: chain_id,
      nonce: nonce,
      max_priority_fee_per_gas: max_priority_fee_per_gas,
      max_fee_per_gas: max_fee_per_gas,
      gas_limit: gas_limit,
      destination: parse_recipient(destination),
      data: parse_data(data),
      amount: amount,
      access_list: access_list
    }
  end

  defp parse_recipient(nil), do: []
  defp parse_recipient("0x" <> recipient), do: Base.decode16!(recipient, case: :mixed)
  defp parse_recipient(recipient), do: Base.decode16!(recipient, case: :mixed)

  defp parse_data(nil), do: []
  defp parse_data("0x" <> data), do: Base.decode16!(data, case: :mixed)
  defp parse_data(data), do: Base.decode16!(data, case: :mixed)

  defimpl ExRLP.Encode, for: EthClient.NewRawTransaction do
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
        :destination,
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
