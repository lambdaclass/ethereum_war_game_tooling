defmodule Frontend.Repo.Migrations.CreateContracts do
  use Ecto.Migration

  def change do
    create table(:contracts) do
      add :address, :string, null: false
      add :name, :string, null: false
      add :abi, :binary, null: false

      timestamps()
    end
  end
end
