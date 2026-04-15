defmodule GodvilleSk.Game.HeroStatistics do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :total_steals, :integer, default: 0
    field :total_wins, :integer, default: 0
    field :total_quests, :integer, default: 0
    field :total_deaths, :integer, default: 0
    field :total_gold_earned, :integer, default: 0
    field :total_distance_traveled, :integer, default: 0
    field :total_items_collected, :integer, default: 0
    field :total_monsters_killed, :integer, default: 0
    field :total_bosses_killed, :integer, default: 0
    field :critical_hits, :integer, default: 0
    field :successful_escapes, :integer, default: 0
    field :dungeons_cleared, :integer, default: 0
    field :cities_visited, {:array, :string}, default: []
    field :longest_combat_streak, :integer, default: 0
    field :current_combat_streak, :integer, default: 0
    field :highest_level, :integer, default: 1
    field :total_xp_earned, :integer, default: 0
    field :highest_gold, :integer, default: 0
    field :unlocked_achievements, {:array, :string}, default: []
  end

  def changeset(statistics, attrs) do
    statistics
    |> cast(attrs, [
      :total_steals,
      :total_wins,
      :total_quests,
      :total_deaths,
      :total_gold_earned,
      :total_distance_traveled,
      :total_items_collected,
      :total_monsters_killed,
      :total_bosses_killed,
      :critical_hits,
      :successful_escapes,
      :dungeons_cleared,
      :cities_visited,
      :longest_combat_streak,
      :current_combat_streak,
      :highest_level,
      :total_xp_earned,
      :highest_gold,
      :unlocked_achievements
    ])
    |> validate_required([])
  end

  def default do
    %__MODULE__{
      total_steals: 0,
      total_wins: 0,
      total_quests: 0,
      total_deaths: 0,
      total_gold_earned: 0,
      total_distance_traveled: 0,
      total_items_collected: 0,
      total_monsters_killed: 0,
      total_bosses_killed: 0,
      critical_hits: 0,
      successful_escapes: 0,
      dungeons_cleared: 0,
      cities_visited: [],
      longest_combat_streak: 0,
      current_combat_streak: 0,
      highest_level: 1,
      total_xp_earned: 0,
      highest_gold: 0,
      unlocked_achievements: []
    }
  end
end
