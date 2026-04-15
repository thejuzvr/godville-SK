defmodule GodvilleSk.Repo.Migrations.AddGameTimeToHeroLogs do
  use Ecto.Migration

  def change do
    alter table(:hero_logs) do
      add :game_time, :map
    end
  end
end
