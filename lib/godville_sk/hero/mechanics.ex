defmodule GodvilleSk.Hero.Mechanics do
  @moduledoc """
  Core game mechanics helpers: dice rolls, attribute modifiers, combat calculations.
  """

  @doc """
  Calculates the attribute modifier (TES-style: (value - 50) / 10, integer division).
  """
  def modifier(value), do: div(value - 50, 10)

  @doc """
  Performs a d20 roll check with attribute modifier, luck bonus, and optional bonus modifier.

  Returns `{:success, roll, total, log_message}` or `{:fail, roll, total, log_message}`.
  Natural 1 and 20 are critical.
  """
  def roll_check(attr_mod, luck_value, dc, bonus_mod \\ 0, overload_mod \\ 0) do
    roll = :rand.uniform(20)
    luck_bonus = div(luck_value, 10)
    total = roll + attr_mod + luck_bonus + bonus_mod + overload_mod

    {result, log} =
      case roll do
        1 ->
          {:fail, "Натуральная 1! Критический провал"}

        20 ->
          {:success, "Натуральная 20! Критический успех"}

        _ ->
          mod_str = if bonus_mod != 0, do: " + Эфф #{bonus_mod}", else: ""

          if total >= dc do
            {:success,
             "Бросок #{roll} + Мод #{attr_mod} + Удача #{luck_bonus}#{mod_str} = #{total} (DC #{dc})"}
          else
            {:fail,
             "Бросок #{roll} + Мод #{attr_mod} + Удача #{luck_bonus}#{mod_str} = #{total} (DC #{dc})"}
          end
      end

    {result, roll, total, log}
  end

  @doc """
  Calculates hero's attack against a target.
  Returns `{is_hit, damage, total, roll, log_message}`.
  """
  def perform_attack(state, target) do
    attr_mod = modifier(state.strength) + state.level
    luck_value = state.luck
    dc = Map.get(target, :ac, 10)
    overload = state.overload_penalty || 0

    case roll_check(attr_mod, luck_value, dc, state.luck_modifier, overload) do
      {:success, 20, total, log} ->
        damage = state.level * 4 + modifier(state.strength) * 2
        {true, damage, total, 20, "#{log}: Сокрушительный удар на #{damage} урона!"}

      {:success, roll, total, log} ->
        damage = max(1, 5 + modifier(state.strength))
        {true, damage, total, roll, "#{log}: Попадание на #{damage} урона!"}

      {:fail, 1, total, log} ->
        {false, 0, total, 1, "#{log}: Споткнулся."}

      {:fail, roll, total, log} ->
        {false, 0, total, roll, "#{log}: Промах!"}
    end
  end

  @doc """
  Calculates enemy's attack against hero.
  """
  def perform_enemy_attack(enemy, hero) do
    attr_mod = Map.get(enemy, :level, 1)
    luck_value = 50
    dc = hero.ac
    enemy_damage = Map.get(enemy, :damage, 1)

    case roll_check(attr_mod, luck_value, dc) do
      {:success, 20, total, log} ->
        damage = enemy_damage * 2
        {true, damage, total, 20, "Враг #{log}: Критический удар на #{damage} урона!"}

      {:success, roll, total, log} ->
        {true, enemy_damage, total, roll, "Враг #{log}: Попадает на #{enemy_damage} урона!"}

      {:fail, 1, total, log} ->
        {false, 0, total, 1, "Враг #{log}: Критический промах!"}

      {:fail, roll, total, log} ->
        {false, 0, total, roll, "Враг #{log}: Промах!"}
    end
  end
end
