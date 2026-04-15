defmodule GodvilleSk.Arena do
  @moduledoc """
  Arena schema for persisted arena data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "arenas" do
    field(:name, :string)
    field(:type, Ecto.Enum, values: [:duel, :team_3v3, :team_5v5])
    field(:status, Ecto.Enum, values: [:waiting, :active, :finished])
    field(:winner_team, :integer)
    field(:round, :integer, default: 0)

    has_many(:participants, GodvilleSk.ArenaParticipant)

    timestamps(type: :utc_datetime)
  end

  def changeset(arena, attrs) do
    arena
    |> cast(attrs, [:name, :type, :status, :winner_team, :round])
    |> validate_required([:type, :status])
  end
end
