defmodule Frontend.Repo.Migrations.CreateChainConfigs do
  use Ecto.Migration

  def change do
    create table(:chain_configs) do
      add :user_address, :string
      add :user_private_key, :string
      add :chain_id, :integer
      add :rpc_host, :string

      timestamps()
    end
  end
end
