defmodule GodvilleSk.Repo.Migrations.AddExtraFieldsToHeroes do
  use Ecto.Migration

  def change do
    alter table(:heroes) do
      add :equipment, :map, default: %{}
      add :statistics, :map, default: %{}
      add :temple, :map, default: %{}
    end
  end
end
