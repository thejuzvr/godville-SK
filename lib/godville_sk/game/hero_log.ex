defmodule GodvilleSk.Game.HeroLog do
  use Ecto.Schema
  import Ecto.Changeset
  alias GodvilleSk.Game.Hero

  schema "hero_logs" do
    field :message, :string
    belongs_to :hero, Hero

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(hero_log, attrs) do
    hero_log
    |> cast(attrs, [:message, :hero_id])
    |> validate_required([:message, :hero_id])
  end
end
