defmodule GodvilleSk.Repo.Migrations.CreateGameContentEntries do
  use Ecto.Migration

  def change do
    create table(:game_content_entries) do
      add :kind, :string, null: false
      add :key, :string, null: false
      add :payload, :map, null: false, default: %{}
      add :active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:game_content_entries, [:kind])
    create unique_index(:game_content_entries, [:kind, :key])
  end
end
