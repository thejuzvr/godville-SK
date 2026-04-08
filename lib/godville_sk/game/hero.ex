defmodule GodvilleSk.Game.Hero do
  use Ecto.Schema
  import Ecto.Changeset
  alias GodvilleSk.Accounts.User
  alias GodvilleSk.Game.HeroLog

  schema "heroes" do
    field :name, :string
    field :race, :string
    field :class, :string
    field :level, :integer, default: 1
    field :gold, :integer, default: 0
    field :hp, :integer, default: 100
    field :max_hp, :integer, default: 100
    field :exp, :integer, default: 0
    field :attributes, :map, default: %{}
    field :perks, {:array, :string}, default: []
    field :status, :string, default: "idle"

    belongs_to :user, User
    has_many :logs, HeroLog

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hero, attrs) do
    hero
    |> cast(attrs, [:name, :race, :class, :level, :gold, :hp, :max_hp, :exp, :attributes, :perks, :status, :user_id])
    |> validate_required([:name, :race, :class, :user_id])
    |> unique_constraint(:name)
  end
end
