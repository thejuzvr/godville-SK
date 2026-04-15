defmodule GodvilleSk.Game.ContentEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @kinds ~w(location monster item quest thought random_event sovngarde_task sovngarde_thought)

  schema "game_content_entries" do
    field :kind, :string
    field :key, :string
    field :payload, :map, default: %{}
    field :active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:kind, :key, :payload, :active])
    |> validate_required([:kind, :key, :payload, :active])
    |> validate_inclusion(:kind, @kinds)
    |> unique_constraint([:kind, :key], name: :game_content_entries_kind_key_index)
  end
end
