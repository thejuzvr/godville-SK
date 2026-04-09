defmodule GodvilleSk.Game.Hero do
  use Ecto.Schema
  import Ecto.Changeset

  schema "heroes" do
    field :attributes, :map
    field :class, :string
    field :exp, :integer
    field :gold, :integer
    field :hp, :integer
    field :level, :integer
    field :max_hp, :integer
    field :name, :string
    field :perks, {:array, :string}
    field :race, :string
    field :user_id, :id
    field :intervention_power, :integer, default: 100
    field :equipment, :map, default: %{}
    field :statistics, :map, default: %{}
    field :temple, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hero, attrs) do
    hero
    |> cast(attrs, [:name, :race, :class, :level, :gold, :hp, :max_hp, :exp, :attributes, :perks, :user_id, :intervention_power, :equipment, :statistics, :temple])
    |> validate_required([:name, :race, :class, :level, :gold, :hp, :max_hp, :exp, :perks, :user_id])
  end
end
