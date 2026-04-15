defmodule GodvilleSk.TickProfile do
  @moduledoc """
  Tick profile configuration for different game speeds.
  Each profile defines intervals (in ms) for different hero statuses.
  """

  @profiles %{
    slow: %{
      idle: {10_000, 180_000},
      questing: {20_000, 60_000},
      combat: 3_000,
      combat_round: 3_000,
      resting: {8_000, 15_000},
      trading: {10_000, 25_000},
      sovngarde: {60_000, 120_000}
    },
    normal: %{
      idle: {5_000, 120_000},
      questing: {10_000, 30_000},
      combat: 2_300,
      combat_round: 2_300,
      resting: {3_000, 8_000},
      trading: {5_000, 15_000},
      sovngarde: {30_000, 60_000}
    },
    fast: %{
      idle: {1_000, 30_000},
      questing: {15_000, 60_000},
      combat: 1_000,
      combat_round: 1_000,
      resting: {1_000, 3_000},
      trading: {2_000, 5_000},
      sovngarde: {10_000, 20_000}
    },
    turbo: %{
      idle: {500, 5_000},
      questing: {5_000, 15_000},
      combat: 500,
      combat_round: 500,
      resting: {500, 1_500},
      trading: {1_000, 2_000},
      sovngarde: {5_000, 10_000}
    }
  }

  @default_profile :normal

  def profiles, do: Map.keys(@profiles)

  def default_profile, do: @default_profile

  def get_profile(name) when is_atom(name), do: Map.get(@profiles, name)

  def get_interval(profile, status) when is_atom(status) do
    case Map.get(@profiles, profile) do
      nil ->
        get_interval(@default_profile, status)

      profile_config ->
        case Map.get(profile_config, status) do
          nil -> 2_000
          {min, max} -> Enum.random(min..max)
          val when is_integer(val) -> val
        end
    end
  end
end
