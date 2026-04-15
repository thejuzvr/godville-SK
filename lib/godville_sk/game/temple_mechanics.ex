defmodule GodvilleSk.Game.TempleMechanics do
  @moduledoc """
  Temple mechanics: construction, bonuses, residents, and enemies.
  """

  alias GodvilleSk.Game.HeroTemple

  @total_cost 5000

  def get_total_cost, do: @total_cost

  def calculate_progress(invested) do
    min(div(invested * 100, @total_cost), 100)
  end

  def donate(temple, amount) when amount > 0 do
    new_invested = (temple.total_invested || 0) + amount
    new_progress = calculate_progress(new_invested)
    new_donations = (temple.donations_count || 0) + 1

    new_temple =
      %{temple | total_invested: new_invested}
      |> Map.put(:construction_progress, new_progress)
      |> Map.put(:donations_count, new_donations)

    new_temple = update_residents(new_temple, new_progress)
    new_temple = update_enemies(new_temple, new_progress)

    {new_temple, new_progress}
  end

  def donate(temple, _), do: {temple, temple.construction_progress || 0}

  defp update_residents(temple, progress) do
    residents = HeroTemple.get_current_residents(temple)
    Map.put(temple, :residents, residents)
  end

  defp update_enemies(temple, progress) do
    enemies =
      cond do
        progress >= 100 ->
          ["Мерунес Дагон", "Молаг Бал", "Мефала", "Дагон", "Бал"]

        progress >= 75 ->
          ["Мерунес Дагон", "Молаг Бал", "Мефала"]

        progress >= 50 ->
          ["Мерунес Дагон", "Молаг Бал"]

        progress >= 25 ->
          ["Мерунес Дагон"]

        true ->
          []
      end

    Map.put(temple, :enemies, enemies)
  end

  def add_temple_event(temple, event_type, message) do
    event = %{
      type: event_type,
      message: message,
      timestamp: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }

    events = [event | temple.temple_events || []] |> Enum.take(20)
    Map.put(temple, :temple_events, events)
  end

  def maybe_spawn_enemy(temple, tick_count) do
    progress = temple.construction_progress || 0
    enemies = temple.enemies || []

    if progress >= 5 && length(enemies) > 0 && rem(tick_count, 100) == 0 && tick_count > 0 do
      encounter_count = (temple.enemy_encounters || 0) + 1

      new_temple =
        temple
        |> Map.put(:enemy_encounters, encounter_count)
        |> add_temple_event(:enemy_attack, "Враги атакуют храм!")

      {new_temple, true}
    else
      {temple, false}
    end
  end

  def apply_gold_bonus(temple, gold) do
    bonuses = HeroTemple.get_bonuses(temple)
    bonus_gold = div(gold * bonuses.gold_bonus, 100)
    gold + bonus_gold
  end

  def apply_xp_bonus(temple, xp) do
    bonuses = HeroTemple.get_bonuses(temple)
    bonus_xp = div(xp * bonuses.xp_bonus, 100)
    xp + bonus_xp
  end

  def apply_damage_bonus(temple, damage) do
    bonuses = HeroTemple.get_bonuses(temple)
    bonus_damage = div(damage * bonuses.damage_bonus, 100)
    damage + bonus_damage
  end

  def get_luck_bonus(temple) do
    bonuses = HeroTemple.get_bonuses(temple)
    bonuses.luck_bonus
  end

  def get_defense_bonus(temple) do
    bonuses = HeroTemple.get_bonuses(temple)
    bonuses.defense_bonus
  end
end
