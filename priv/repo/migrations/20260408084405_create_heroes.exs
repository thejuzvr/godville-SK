defmodule GodvilleSk.Repo.Migrations.CreateHeroes do
  use Ecto.Migration

  def change do
    create table(:heroes) do
      add :name, :string
      add :race, :string
      add :class, :string
      add :level, :integer
      add :gold, :integer
      add :hp, :integer
      add :max_hp, :integer
      add :exp, :integer
      add :attributes, :map
      add :perks, {:array, :string}
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:heroes, [:user_id])
  end
end
