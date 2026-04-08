defmodule GodvilleSk.Repo.Migrations.CreateHeroesAndLogs do
  use Ecto.Migration

  def change do
    alter table(:heroes) do
      add :status, :string, default: "idle"
    end

    create unique_index(:heroes, [:name])

    create table(:hero_logs) do
      add :hero_id, references(:heroes, on_delete: :delete_all), null: false
      add :message, :text, null: false
      timestamps(updated_at: false)
    end

    create index(:hero_logs, [:hero_id])
  end
end
