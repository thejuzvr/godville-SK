defmodule GodvilleSk.Repo.Migrations.AddMetadataToHeroLogs do
  use Ecto.Migration

  def change do
    alter table(:hero_logs) do
      add :metadata, :map, default: %{}
    end
  end
end
