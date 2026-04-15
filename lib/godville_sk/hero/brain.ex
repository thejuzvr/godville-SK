defmodule GodvilleSk.Hero.Brain do
  @moduledoc """
  Hero "Brain" - coordinates mood, memory, personality, goals, and fears.
  Makes decisions based on the hero's emotional state and past experiences.
  """

  alias GodvilleSk.GameContent
  alias GodvilleSk.Hero.BodyParts

  @max_memory 20
  @fear_decay_rate 0.1

  # --- Public API ---

  @doc """
  Main think function - processes the hero's brain state and returns decisions.
  """
  def think(state) do
    state
    |> update_mood()
    |> update_fatigue()
    |> decay_fears()
    |> maybe_remember_event()
  end

  @doc """
  Get contextual thought based on current state.
  """
  def contextual_thought(state) do
    base_thought = GameContent.context_thought(state.location, state.level)
    mood_modifier(state, base_thought)
  end

  @doc """
  Choose action based on brain state (for idle state decisions).
  """
  def choose_action(state) do
    _traits = state.traits
    mood = state.mood
    intensity = state.mood_intensity
    fears = state.fears

    cond do
      intensity > 70 && mood == :tired && state.fatigue > 30 ->
        {:rest, "Слишком устал, нужно отдохнуть."}

      intensity > 70 && mood == :scared ->
        {:cautious, "Страх гложет, нужно быть осторожным."}

      intensity > 70 && mood == :angry ->
        {:aggressive, "Я в ярости! Хочу сражаться!"}

      intensity > 70 && mood == :furious ->
        {:aggressive, "Я в бешенстве! Сражусь с чем угодно!"}

      intensity > 70 && mood == :hopeful ->
        {:optimistic, "Полон надежд, хочу приключений!"}

      state.hp < state.max_hp * 0.3 ->
        {:heal, "Здоровье низкое, нужно восстановиться."}

      Map.get(fears.locations, state.location, 0) > 3 ->
        {:leave, "Это место вызывает неприятные воспоминания."}

      intensity > 70 && mood == :excited ->
        weighted_decision_boosted(state, [:dungeon, :quest])

      state.overload_penalty < 0 ->
        {:sell, "Слишком тяжело! Нужно избавиться от лишнего перед боем."}

      has_better_equipment?(state) ->
        {:auto_equip, "Вижу в инвентаре что-то получше, нужно примерить."}

      true ->
        weighted_decision(state)
    end
  end

  defp has_better_equipment?(state) do
    Enum.any?(state.inventory, fn item_name ->
      item = GodvilleSk.Hero.Items.find_item([], item_name)
      item && item.type in [:weapon, :armor] && is_better?(item, state)
    end)
  end

  defp is_better?(%{type: :weapon, value: damage}, state) do
    current_weapon = state.equipment.weapon

    if current_weapon do
      current = GodvilleSk.Hero.Items.find_item([], current_weapon)
      current && damage > (current.value || 0)
    else
      true
    end
  end

  defp is_better?(%{type: :armor, slot: slot, value: ac}, state) do
    current_item = Map.get(state.equipment, slot)

    if current_item do
      current = GodvilleSk.Hero.Items.find_item([], current_item)
      current && ac > (current.value || 0)
    else
      true
    end
  end

  defp is_better?(_, _), do: false

  defp weighted_decision_boosted(state, boosted_actions) do
    weights = weighted_decision(state)

    boosted_weights =
      Enum.reduce(boosted_actions, weights, fn action, acc ->
        Map.update(acc, action, 10, &(&1 + 15))
      end)

    choose_weighted(boosted_weights)
  end

  @doc """
  Process combat outcome and update brain state accordingly.
  """
  def process_combat_outcome(state, :victory, enemy) do
    state
    |> update_mood_on_victory(enemy)
    |> add_memory(:victory, enemy)
    |> add_fear(:monsters, enemy, 0)
    |> update_goals_on_victory(enemy)
  end

  def process_combat_outcome(state, :defeat, enemy) do
    state
    |> update_mood_on_defeat(enemy)
    |> add_memory(:defeat, enemy)
    |> add_fear(:monsters, enemy.name, 1)
    |> add_fear(:conditions, :low_hp_combat, 1)
  end

  def process_combat_outcome(state, :fled, enemy) do
    state
    |> shift_mood_toward(:scared)
    |> add_memory(:fled, enemy)
    |> add_fear(:monsters, enemy.name, 1)
  end

  @doc """
  Process quest completion.
  """
  def process_quest_complete(state, quest) do
    state
    |> shift_mood_toward(:happy)
    |> add_memory(:quest_complete, quest)
    |> update_goals_on_quest(quest)
  end

  @doc """
  Check if hero should avoid certain action due to fears.
  """
  def should_avoid?(state, :monster, monster_name) do
    fear_level = Map.get(state.fears.monsters, monster_name, 0)
    personality = state.traits
    bravery_factor = 100 - personality.bravery
    fear_level * 5 > bravery_factor
  end

  def should_avoid?(state, :location, location) do
    fear_level = Map.get(state.fears.locations, location, 0)
    personality = state.traits
    curiosity_factor = 100 - personality.curiosity
    fear_level * 2 > curiosity_factor
  end

  def should_avoid?(_state, _type, _target), do: false

  @doc """
  Get combat strategy based on brain state.
  """
  def combat_strategy(state) do
    personality = state.traits
    mood = state.mood
    intensity = state.mood_intensity

    cond do
      intensity > 70 && mood == :angry -> :aggressive
      intensity > 70 && mood == :scared -> :defensive
      personality.bravery > 70 && intensity <= 70 -> :aggressive
      personality.risk_tolerance > 70 && intensity <= 70 -> :risky
      true -> :balanced
    end
  end

  # --- Mood System ---

  @mood_change_rate 8
  @intensity_threshold 70

  defp update_mood(state) do
    new_timer = state.mood_timer + 1
    mood = state.mood
    intensity = state.mood_intensity

    cond do
      state.hp < state.max_hp * 0.3 ->
        if mood != :scared do
          shift_mood_toward(state, :scared)
        else
          adjust_intensity(state, @mood_change_rate)
        end

      state.status == :sovngarde ->
        if mood != :sad do
          shift_mood_toward(state, :sad)
        else
          %{state | mood_timer: new_timer}
        end

      state.stamina < state.stamina_max * 0.2 ->
        if mood != :tired do
          shift_mood_toward(state, :tired)
        else
          adjust_intensity(state, @mood_change_rate)
        end

      new_timer > 40 && intensity > @intensity_threshold ->
        decay_intensity(state)

      true ->
        normalize_toward_neutral(state, new_timer)
    end
  end

  defp shift_mood_toward(state, target_mood) do
    current_intensity = state.mood_intensity
    current_mood = state.mood

    cond do
      current_intensity > @intensity_threshold ->
        change_mood(state, target_mood, @mood_change_rate)

      current_intensity > 50 ->
        build_secondary_mood(state, target_mood)

      current_mood == target_mood ->
        adjust_intensity(state, @mood_change_rate)

      true ->
        change_mood(state, target_mood, @mood_change_rate)
    end
  end

  defp build_secondary_mood(state, target_mood) do
    current_intensity = state.mood_intensity
    new_intensity = min(100, current_intensity + div(@mood_change_rate, 2))

    %{
      state
      | mood_intensity: new_intensity,
        secondary_mood: target_mood,
        secondary_intensity: min(30, new_intensity - 50),
        mood_timer: 0
    }
  end

  defp change_mood(state, new_mood, intensity_delta) do
    current_intensity = state.mood_intensity

    new_history =
      [
        %{
          mood: new_mood,
          intensity: min(100, current_intensity + intensity_delta),
          timestamp: now()
        }
        | state.mood_history
      ]
      |> Enum.take(10)

    new_intensity = min(100, current_intensity + intensity_delta)

    mixed_mood = determine_mixed_mood(state.mood, new_mood, state.secondary_mood, new_intensity)

    %{
      state
      | mood: mixed_mood,
        mood_intensity: new_intensity,
        secondary_mood: nil,
        secondary_intensity: 0,
        mood_history: new_history,
        mood_timer: 0
    }
  end

  defp determine_mixed_mood(_old_mood, new_mood, nil, _intensity), do: new_mood

  defp determine_mixed_mood(old_mood, new_mood, secondary, intensity) do
    cond do
      intensity > 70 && new_mood == :happy && secondary == :scared ->
        :hopeful

      intensity > 70 && new_mood == :angry && secondary == :scared ->
        :furious

      intensity > 70 && new_mood == :scared && secondary == :angry ->
        :furious

      intensity > 70 && new_mood == :happy && old_mood == :sad ->
        :hopeful

      true ->
        new_mood
    end
  end

  defp adjust_intensity(state, delta) do
    new_intensity = min(100, max(30, state.mood_intensity + delta))
    %{state | mood_intensity: new_intensity, mood_timer: 0}
  end

  defp decay_intensity(state) do
    new_intensity = max(30, state.mood_intensity - @mood_change_rate)
    %{state | mood_intensity: new_intensity, mood_timer: 0}
  end

  defp normalize_toward_neutral(state, new_timer) do
    intensity = state.mood_intensity

    cond do
      intensity > 75 ->
        new_intensity = max(50, intensity - 5)
        %{state | mood_intensity: new_intensity, mood_timer: new_timer}

      intensity < 25 && state.mood != :neutral ->
        change_mood(state, :neutral, -5)

      true ->
        Map.put(state, :mood_timer, new_timer)
    end
  end

  defp update_mood_on_victory(state, enemy) do
    personality = state.traits

    if enemy.level > state.level + 2 do
      if personality.risk_tolerance > 60 do
        shift_mood_toward(state, :excited)
      else
        shift_mood_toward(state, :happy)
      end
    else
      shift_mood_toward(state, :happy)
    end
  end

  defp update_mood_on_defeat(state, _enemy) do
    personality = state.traits

    if personality.bravery > 70 do
      shift_mood_toward(state, :angry)
    else
      shift_mood_toward(state, :sad)
    end
  end

  # --- Fatigue System ---

  defp update_fatigue(state) do
    cond do
      state.status in [:traveling, :questing] ->
        new_fatigue = min(100, state.fatigue + 1)
        %{state | fatigue: new_fatigue}

      state.status in [:resting, :camping, :tavern] ->
        new_fatigue = max(0, state.fatigue - 5)
        %{state | fatigue: new_fatigue}

      state.fatigue > 0 ->
        new_fatigue = max(0, state.fatigue - 1)
        %{state | fatigue: new_fatigue}

      true ->
        state
    end
  end

  # --- Memory System ---

  @doc """
  Add a memory entry to the hero's memory.
  """
  def add_memory(state, type, data) do
    memory_entry = %{
      type: type,
      data: data,
      timestamp: now()
    }

    new_memory = [memory_entry | state.memory] |> Enum.take(@max_memory)
    Map.put(state, :memory, new_memory)
  end

  defp maybe_remember_event(state) do
    case state.status do
      :idle ->
        if state.fatigue < 20 && state.mood == :neutral do
          recent_victory = Enum.find(state.memory, fn m -> m.type == :victory end)
          recent_defeat = Enum.find(state.memory, fn m -> m.type == :defeat end)

          cond do
            recent_victory && recent_defeat == nil ->
              if state.traits.risk_tolerance > 50 do
                %{state | recent_thought: :victory_boost}
              else
                state
              end

            recent_defeat && time_since(recent_defeat.timestamp) < 600 ->
              if state.traits.bravery < 50 do
                %{state | recent_thought: :cautious}
              else
                state
              end

            true ->
              state
          end
        else
          state
        end

      _ ->
        state
    end
  end

  # --- Fear System ---

  def add_fear(state, category, key, amount) do
    current = Map.get(state.fears, category, %{})
    new_value = Map.get(current, key, 0) + amount

    new_fears = Map.put(state.fears, category, Map.put(current, key, new_value))
    Map.put(state, :fears, new_fears)
  end

  defp decay_fears(state) do
    new_monsters =
      Map.new(state.fears.monsters, fn {k, v} ->
        {k, max(0, v - @fear_decay_rate)}
      end)

    new_locations =
      Map.new(state.fears.locations, fn {k, v} ->
        {k, max(0, v - @fear_decay_rate / 2)}
      end)

    new_conditions =
      Map.new(state.fears.conditions, fn {k, v} ->
        {k, max(0, v - @fear_decay_rate)}
      end)

    %{
      state
      | fears: %{
          monsters: new_monsters,
          locations: new_locations,
          conditions: new_conditions
        }
    }
  end

  # --- Goal System ---

  defp update_goals_on_victory(state, _enemy) do
    goals = state.goals

    new_goals =
      Enum.map(goals, fn goal ->
        case goal.type do
          :level ->
            Map.put(goal, :current, goal.current + 1)

          _ ->
            goal
        end
      end)

    Map.put(state, :goals, new_goals)
  end

  defp update_goals_on_quest(state, quest) do
    goals = state.goals

    new_goals =
      Enum.map(goals, fn goal ->
        case goal.type do
          :wealth ->
            current = goal.current + (quest.reward || 0)
            Map.put(goal, :current, current)

          _ ->
            goal
        end
      end)

    Map.put(state, :goals, new_goals)
  end

  # --- Decision Making ---

  defp weighted_decision(state) do
    personality = state.traits
    mood = state.mood
    goals = state.goals
    last_action = state.last_action
    is_city = GameContent.is_city?(state.location)
    body_parts = Map.get(state, :body_parts, BodyParts.default())

    weights = base_weights(is_city)

    weights = adjust_by_personality(weights, personality)
    weights = adjust_by_mood(weights, mood)
    weights = adjust_by_goals(weights, goals)
    weights = adjust_by_last_action(weights, last_action)
    weights = adjust_by_body_parts(weights, body_parts)

    choose_weighted(weights)
  end

  defp adjust_by_last_action(weights, nil), do: weights

  defp adjust_by_last_action(weights, last_action) do
    Map.update(weights, last_action, 0, &floor(&1 * 0.5))
  end

  defp base_weights(is_city) do
    if is_city do
      %{tavern: 20, quest: 30, trade: 10, walk: 20, leave: 20}
    else
      %{travel: 30, camp: 15, quest: 25, dungeon: 15, explore: 15}
    end
  end

  defp adjust_by_personality(weights, personality) do
    weights
    |> Map.update(
      :tavern,
      personality.sociability / 100 * 30,
      &(&1 + personality.sociability / 100 * 10)
    )
    |> Map.update(
      :dungeon,
      personality.curiosity / 100 * 25,
      &(&1 + personality.curiosity / 100 * 10)
    )
    |> Map.update(
      :quest,
      personality.stubbornness / 100 * 20,
      &(&1 + personality.stubbornness / 100 * 5)
    )
  end

  defp adjust_by_mood(weights, mood) do
    case mood do
      :happy ->
        weights
        |> Map.update(:dungeon, 20, &(&1 + 15))
        |> Map.update(:quest, 25, &(&1 + 10))

      :excited ->
        weights
        |> Map.update(:dungeon, 20, &(&1 + 20))
        |> Map.update(:quest, 25, &(&1 + 15))

      :scared ->
        weights
        |> Map.update(:travel, 30, &(&1 + 20))
        |> Map.update(:camp, 15, &(&1 + 15))
        |> Map.update(:dungeon, 15, &(&1 - 10))

      :sad ->
        weights
        |> Map.update(:tavern, 20, &(&1 + 15))
        |> Map.update(:rest, 10, &(&1 + 10))

      :angry ->
        weights
        |> Map.update(:quest, 25, &(&1 + 15))
        |> Map.update(:dungeon, 15, &(&1 + 10))

      :tired ->
        weights
        |> Map.update(:rest, 10, &(&1 + 30))
        |> Map.update(:tavern, 20, &(&1 + 10))
        |> Map.update(:quest, 25, &(&1 - 15))

      :hopeful ->
        weights
        |> Map.update(:dungeon, 20, &(&1 + 15))
        |> Map.update(:quest, 25, &(&1 + 10))
        |> Map.update(:explore, 15, &(&1 + 10))

      :furious ->
        weights
        |> Map.update(:quest, 25, &(&1 + 20))
        |> Map.update(:dungeon, 15, &(&1 + 15))
        |> Map.update(:travel, 30, &(&1 - 10))

      _ ->
        weights
    end
  end

  defp adjust_by_goals(weights, goals) do
    Enum.reduce(goals, weights, fn goal, acc ->
      case goal.type do
        :wealth ->
          Map.update(acc, :quest, 25, &(&1 + 10))

        :level ->
          Map.update(acc, :dungeon, 15, &(&1 + 10))

        _ ->
          acc
      end
    end)
  end

  defp adjust_by_body_parts(weights, body_parts) do
    flee_modifier = BodyParts.flee_modifier(body_parts)
    fight_modifier = BodyParts.fight_modifier(body_parts)
    explore_modifier = BodyParts.explore_modifier(body_parts)
    can_flee = BodyParts.can_flee?(body_parts)
    can_fight = BodyParts.can_fight?(body_parts)

    weights
    |> Map.update(:flee, 30, &round(&1 * flee_modifier))
    |> Map.update(:fight, 25, &round(&1 * fight_modifier))
    |> Map.update(:explore, 15, &round(&1 * explore_modifier))
    |> then(fn w ->
      if can_flee, do: w, else: Map.put(w, :flee, 0)
    end)
    |> then(fn w ->
      if can_fight, do: w, else: Map.put(w, :fight, 0)
    end)
  end

  defp choose_weighted(weights) do
    total = weights |> Map.values() |> Enum.sum()

    random = :rand.uniform() * total

    Enum.reduce_while(weights, {random, nil}, fn {action, weight}, {acc, _} ->
      new_acc = acc - weight

      if new_acc <= 0 do
        {:halt, action}
      else
        {:cont, {new_acc, action}}
      end
    end)
  end

  # --- Memory Recall System ---

  @memory_cooldown 20
  @min_memory_age 10
  @trigger_location 0.20
  @trigger_monster 0.15
  @trigger_idle 0.05

  @doc """
  Attempt to recall a memory based on current context.
  Returns {state, memory_string} or {state, nil}.
  """
  def recall_memory(state) do
    state = %{state | memory_recall_cooldown: max(0, state.memory_recall_cooldown - 1)}

    if state.memory_recall_cooldown > 0 || Enum.empty?(state.memory) do
      {state, nil}
    else
      trigger_type = determine_trigger(state)
      do_recall(state, trigger_type)
    end
  end

  defp determine_trigger(state) do
    cond do
      state.status in [:traveling] -> :location
      state.status in [:combat_initiative, :combat_round] -> :monster
      state.status == :idle -> :idle
      true -> nil
    end
  end

  defp do_recall(state, nil), do: {state, nil}

  defp do_recall(state, trigger_type) do
    chance =
      case trigger_type do
        :location -> @trigger_location
        :monster -> @trigger_monster
        :idle -> @trigger_idle
      end

    if :rand.uniform() > chance do
      {state, nil}
    else
      memory = select_memory(state, trigger_type)

      if memory do
        message = format_memory(memory, state)
        new_state = %{state | memory_recall_cooldown: @memory_cooldown}
        {new_state, message}
      else
        {state, nil}
      end
    end
  end

  defp select_memory(state, :location) do
    location_memories =
      Enum.filter(state.memory, fn m ->
        m.type == :location_visited && time_since(m.timestamp) > @min_memory_age * 2
      end)

    if Enum.empty?(location_memories) do
      nil
    else
      if :rand.uniform() < 0.3 do
        Enum.random(location_memories)
      else
        nil
      end
    end
  end

  defp select_memory(state, :monster) do
    combat_memories =
      Enum.filter(state.memory, fn m ->
        m.type in [:victory, :defeat, :fled] && time_since(m.timestamp) > @min_memory_age * 2
      end)

    if Enum.empty?(combat_memories) do
      nil
    else
      if :rand.uniform() < 0.5 do
        Enum.random(combat_memories)
      else
        nil
      end
    end
  end

  defp select_memory(state, :idle) do
    eligible =
      Enum.filter(state.memory, fn m ->
        time_since(m.timestamp) > @min_memory_age * 3
      end)

    if Enum.empty?(eligible) do
      nil
    else
      if :rand.uniform() < 0.4 do
        Enum.random(eligible)
      else
        nil
      end
    end
  end

  defp format_memory(memory, state) do
    mood = state.mood
    intensity = state.mood_intensity

    case memory.type do
      :victory ->
        enemy_name = get_in(memory.data, [:name]) || "монстр"

        positive_templates(intensity, mood, enemy_name)
        |> Enum.random()

      :defeat ->
        enemy_name = get_in(memory.data, [:name]) || "монстр"

        negative_templates(intensity, mood, enemy_name)
        |> Enum.random()

      :fled ->
        enemy_name = get_in(memory.data, [:name]) || "монстр"

        negative_templates(intensity, mood, enemy_name)
        |> Enum.random()

      :location_visited ->
        location_name = memory.data || "это место"

        neutral_templates(location_name)
        |> Enum.random()

      :quest_complete ->
        quest_name = get_in(memory.data, [:name]) || "задание"

        positive_templates(intensity, mood, quest_name)
        |> Enum.random()

      _ ->
        neutral_templates("прошлое")
        |> Enum.random()
    end
  end

  defp positive_templates(_intensity, mood, subject) do
    base = [
      "Вспоминаю свою победу над #{subject} - было дело!",
      "Эх, хорошее было время, когда я победил #{subject}...",
      "Помню, как справился с #{subject} - неплохо справился!",
      "Был у меня опыт победы над #{subject} - удачный день выдался.",
      "Всплыло в памяти - победил как-то #{subject}. Хорошие воспоминания."
    ]

    case mood do
      :happy -> Enum.map(base, &"Радостно: #{&1}")
      :excited -> Enum.map(base, &"С восторгом: #{&1}")
      :hopeful -> Enum.map(base, &"С надеждой: #{&1}")
      :sad -> Enum.map(base, &"Грустно: #{&1}")
      _ -> base
    end
  end

  defp negative_templates(_intensity, mood, subject) do
    base = [
      "#{subject}? Я его помню... он меня однажды победил.",
      "Этот монстр напоминает мне о позорном поражении...",
      "Вспоминаю #{subject} - тогда мне не повезло.",
      "Было дело - #{subject} оказался сильнее. Печально.",
      "Нехорошие воспоминания - когда-то #{subject} меня одолел."
    ]

    case mood do
      :scared -> Enum.map(base, &"Страх: #{&1}")
      :sad -> Enum.map(base, &"Грустно: #{&1}")
      :angry -> Enum.map(base, &"Злобно: #{&1}")
      :furious -> Enum.map(base, &"Яростно: #{&1}")
      _ -> base
    end
  end

  defp neutral_templates(subject) do
    [
      "Я уже был здесь раньше, кажется...",
      "Интересно, что я здесь забыл в прошлый раз?",
      "Дежавю... #{subject} - знакомое чувство.",
      "Смутное воспоминание - я где-то это видел.",
      "Что-то familiar - в памяти всплывает #{subject}."
    ]
  end

  # --- Contextual Thoughts ---

  defp mood_modifier(state, base_thought) do
    case state.mood do
      :happy ->
        prepend_thought(base_thought, "Радостно думаю: ")

      :excited ->
        prepend_thought(base_thought, "В восторге от мысли: ")

      :scared ->
        prepend_thought(base_thought, "С опаской думаю: ")

      :sad ->
        prepend_thought(base_thought, "Грустно размышляю: ")

      :angry ->
        prepend_thought(base_thought, "Злобно думаю: ")

      :tired ->
        prepend_thought(base_thought, "Устало думаю: ")

      :hopeful ->
        prepend_thought(base_thought, "С надеждой думаю: ")

      :furious ->
        prepend_thought(base_thought, "Яростно думаю: ")

      _ ->
        base_thought
    end
  end

  defp prepend_thought(thought, prefix) do
    "#{prefix}#{thought}"
  end

  # --- Helpers ---

  defp now do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end

  defp time_since(timestamp) do
    now()
    |> NaiveDateTime.diff(timestamp, :second)
  end
end
