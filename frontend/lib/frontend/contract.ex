defmodule Frontend.Contract do
  use Frontend.Schema
  alias Frontend.Repo
  import Ecto.Changeset
  import Ecto.Query

  schema "contracts" do
    field :abi, :binary
    field :address, :string
    field :name, :string

    timestamps()
  end

  def changeset(contract, attrs) do
    contract
    |> cast(attrs, [:address, :name, :abi])
    |> validate_required([:address, :name, :abi])
    |> unique_constraint(:name)
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def get_latest do
    from(c in __MODULE__, order_by: [desc: :inserted_at], limit: 1)
    |> Repo.one()
  end

  def by_id(id), do: Repo.get!(__MODULE__, id)
  def by_name(name), do: Repo.get_by!(__MODULE__, name: name)
  def all, do: Repo.all(__MODULE__)
end
