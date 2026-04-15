defmodule GodvilleSk.Repo.Migrations.CreateArenas do
  use Ecto.Migration

  def change do
    create table(:arenas) do
      add(:name, :string)
      add(:type, :string)
      add(:status, :string, default: "waiting")
      add(:winner_team, :integer)
      add(:round, :integer, default: 0)

      timestamps(type: :utc_datetime)
    end

    create table(:arena_participants) do
      add(:arena_id, references(:arenas, on_delete: :delete_all))
      add(:character_id, references(:heroes, on_delete: :delete_all))
      add(:team, :integer)

      timestamps(type: :utc_datetime)
    end

    create(index(:arena_participants, [:arena_id]))
    create(index(:arena_participants, [:character_id]))
  end
end
