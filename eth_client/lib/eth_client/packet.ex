defmodule EthClient.Packet do
  @moduledoc """
  """
  defstruct [:version, :from, :to, :expiration]

  def new(version, from, to, expiration) do
    %__MODULE__{
      version: version,
      from: from,
      to: to,
      expiration: expiration
    }
  end

  defimpl ExRLP.Encode, for: EthClient.Packet do
    alias ExRLP.Encode

    def encode(raw_transaction, options \\ []) do
      raw_transaction
      |> to_list()
      |> Encode.encode(options)
    end

    defp to_list(raw_transaction) do
      # NOTE: The order of fields here is PARAMOUNT. If you rearrange them
      # the RLP encoding will be incorrect.
      [:version, :from, :to, :expiration]
      |> Enum.map(fn field ->
        Map.get(raw_transaction, field)
      end)
    end
  end

  def encode(packet) do
    packet_data = ExRLP.encode(packet)
    to_sign = <<1>> <> packet_data

    signature =
      EthClient.sign_raw_bytes(
        :erlang.binary_to_list(to_sign),
        "e90d75baafee04b3d9941bd8d76abe799b391aec596515dee11a9bd55f05709c"
      )
      |> :erlang.list_to_binary()

    hash = ExKeccak.hash_256(signature <> <<1>> <> packet_data)
    packet_header = hash <> signature <> <<1>>
    packet_header <> packet_data
  end
end

## packet = EthClient.Packet.new(4, ["127.0.0.1", 30335, 8000], ["127.0.0.1", 30303, 0], 1754192626)
## packet = EthClient.Packet.new(4, [<<127,0,0,1>>, 30335, 8000], [<<127,0,0,1>>, 30303, 0], 1754192626)
## signature = sign(packet-type || packet-data)
## hash = keccak256(signature || packet-type || packet-data)
## packet-header = hash || signature || packet-type
## 7F000001
