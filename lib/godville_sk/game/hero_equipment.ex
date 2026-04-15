defmodule GodvilleSk.Game.HeroEquipment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :weapon, :string
    field :head, :string
    field :torso, :string
    field :legs, :string
    field :arms, :string
    field :boots, :string
    field :amulet, :string
    field :ring, :string
  end

  def changeset(equipment, attrs) do
    equipment
    |> cast(attrs, [:weapon, :head, :torso, :legs, :arms, :boots, :amulet, :ring])
    |> validate_required([])
  end

  def default do
    %__MODULE__{
      weapon: nil,
      head: nil,
      torso: nil,
      legs: nil,
      arms: nil,
      boots: nil,
      amulet: nil,
      ring: nil
    }
  end
end
