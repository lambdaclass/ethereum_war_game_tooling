defmodule Frontend.Chain.Config do
  use Frontend.Schema
  import Ecto.Changeset

  schema "chain_configs" do
    field :chain_id, :integer
    field :rpc_host, :string
    field :user_address, :string
    field :user_private_key, :string

    timestamps()
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(attrs, [:user_address, :user_private_key, :chain_id, :rpc_host])
    |> validate_required([:user_address, :user_private_key, :chain_id, :rpc_host])
  end
end
