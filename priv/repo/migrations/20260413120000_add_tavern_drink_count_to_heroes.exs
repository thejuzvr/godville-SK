defmodule GodvilleSk.Repo.Migrations.AddTavernDrinkCountToHeroes do
  use Ecto.Migration

  def change do
    alter table(:heroes) do
      add :tavern_drink_count, :integer, default: 0
    end
  end
end
