defmodule GodvilleSk.ArenaParticipant do
  @moduledoc """
  Arena participant schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "arena_participants" do
    belongs_to(:arena, GodvilleSk.Arena)
    belongs_to(:character, GodvilleSk.Game.Hero)

    field(:team, :integer)

    timestamps(type: :utc_datetime)
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:arena_id, :character_id, :team])
    |> validate_required([:arena_id, :character_id, :team])
  end
end
