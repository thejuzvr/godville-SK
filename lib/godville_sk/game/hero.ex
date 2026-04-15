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
    field :stamina, :integer, default: 100
    field :stamina_max, :integer, default: 100
    field :luck_modifier, :integer, default: 0
    field :status, :string, default: "idle"
    field :inventory, {:array, :string}, default: []
    field :location, :string, default: "Балмора"
    field :quest_progress, :integer, default: 0
    field :tavern_drink_count, :integer, default: 0
    field :turn, :string, default: "hero"
    field :respawn_at, :naive_datetime
    embeds_one :equipment, GodvilleSk.Game.HeroEquipment, on_replace: :update
    embeds_one :statistics, GodvilleSk.Game.HeroStatistics, on_replace: :update
    embeds_one :temple, GodvilleSk.Game.HeroTemple, on_replace: :update

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hero, attrs) do
    hero
    |> cast(attrs, [
      :name,
      :race,
      :class,
      :level,
      :gold,
      :hp,
      :max_hp,
      :exp,
      :attributes,
      :perks,
      :user_id,
      :intervention_power,
      :stamina,
      :stamina_max,
      :luck_modifier,
      :status,
      :inventory,
      :location,
      :quest_progress,
      :tavern_drink_count,
      :turn,
      :respawn_at
    ])
    |> validate_required([
      :name,
      :race,
      :class,
      :level,
      :gold,
      :hp,
      :max_hp,
      :exp,
      :perks,
      :user_id,
      :stamina,
      :stamina_max,
      :luck_modifier,
      :status,
      :inventory,
      :location,
      :quest_progress,
      :tavern_drink_count,
      :turn
    ])
    |> cast_embed(:equipment)
    |> cast_embed(:statistics)
    |> cast_embed(:temple)
  end
end
