defmodule GodvilleSk.Hero.BodyParts do
  @moduledoc """
  Manages hero body parts and their effects on abilities.
  Implements Kenshi-style permanent injury system where limbs can be:
  - healthy: fully functional
  - injured: reduced functionality
  - lost: no functionality, permanent
  """

  @doc """
  Returns the default healthy body parts map.
  """
  def default do
    %{
      left_arm: :healthy,
      right_arm: :healthy,
      left_leg: :healthy,
      right_leg: :healthy,
      head: :healthy
    }
  end

  @doc """
  Checks if a specific body part is functional (not lost).
  """
  def functional?(body_parts, part) do
    case Map.get(body_parts, part, :healthy) do
      :healthy -> true
      :injured -> true
      :lost -> false
    end
  end

  @doc """
  Returns the functionality multiplier for a part (0.0 to 1.0).
  """
  def functionality_multiplier(body_parts, part) do
    case Map.get(body_parts, part, :healthy) do
      :healthy -> 1.0
      :injured -> 0.5
      :lost -> 0.0
    end
  end

  @doc """
  Calculates flee priority modifier based on leg injuries.
  Injured leg: +30% flee priority
  Lost leg: +60% flee priority
  Two injured legs: +80% flee priority
  Two lost legs: cannot flee (0.0 multiplier)
  """
  def flee_modifier(body_parts) do
    left_leg = functionality_multiplier(body_parts, :left_leg)
    right_leg = functionality_multiplier(body_parts, :right_leg)
    avg_leg_function = (left_leg + right_leg) / 2.0

    cond do
      left_leg == 0.0 and right_leg == 0.0 -> 0.0
      left_leg < 1.0 or right_leg < 1.0 -> 1.0 + (1.0 - avg_leg_function) * 0.8
      true -> 1.0
    end
  end

  @doc """
  Calculates fight priority modifier based on arm injuries.
  Lost arm: -30% fight priority (can't wield two-handed weapons)
  Injured arm: -15% fight priority
  """
  def fight_modifier(body_parts) do
    left_arm = functionality_multiplier(body_parts, :left_arm)
    right_arm = functionality_multiplier(body_parts, :right_arm)

    combat_efficiency = (left_arm + right_arm) / 2.0
    combat_efficiency
  end

  @doc """
  Calculates exploration penalty based on head injury.
  Lost eye (head): -20% exploration priority
  """
  def explore_modifier(body_parts) do
    head = functionality_multiplier(body_parts, :head)

    cond do
      head == 0.0 -> 0.3
      head < 1.0 -> 0.7
      true -> 1.0
    end
  end

  @doc """
  Checks if hero can use two-handed weapons (requires both arms).
  """
  def can_use_two_handed?(body_parts) do
    functional?(body_parts, :left_arm) and functional?(body_parts, :right_arm)
  end

  @doc """
  Checks if hero can flee (requires at least one functional leg).
  """
  def can_flee?(body_parts) do
    functional?(body_parts, :left_leg) or functional?(body_parts, :right_leg)
  end

  @doc """
  Checks if hero can fight (requires at least one functional arm).
  """
  def can_fight?(body_parts) do
    functional?(body_parts, :left_arm) or functional?(body_parts, :right_arm)
  end

  @doc """
  Returns a movement speed modifier based on leg injuries.
  """
  def movement_modifier(body_parts) do
    left_leg = functionality_multiplier(body_parts, :left_leg)
    right_leg = functionality_multiplier(body_parts, :right_leg)
    (left_leg + right_leg) / 2.0
  end

  @doc """
  Returns a combat damage modifier based on arm injuries.
  """
  def damage_modifier(body_parts) do
    left_arm = functionality_multiplier(body_parts, :left_arm)
    right_arm = functionality_multiplier(body_parts, :right_arm)
    (left_arm + right_arm) / 2.0
  end

  @doc """
  Returns a max HP penalty based on head injury.
  Lost head = instant death handled separately.
  Injured head = -20% max HP.
  """
  def max_hp_modifier(body_parts) do
    case Map.get(body_parts, :head, :healthy) do
      :healthy -> 1.0
      :injured -> 0.8
      :lost -> 0.0
    end
  end

  @doc """
  Calculates the total injury count (injured + lost parts).
  """
  def injury_count(body_parts) do
    body_parts
    |> Map.values()
    |> Enum.count(fn status -> status != :healthy end)
  end

  @doc """
  Determines if a random injury should occur during combat.
  Returns {:limb, atom} for a specific limb, or nil.
  """
  def random_injury(hero_level) do
    base_chance = 0.05 + hero_level * 0.005

    if :rand.uniform() < base_chance do
      limbs = [:left_arm, :right_arm, :left_leg, :right_leg, :head]
      limb = Enum.random(limbs)
      {:injury, limb}
    else
      nil
    end
  end

  @doc """
  Determines if a limb should be permanently lost.
  Only occurs on critical hits when HP is very low.
  """
  def random_limb_loss?(hero_level, hp_ratio) do
    if hp_ratio < 0.15 and :rand.uniform() < 0.15 + hero_level * 0.01 do
      {:loss, Enum.random([:left_arm, :right_arm, :left_leg, :right_leg])}
    else
      nil
    end
  end

  @doc """
  Applies an injury to a body part.
  """
  def apply_injury(body_parts, part) do
    current = Map.get(body_parts, part, :healthy)

    new_status =
      case current do
        :healthy -> :injured
        :injured -> :injured
        :lost -> :lost
      end

    Map.put(body_parts, part, new_status)
  end

  @doc """
  Applies limb loss to a body part.
  """
  def apply_loss(body_parts, part) do
    Map.put(body_parts, part, :lost)
  end

  @doc """
  Heals an injured body part (cannot heal lost parts).
  """
  def heal_injury(body_parts, part) do
    current = Map.get(body_parts, part, :healthy)

    new_status =
      case current do
        :healthy -> :healthy
        :injured -> :healthy
        :lost -> :lost
      end

    Map.put(body_parts, part, new_status)
  end

  @doc """
  Formats a description of the hero's physical state for the diary.
  """
  def describe_state(body_parts) do
    injuries =
      body_parts
      |> Enum.reject(fn {_, status} -> status == :healthy end)
      |> Enum.map(fn {part, status} ->
        case {part, status} do
          {:left_arm, :injured} -> "левая рука ранена"
          {:right_arm, :injured} -> "правая рука ранена"
          {:left_leg, :injured} -> "левая нога ранена"
          {:right_leg, :injured} -> "правая нога ранена"
          {:head, :injured} -> "голова ранена"
          {:left_arm, :lost} -> "левая рука ампутирована"
          {:right_arm, :lost} -> "правая рука ампутирована"
          {:left_leg, :lost} -> "левая нога ампутирована"
          {:right_leg, :lost} -> "правая нога ампутирована"
          {:head, :lost} -> "ГОЛОВЫ НЕТ"
        end
      end)

    if Enum.empty?(injuries) do
      "в отличном физическом состоянии"
    else
      injuries |> Enum.join(", ")
    end
  end
end
