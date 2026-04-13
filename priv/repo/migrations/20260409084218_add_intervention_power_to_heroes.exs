defmodule GodvilleSk.Repo.Migrations.AddInterventionPowerToHeroes do
  use Ecto.Migration

  def change do
    alter table(:heroes) do
      add :intervention_power, :integer, default: 100, null: false
    end
  end
end
