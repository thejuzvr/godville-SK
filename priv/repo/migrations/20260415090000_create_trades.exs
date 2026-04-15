defmodule GodvilleSk.Repo.Migrations.CreateTrades do
  use Ecto.Migration

  def change do
    create table(:trades) do
      add(:type, :string)
      add(:price, :integer)
      add(:status, :string, default: "active")
      add(:item_name, :string)
      add(:seller_id, references(:users, on_delete: :delete_all))
      add(:character_id, references(:heroes, on_delete: :delete_all))

      timestamps(type: :utc_datetime)
    end

    create(index(:trades, [:seller_id]))
    create(index(:trades, [:status]))
    create(index(:trades, [:type]))
    create(index(:trades, [:character_id]))
  end
end
