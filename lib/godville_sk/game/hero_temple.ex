defmodule GodvilleSk.Game.HeroTemple do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :construction_progress, :integer, default: 0
    field :total_invested, :integer, default: 0
    field :temple_level, :integer, default: 0
    field :donations_count, :integer, default: 0
    field :residents, {:array, :string}, default: []
    field :enemies, {:array, :string}, default: []
    field :defense_level, :integer, default: 1
    field :enemy_encounters, :integer, default: 0
    field :temple_events, {:array, :map}, default: []
  end

  def changeset(temple, attrs) do
    temple
    |> cast(attrs, [
      :construction_progress,
      :total_invested,
      :temple_level,
      :donations_count,
      :residents,
      :enemies,
      :defense_level,
      :enemy_encounters,
      :temple_events
    ])
    |> validate_required([])
  end

  def default do
    %__MODULE__{
      construction_progress: 0,
      total_invested: 0,
      temple_level: 0,
      donations_count: 0,
      residents: [],
      enemies: [],
      defense_level: 1,
      enemy_encounters: 0,
      temple_events: []
    }
  end

  def get_bonuses(temple) do
    progress = temple.construction_progress || 0

    base = %{
      gold_bonus: 0,
      luck_bonus: 0,
      xp_bonus: 0,
      damage_bonus: 0,
      defense_bonus: 0
    }

    cond do
      progress >= 100 ->
        Map.merge(base, %{
          gold_bonus: 25,
          luck_bonus: 5,
          xp_bonus: 5,
          damage_bonus: 5,
          defense_bonus: 10
        })

      progress >= 75 ->
        Map.merge(base, %{
          gold_bonus: 20,
          luck_bonus: 3,
          xp_bonus: 5,
          damage_bonus: 5,
          defense_bonus: 8
        })

      progress >= 50 ->
        Map.merge(base, %{
          gold_bonus: 15,
          luck_bonus: 2,
          xp_bonus: 3,
          damage_bonus: 3,
          defense_bonus: 5
        })

      progress >= 25 ->
        Map.merge(base, %{
          gold_bonus: 10,
          luck_bonus: 1,
          xp_bonus: 2,
          damage_bonus: 2,
          defense_bonus: 3
        })

      progress >= 5 ->
        Map.merge(base, %{
          gold_bonus: 5,
          luck_bonus: 0,
          xp_bonus: 0,
          damage_bonus: 0,
          defense_bonus: 0
        })

      true ->
        base
    end
  end

  def get_current_residents(temple) do
    progress = temple.construction_progress || 0

    residents = []

    residents =
      if progress >= 100 do
        ["Пророк" | residents]
      else
        residents
      end

    residents =
      if progress >= 75 do
        ["Призванный даэдра" | residents]
      else
        residents
      end

    residents =
      if progress >= 50 do
        ["Дух предков" | residents]
      else
        residents
      end

    residents =
      if progress >= 25 do
        ["Отрекшийся" | residents]
      else
        residents
      end

    residents
  end
end
