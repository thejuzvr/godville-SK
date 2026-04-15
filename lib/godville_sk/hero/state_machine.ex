defmodule GodvilleSk.Hero.StateMachine do
  @moduledoc """
  Hero state machine: status transitions and state handlers.
  All functions are pure and return the updated state.
  """

  alias GodvilleSk.GameContent
  alias GodvilleSk.Hero.{Mechanics, Combat, Items, Brain}
  alias GodvilleSk.{Repo, WorldClock}
  alias GodvilleSk.Game.{LogMetadata, TempleMechanics, Achievements}

  @max_log_size 60

  # --- Public API ---

  @doc """
  Processes one tick for the given hero state, applying all status-specific logic.
  """
  def tick(state) do
    tick_count = (state.tick_counter || 0) + 1

    state = update_inventory_weight(state)
    state = Brain.think(state)
    state = handle_status(state.status, state)

    {state, memory_msg} = Brain.recall_memory(state)

    state =
      if memory_msg,
        do: add_to_log(state, "Воспоминание: #{memory_msg}", %{type: "memory"}),
        else: state

    state =
      state
      |> maybe_rest()
      |> regenerate_intervention_power()
      |> regenerate_stamina()

    state = maybe_process_temple_enemy(state, tick_count)

    {state, _} = Achievements.check_achievements(state)

    Map.put(state, :tick_counter, tick_count)
  end

  defp maybe_process_temple_enemy(state, tick_count) do
    temple = state.temple
    {new_temple, enemy_spawned} = TempleMechanics.maybe_spawn_enemy(temple, tick_count)

    state = Map.put(state, :temple, new_temple)

    if enemy_spawned do
      enemy = Enum.random(new_temple.enemies)
      add_to_log(state, "ВНИМАНИЕ! #{enemy} атакует храм! Защита на страже!")
    else
      state
    end
  end

  defp update_inventory_weight(state) do
    weight = Items.calculate_inventory_weight(state.inventory)
    {is_overloaded, penalty} = Items.check_overload(weight)

    state
    |> Map.put(:inventory_weight, weight)
    |> Map.put(:overload_penalty, penalty)
  end

  @doc """
  Adds a message to the hero's log with optional metadata.
  Public function that can be called from other modules.
  """
  def add_to_log(state, msg, metadata \\ %{}) do
    context = if state.status == :sovngarde, do: :sovngarde, else: :normal

    case LogMetadata.validate(metadata, context) do
      {:ok, normalized_metadata} ->
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        entry = %{
          id: nil,
          message: msg,
          metadata: normalized_metadata,
          inserted_at: now,
          game_time: WorldClock.game_time_at(now)
        }

        _ = persist_log(state, entry)

        new_log = [entry | state.log] |> Enum.take(@max_log_size)
        Map.put(state, :log, new_log)

      {:error, reason} ->
        require Logger
        Logger.error("[Hero] Invalid metadata for log entry: #{inspect(reason)}. Message: #{msg}")
        state
    end
  end

  # --- Status handlers ---

  defp handle_status(_any_status, %{xp: xp, level: level} = state) when xp >= level * 100 do
    attributes = [
      :strength,
      :intelligence,
      :willpower,
      :agility,
      :speed,
      :endurance,
      :personality,
      :luck
    ]

    attr = Enum.random(attributes)
    current_val = Map.get(state, attr)

    state
    |> Map.put(:status, :leveling_up)
    |> Map.put(:level, level + 1)
    |> Map.put(:xp, 0)
    |> Map.put(:max_hp, state.max_hp + 10)
    |> Map.put(:hp, state.max_hp + 10)
    |> Map.put(attr, (current_val || 50) + 1)
    |> tap(fn _ ->
      require Logger
      Logger.info("[Hero] '#{state.name}' reached LEVEL #{level + 1}! #{attr} increased.")
    end)
    |> add_to_log("УРОВЕНЬ ПОВЫШЕН! Теперь вы уровень #{level + 1}! #{attr} +1.")
  end

  defp handle_status(:leveling_up, state) do
    Map.put(state, :status, :idle)
  end

  defp handle_status(
         :sovngarde,
         %{respawn_at: respawn_at, hp: hp, max_hp: max_hp, stamina: st, stamina_max: st_max} =
           state
       ) do
    now = DateTime.utc_now()

    if respawn_at && DateTime.compare(now, respawn_at) in [:gt, :eq] do
      state
      |> Map.put(:status, :idle)
      |> Map.put(:respawn_at, nil)
      |> Map.put(:location, GameContent.get_location())
      |> add_to_log("Шор милостиво открыл портал. Срок в Совнгарде окончен. Возвращаюсь!")
    else
      state =
        case Enum.random([:task, :thought, :heal]) do
          :task ->
            task = Enum.random(GameContent.sovngarde_tasks())

            add_to_log(state, "Совнгард: [Задание] #{task.title}. #{task.description}", %{
              type: "sovngarde_task",
              task_id: task.id,
              title: task.title
            })

          :thought ->
            thought = Enum.random(GameContent.sovngarde_thoughts())

            add_to_log(state, "Совнгард: [Мысль] #{thought}", %{
              type: "sovngarde_thought"
            })

          :heal ->
            state
        end

      state
      |> Map.put(:hp, min(hp + 10, max_hp))
      |> Map.put(:stamina, min(st + 15, st_max))
    end
  end

  defp handle_status(:resting, %{hp: hp, max_hp: max} = state) do
    if hp >= max do
      state
      |> Map.put(:status, :idle)
      |> add_to_log("Отдохнул и восстановил силы. Пора в путь!")
    else
      Map.put(state, :hp, min(hp + 5, max))
    end
  end

  defp handle_status(:camping, %{hp: hp, max_hp: max, stamina: st, stamina_max: st_max} = state) do
    new_hp = min(hp + 15, max)
    new_stamina = min(st + 20, st_max)

    event = Enum.random(GameContent.night_events())

    case event.effect do
      :ambush ->
        monster = GameContent.get_random_monster(max(1, state.level - 1))

        state
        |> Map.put(:hp, new_hp)
        |> Map.put(:stamina, new_stamina)
        |> Map.put(:status, :combat_initiative)
        |> Map.put(:target, monster)
        |> add_to_log("Ночью в лагерь кто-то напал! #{event.msg} Встретил: #{monster.name}!")

      :rest ->
        state
        |> Map.put(:hp, new_hp + 10)
        |> Map.put(:stamina, new_stamina + 10)
        |> Map.put(:status, :idle)
        |> add_to_log(
          "Хорошая ночь у костра. #{event.msg} Восстановил силы. (+15 HP, +20 Stamina)"
        )

      _ ->
        state
        |> Map.put(:hp, new_hp)
        |> Map.put(:stamina, new_stamina)
        |> Map.put(:status, :idle)
        |> add_to_log("Ночь прошла спокойно. #{event.msg} (+15 HP, +20 Stamina)")
    end
  end

  defp handle_status(:traveling, state) do
    new_location = GameContent.get_location()

    state_with_location = Map.put(state, :location, new_location)

    city_arrival_updates =
      if GameContent.is_city?(new_location) do
        visited = [new_location | state.visited_cities] |> Enum.take(10)

        %{
          city_phase: :arrived,
          visited_cities: visited,
          tavern_visited: false,
          walked_in_city: false,
          quest_checked: false
        }
      else
        %{}
      end

    case Enum.random([:safe, :monster, :event, :bandits]) do
      :safe ->
        state_with_location
        |> Map.merge(city_arrival_updates)
        |> Brain.add_memory(:location_visited, new_location)
        |> Map.put(:status, :idle)
        |> add_to_log("Путешествие прошло без приключений. Добрался до #{new_location}.")

      :monster ->
        monster = GameContent.get_random_monster(state.level)

        state_with_location
        |> Map.merge(city_arrival_updates)
        |> Brain.add_memory(:location_visited, new_location)
        |> Map.put(:status, :combat_initiative)
        |> Map.put(:target, monster)
        |> add_to_log("В пути наткнулся на врага: #{monster.name}! Локация: #{new_location}")

      :event ->
        event = Enum.random(GameContent.random_events())
        state = add_to_log(state_with_location, "В пути: #{event.msg}")
        state = Map.put(state, :status, :idle)
        state = Brain.add_memory(state, :location_visited, new_location)
        state = Map.merge(state, city_arrival_updates)

        case event.effect do
          :heal -> Map.put(state, :hp, min(state.hp + 10, state.max_hp))
          _ -> state
        end

      :bandits ->
        monster =
          Enum.random([
            %{
              id: "bandit",
              name: "Бандит",
              hp: 45,
              max_hp: 45,
              damage: 6,
              xp: 40,
              level: 3,
              ac: 13
            },
            %{
              id: "bandit_outlaw",
              name: "Бандит-дезертир",
              hp: 55,
              max_hp: 55,
              damage: 7,
              xp: 50,
              level: 4,
              ac: 13
            }
          ])

        state_with_location
        |> Map.merge(city_arrival_updates)
        |> Brain.add_memory(:location_visited, new_location)
        |> Map.put(:status, :combat_initiative)
        |> Map.put(:target, monster)
        |> add_to_log(
          "На дороге напали бандиты! Встретил: #{monster.name}! Локация: #{new_location}"
        )
    end
  end

  defp handle_status(:fleeing, state) do
    state
    |> Map.put(:status, :idle)
    |> Map.put(:target, nil)
    |> add_to_log("Скрылся от опасности. Перевожу дух.")
  end

  defp handle_status(:trading, state) do
    state
    |> Map.put(:status, :idle)
    |> add_to_log("Торговля окончена. Карманы звенят.")
  end

  defp handle_status(:tavern, %{tavern_drink_count: count} = state) do
    new_count = count + 1

    {outcome_state, outcome_msg} =
      if new_count < 3 do
        case Enum.random([:rumor, :cheerful, :rest, :rumor]) do
          :rumor ->
            rumor = Enum.random(GameContent.tavern_rumors())
            {state, "Таверна: #{rumor}"}

          :cheerful ->
            {state, "Таверна: Выпил за компанию. На душе весело!"}

          :rest ->
            new_hp = min(state.hp + 15, state.max_hp)
            {Map.put(state, :hp, new_hp), "Таверна: Выспались в углу. (+15 HP)"}

          _ ->
            rumor = Enum.random(GameContent.tavern_rumors())
            {state, "Таверна: #{rumor}"}
        end
      else
        case Enum.random([:drunk_happy, :drunk_fight, :drunk_sleep, :rumor]) do
          :drunk_happy ->
            new_hp = min(state.hp + 10, state.max_hp)
            {Map.put(state, :hp, new_hp), "Таверна: Напился, но весело! Приятная ночь. (+10 HP)"}

          :drunk_fight ->
            monster = GameContent.get_random_monster(state.level)

            {state
             |> Map.put(:status, :combat_initiative)
             |> Map.put(:target, monster),
             "Таверна: Напился и лезу в драку! Встретил: #{monster.name}!"}

          :drunk_sleep ->
            new_hp = min(state.hp + 25, state.max_hp)

            {Map.put(state, :hp, new_hp),
             "Таверна: Напился и отключился. Проснулся с головной болью. (+25 HP)"}

          :rumor ->
            rumor = Enum.random(GameContent.tavern_rumors())
            {state, "Таверна (пьяный): #{rumor}"}
        end
      end

    outcome_state
    |> Map.put(:tavern_drink_count, new_count)
    |> Map.put(:status, :idle)
    |> add_to_log(outcome_msg)
  end

  defp handle_status(:questing, state) do
    if is_nil(state.target) do
      require Logger

      Logger.error("[Hero] '#{state.name}' normalized from :questing to :idle (target missing)")

      state
      |> Map.put(:status, :idle)
      |> Map.put(:quest_progress, 0)
    else
      quest_type = Map.get(state.target, :type, :bounty)

      case quest_type do
        :dungeon -> handle_dungeon_quest(state)
        :bounty -> handle_bounty_quest(state)
        :delivery -> handle_delivery_quest(state)
        :gathering -> handle_gathering_quest(state)
        _ -> handle_default_quest(state)
      end
    end
  end

  defp handle_dungeon_quest(state) do
    progress = state.quest_progress + 1
    total = state.target.steps

    if progress >= total do
      complete_quest(state, "Исследование подземелья '#{state.target.name}' завершено!")
    else
      if progress == total - 1 do
        monster = GameContent.get_random_monster(state.level + 2)

        state
        |> Map.put(:quest_progress, progress)
        |> Map.put(:status, :combat_initiative)
        |> Map.put(:target, monster)
        |> add_to_log("БОСС! #{monster.name} преграждает путь к выходу!", %{type: "quest_event"})
      else
        event = GameContent.get_random_dungeon_room_event()

        case event.effect do
          :combat ->
            monster = GameContent.get_random_monster(state.level)

            state
            |> Map.put(:quest_progress, progress)
            |> Map.put(:status, :combat_initiative)
            |> Map.put(:target, monster)
            |> add_to_log("Исследую комнату... #{event.msg} #{monster.name}!", %{
              type: "quest_event"
            })

          :loot ->
            loot = GameContent.get_random_loot(state.level)

            state
            |> Map.put(:quest_progress, progress)
            |> add_to_log("Исследую комнату... #{event.msg} #{loot}", %{type: "quest_event"})

          :damage ->
            damage = Enum.random(10..20)

            state
            |> Map.put(:quest_progress, progress)
            |> Map.put(:hp, max(1, state.hp - damage))
            |> add_to_log("Исследую комнату... #{event.msg} #{damage} HP", %{type: "quest_event"})

          :heal ->
            heal = Enum.random(15..25)

            state
            |> Map.put(:quest_progress, progress)
            |> Map.put(:hp, min(state.hp + heal, state.max_hp))
            |> add_to_log("Исследую комнату... #{event.msg} #{heal} HP", %{type: "quest_event"})

          :bonus ->
            base_bonus = Enum.random(20..50)
            bonus_gold = TempleMechanics.apply_gold_bonus(state.temple, base_bonus)

            state
            |> Map.put(:quest_progress, progress)
            |> Map.put(:gold, state.gold + bonus_gold)
            |> add_to_log("Исследую комнату... #{event.msg} #{bonus_gold} золотых!", %{
              type: "quest_event"
            })

          _ ->
            state
            |> Map.put(:quest_progress, progress)
        end
      end
    end
  end

  defp handle_bounty_quest(state) do
    progress = state.quest_progress + 1
    total = state.target.steps

    if progress >= total do
      complete_quest(state, "Охота на '#{state.target.name}' завершена!")
    else
      case Enum.random([:searching, :found, :combat]) do
        :searching ->
          state
          |> Map.put(:quest_progress, progress)

        :found ->
          monster = GameContent.get_random_monster(state.level)

          state
          |> Map.put(:quest_progress, progress)
          |> Map.put(:status, :combat_initiative)
          |> Map.put(:target, monster)
          |> add_to_log("Заметил цель: #{monster.name}!")

        :combat ->
          monster = GameContent.get_random_monster(state.level)

          state
          |> Map.put(:quest_progress, progress)
          |> Map.put(:status, :combat_initiative)
          |> Map.put(:target, monster)
          |> add_to_log("Атакую цель! #{monster.name}!")
      end
    end
  end

  defp handle_delivery_quest(state) do
    progress = state.quest_progress + 1
    total = state.target.steps

    if progress >= total do
      complete_quest(state, "Доставка '#{state.target.name}' выполнена!")
    else
      case Enum.random([:traveling, :safe, :event, :bandits]) do
        :traveling ->
          state
          |> Map.put(:quest_progress, progress)

        :safe ->
          state
          |> Map.put(:quest_progress, progress)

        :event ->
          event = Enum.random(GameContent.random_events())

          state
          |> Map.put(:quest_progress, progress)
          |> add_to_log("В пути: #{event.msg}", %{type: "quest_event"})

        :bandits ->
          monster =
            Enum.random([
              %{
                id: "bandit",
                name: "Бандит",
                hp: 45,
                max_hp: 45,
                damage: 6,
                xp: 40,
                level: 3,
                ac: 13
              },
              %{
                id: "bandit_outlaw",
                name: "Бандит-дезертир",
                hp: 55,
                max_hp: 55,
                damage: 7,
                xp: 50,
                level: 4,
                ac: 13
              }
            ])

          state
          |> Map.put(:quest_progress, progress)
          |> Map.put(:status, :combat_initiative)
          |> Map.put(:target, monster)
          |> add_to_log("На дороге напали разбойники! Встретил: #{monster.name}!")
      end
    end
  end

  defp handle_gathering_quest(state) do
    progress = state.quest_progress + 1
    total = state.target.steps

    if progress >= total do
      complete_quest(state, "Сбор ресурсов '#{state.target.name}' завершён!")
    else
      case Enum.random([:searching, :found, :gather]) do
        :searching ->
          state
          |> Map.put(:quest_progress, progress)

        :found ->
          event = Enum.random(GameContent.random_events())

          state
          |> Map.put(:quest_progress, progress)
          |> add_to_log("Нашел следы! #{event.msg}", %{type: "quest_event"})

        :gather ->
          item = GameContent.get_random_loot(state.level)

          state
          |> Map.put(:quest_progress, progress)
          |> add_to_log("Собрал: #{item}", %{type: "quest_event"})
      end
    end
  end

  defp handle_default_quest(state) do
    progress = state.quest_progress + 1
    total = state.target.steps

    if progress >= total do
      complete_quest(state, "Квест '#{state.target.name}' выполнен!")
    else
      state
      |> Map.put(:quest_progress, progress)
    end
  end

  defp complete_quest(state, message) do
    base_xp = 10
    new_xp = state.xp + TempleMechanics.apply_xp_bonus(state.temple, base_xp)
    new_statistics = %{state.statistics | total_quests: state.statistics.total_quests + 1}
    bonus_gold = if Map.get(state.target, :type) == :dungeon, do: 20, else: 0
    base_gold = state.target.reward + bonus_gold
    total_gold = TempleMechanics.apply_gold_bonus(state.temple, base_gold)

    completion_thought = quest_completion_thought(state.target, total_gold)

    state = Brain.process_quest_complete(state, state.target)

    state
    |> Map.put(:status, :idle)
    |> Map.put(:target, nil)
    |> Map.put(:quest_progress, 0)
    |> Map.put(:gold, state.gold + total_gold)
    |> Map.put(:xp, new_xp)
    |> Map.put(:statistics, new_statistics)
    |> Map.put(:last_action, nil)
    |> add_to_log(
      "#{message} Получено #{total_gold} золотых, #{base_xp} XP. #{completion_thought}"
    )
  end

  defp quest_completion_thought(quest, gold) do
    quest_type = Map.get(quest, :type, :unknown)

    thoughts =
      case quest_type do
        :bounty ->
          [
            "Кости обнищали, благо я заработал #{gold} золота.",
            "Наконец-то! Убил того монстра - теперь хоть посплю.",
            "Задание выполнено. Боги довольны, желудок пуст.",
            "С этими бандитами покончено. Жаль, конечно, что награда такая маленькая...",
            "Наконец-то могу отдохнуть. Голова гудит от боя.",
            "Монстры побеждены, золото в кармане - жизнь налаживается!"
          ]

        :delivery ->
          [
            "Доставил посылку! Теперь хочу пойти и напиться.",
            "Сдал груз, получил золото - неплохо сработал.",
            "Наконец-то добрался! Ноги гудят, но оно того стоило.",
            "Получатель доволен - я тоже. Золото - хорошая мотивация.",
            "Посылка доставлена целой. Почти. Как и мои ноги.",
            "Фух, донес! Теперь можно и отдохнуть в таверне."
          ]

        :gathering ->
          [
            "Собрал все, что нужно. Золото получено - можно идти дальше.",
            "Набрал трав (или руды). Теперь главное - не забыть, зачем.",
            "Вот и собрал. Сумка тяжелая, карман - тоже. Хорошо.",
            "Находки неплохие. Золото приятно греет карман.",
            "Собрал, что требовалось. Теперь главное - донести до склада.",
            "Пока собирал, заметил странную корову. Испугался, но задание важнее."
          ]

        :dungeon ->
          [
            "Выбрался из подземелья! Сокровища - мои!",
            "Подземелье исследовано. Мертвецы остались мертвыми.",
            "Наконец-то на поверхности! Свежий воздух - лучше золота.",
            "Тьма побеждена! Сокровища найдены. Можно жить.",
            "Из подземелья вышел живым - уже успех. А золото - бонус.",
            "Страшные монстры позади. Сокровища - в рюкзаке. Отлично!"
          ]

        _ ->
          [
            "Задание выполнено. Золото получено.",
            "Наконец-то справился! Теперь можно отдохнуть.",
            "Дело сделано. Герой доволен, боги - тоже.",
            "Успех! Золото в кармане, голова на плечах."
          ]
      end

    Enum.random(thoughts)
  end

  defp handle_status(:combat_initiative, state) do
    if is_nil(state.target) do
      require Logger

      Logger.error(
        "[Hero] '#{state.name}' normalized from :combat_initiative to :idle (target missing)"
      )

      state
      |> Map.put(:status, :idle)
      |> Map.put(:target, nil)
    else
      Combat.do_combat_initiative(state)
    end
  end

  defp handle_status(:combat_round, state) do
    cond do
      is_nil(state.target) ->
        require Logger

        Logger.error(
          "[Hero] '#{state.name}' normalized from :combat_round to :idle (target missing)"
        )

        state
        |> Map.put(:status, :idle)
        |> Map.put(:target, nil)

      state.hp < state.max_hp * 0.15 && state.stamina >= 25 ->
        attempt_emergency_flee(state)

      true ->
        Combat.do_combat_round(state)
    end
  end

  defp handle_status(:idle, %{inventory: inv, inventory_capacity: cap} = state)
       when length(inv) >= cap do
    num_items = length(inv)
    base_gold = Enum.reduce(1..num_items, 0, fn _, acc -> acc + Enum.random(5..15) end)
    earned_gold = TempleMechanics.apply_gold_bonus(state.temple, base_gold)

    state
    |> Map.put(:status, :trading)
    |> Map.put(:inventory, [])
    |> Map.put(:gold, state.gold + earned_gold)
    |> add_to_log("Инвентарь полон! Продал #{num_items} вещей за #{earned_gold} золотых.")
  end

  defp handle_status(:idle, state) do
    if GameContent.is_city?(state.location) do
      handle_idle_city(state)
    else
      handle_idle_wilderness(state)
    end
  end

  defp handle_idle_city(state) do
    if better_item = find_better_item(state) do
      state
      |> equip_item_from_inventory(better_item)
      |> add_to_log("Вижу в инвентаре что-то получше, нужно примерить.")
    else
      handle_idle_city_phase(state)
    end
  end

  defp handle_idle_city_phase(state) do
    was_in_city = state.location in state.visited_cities

    case {state.city_phase, was_in_city} do
      {:arrived, false} ->
        state
        |> Map.put(:status, :tavern)
        |> Map.put(:city_phase, :tavern_visited)
        |> Map.put(:tavern_visited, true)
        |> Map.put(:tavern_drink_count, 0)
        |> Map.put(:last_action, :tavern)
        |> add_to_log("Зашел в таверну. По традиции - сначала сюда.")

      {:arrived, true} ->
        state
        |> Map.put(:city_phase, :walked)
        |> Map.put(:walked_in_city, true)
        |> Map.put(:last_action, :walk)
        |> add_to_log("Вернулся в #{state.location}. Осмотрелся - знакомые места.")

      {:tavern_visited, _} ->
        if state.walked_in_city do
          if :rand.uniform() < 0.3 do
            leave_city(%{state | city_phase: :arrived})
          else
            maybe_trade_before_quest(%{state | city_phase: :quest_checked})
          end
        else
          if :rand.uniform() < 0.3 do
            leave_city(%{state | city_phase: :arrived})
          else
            state
            |> Map.put(:city_phase, :walked)
            |> Map.put(:walked_in_city, true)
            |> Map.put(:last_action, :walk)
            |> add_to_log("Прогулялся по городу. Осмотрелся.")
          end
        end

      {:walked, _} ->
        if length(state.inventory) >= trunc(state.inventory_capacity * 0.8) do
          state
          |> Map.put(:status, :trading)
          |> Map.put(:city_phase, :quest_checked)
          |> add_to_log("Карманы полны. Нужно продать лишнее.")
        else
          if :rand.uniform() < 0.3 do
            leave_city(%{state | city_phase: :arrived})
          else
            state
            |> Map.put(:city_phase, :quest_checked)
            |> try_take_quest()
          end
        end

      {:quest_checked, _} ->
        state
        |> Map.put(:city_phase, :arrived)
        |> leave_city()

      _ ->
        state
        |> Map.put(:city_phase, :arrived)
        |> leave_city()
    end
  end

  defp maybe_trade_before_quest(state) do
    if length(state.inventory) >= trunc(state.inventory_capacity * 0.8) do
      state
      |> Map.put(:status, :trading)
      |> add_to_log("Карманы полны. Нужно продать лишнее.")
    else
      state
      |> try_take_quest()
    end
  end

  defp try_take_quest(state) do
    if :rand.uniform() < 0.7 do
      start_quest(state)
    else
      state
      |> Map.put(:last_action, :quest_skip)
      |> add_to_log("Нет настроения искать приключения. Может, в другой раз.")
    end
  end

  defp leave_city(state) do
    new_location = GameContent.get_location()
    visited = [new_location | state.visited_cities] |> Enum.take(10)

    state
    |> Map.put(:location, new_location)
    |> Map.put(:visited_cities, visited)
    |> Map.put(:tavern_drink_count, 0)
    |> Map.put(:city_phase, :arrived)
    |> Map.put(:tavern_visited, false)
    |> Map.put(:walked_in_city, false)
    |> Map.put(:quest_checked, false)
    |> Map.put(:status, :traveling)
    |> Brain.add_memory(:location_visited, new_location)
    |> add_to_log("Дела в городе сделаны. Отправляюсь в #{new_location}.")
  end

  defp find_better_item(state) do
    Enum.find(state.inventory, fn item_name ->
      item = Items.find_item([], item_name)
      item && item.type in [:weapon, :armor] && is_better?(item, state)
    end)
  end

  defp is_better?(%{type: :weapon, value: damage}, state) do
    current_weapon = state.equipment.weapon

    if current_weapon do
      current = Items.find_item([], current_weapon)
      current && damage > (current.value || 0)
    else
      true
    end
  end

  defp is_better?(%{type: :armor, slot: slot, value: ac}, state) do
    current_item = Map.get(state.equipment, slot)

    if current_item do
      current = Items.find_item([], current_item)
      current && ac > (current.value || 0)
    else
      true
    end
  end

  defp is_better?(_, _), do: false

  defp equip_item_from_inventory(state, item_name) do
    item = Items.find_item([], item_name)

    if item do
      new_inventory = List.delete(state.inventory, item_name)
      new_equipment = Map.put(state.equipment, item.slot, item_name)

      state
      |> Map.put(:inventory, new_inventory)
      |> Map.put(:equipment, new_equipment)
      |> Map.put(:last_action, :auto_equip)
    else
      state
    end
  end

  defp handle_idle_wilderness(state) do
    cond do
      state.target != nil and Map.has_key?(state.target, :steps) ->
        state
        |> Map.put(:status, :questing)
        |> Map.put(:last_action, :quest)
        |> add_to_log(
          "Продолжаю задание: #{state.target.name} (#{state.quest_progress}/#{state.target.steps})"
        )

      true ->
        case Brain.choose_action(state) do
          {:leave, reason} ->
            new_location = GameContent.get_location()
            state = Brain.add_fear(state, :locations, state.location, 1)

            state
            |> Map.put(:location, new_location)
            |> Brain.add_memory(:location_visited, new_location)
            |> Map.put(:last_action, :travel)
            |> add_to_log("#{reason} Покинул локацию. Новое место: #{new_location}.")

          {:rest, reason} ->
            state
            |> Map.put(:status, :camping)
            |> Map.put(:last_action, :camp)
            |> add_to_log("#{reason} Решил отдохнуть.")

          {:cautious, _} ->
            new_location = GameContent.get_location()

            state
            |> Map.put(:location, new_location)
            |> Brain.add_memory(:location_visited, new_location)
            |> Map.put(:last_action, :travel)
            |> add_to_log("Действую осторожно. Перемещаюсь в #{new_location}.")

          {:heal, _} ->
            state
            |> Map.put(:status, :resting)
            |> Map.put(:last_action, :rest)
            |> add_to_log("Здоровье подорвано. Нужно отдохнуть и восстановиться.")

          {:aggressive, _reason} ->
            new_location = GameContent.get_location()
            monster = GameContent.get_random_monster(state.level)

            state
            |> Map.put(:location, new_location)
            |> Brain.add_memory(:location_visited, new_location)
            |> Map.put(:status, :combat_initiative)
            |> Map.put(:target, monster)
            |> Map.put(:last_action, :fight)
            |> add_to_log("Ярость кипит! Бросаюсь на врага: #{monster.name}!")

          {:optimistic, _reason} ->
            state = handle_wilderness_action(state, :quest)
            Map.put(state, :last_action, :quest)

          {:sell, _reason} ->
            if state.inventory != [] do
              num_items = length(state.inventory)
              base_gold = Enum.reduce(1..num_items, 0, fn _, acc -> acc + Enum.random(5..15) end)

              earned_gold =
                GodvilleSk.Game.TempleMechanics.apply_gold_bonus(state.temple, base_gold)

              state
              |> Map.put(:inventory, [])
              |> Map.put(:gold, state.gold + earned_gold)
              |> Map.put(:last_action, :trade)
              |> add_to_log(
                "Избавился от лишнего груза. Продал #{num_items} вещей за #{earned_gold} золотых."
              )
            else
              state
              |> Map.put(:last_action, :travel)
              |> handle_wilderness_action(:travel)
            end

          {:auto_equip, _reason} ->
            if better = find_better_item(state) do
              state
              |> equip_item_from_inventory(better)
              |> Map.put(:last_action, :auto_equip)
              |> add_to_log("Вижу в инвентаре что-то получше, нужно примерить.")
            else
              state
              |> Map.put(:last_action, :travel)
              |> handle_wilderness_action(:travel)
            end

          :flee ->
            new_location = GameContent.get_location()
            state = Brain.add_fear(state, :locations, state.location, 2)

            state
            |> Map.put(:location, new_location)
            |> Brain.add_memory(:location_visited, new_location)
            |> Map.put(:last_action, :flee)
            |> add_to_log("Спасаюсь бегством! Убежал в #{new_location}.")

          :fight ->
            new_location = GameContent.get_location()
            monster = GameContent.get_random_monster(state.level)

            state
            |> Map.put(:location, new_location)
            |> Brain.add_memory(:location_visited, new_location)
            |> Map.put(:status, :combat_initiative)
            |> Map.put(:target, monster)
            |> Map.put(:last_action, :fight)
            |> add_to_log("Ищу противника! Нашёл: #{monster.name} в #{new_location}.")

          :rest ->
            state
            |> Map.put(:status, :camping)
            |> Map.put(:last_action, :camp)
            |> add_to_log("Нужно передохнуть. Разбил лагерь.")

          action
          when action in [:travel, :tavern, :quest, :trade, :walk, :dungeon, :camp, :explore] ->
            state = handle_wilderness_action(state, action)
            Map.put(state, :last_action, action)
        end
    end
  end

  defp handle_wilderness_action(state, :travel) do
    new_location = GameContent.get_location()

    if Brain.should_avoid?(state, :location, new_location) do
      state
      |> Map.put(:location, new_location)
      |> Brain.add_memory(:location_visited, new_location)
      |> add_to_log("Тяжелые воспоминания... Но иду дальше. Прибыл: #{new_location}.")
    else
      encounter_type = weighted_encounter(state)

      case encounter_type do
        :safe ->
          state
          |> Map.put(:location, new_location)
          |> Brain.add_memory(:location_visited, new_location)
          |> add_to_log("Путешествую... Добрался до #{new_location}.")

        :monster ->
          monster = GameContent.get_random_monster(state.level)

          if Brain.should_avoid?(state, :monster, monster.name) do
            new_location2 = GameContent.get_location()

            state
            |> Map.put(:location, new_location2)
            |> Brain.add_memory(:location_visited, new_location2)
            |> add_to_log(
              "Вспомнил что-то нехорошее о #{monster.name}. Лучше уйти. Новый путь: #{new_location2}."
            )
          else
            state
            |> Map.put(:location, new_location)
            |> Brain.add_memory(:location_visited, new_location)
            |> Map.put(:status, :combat_initiative)
            |> Map.put(:target, monster)
            |> add_to_log(
              "Во время путешествия заметил противника: #{monster.name}! Локация: #{new_location}"
            )
          end

        :event ->
          event = Enum.random(GameContent.random_events())
          state = add_to_log(state, "Путешествуя: #{event.msg}")
          state = Map.put(state, :location, new_location)
          state = Brain.add_memory(state, :location_visited, new_location)

          case event.effect do
            :heal -> Map.put(state, :hp, min(state.hp + 10, state.max_hp))
            _ -> state
          end

        :bandits ->
          monster = random_bandit()

          if Brain.should_avoid?(state, :monster, monster.name) do
            new_location2 = GameContent.get_location()

            state
            |> Map.put(:location, new_location2)
            |> Brain.add_memory(:location_visited, new_location2)
            |> add_to_log(
              "Вспомнил былые неудачи с бандитами. Лучше пройти мимо. Новый путь: #{new_location2}."
            )
          else
            state
            |> Map.put(:location, new_location)
            |> Brain.add_memory(:location_visited, new_location)
            |> Map.put(:status, :combat_initiative)
            |> Map.put(:target, monster)
            |> add_to_log(
              "На дороге напали бандиты! Встретил: #{monster.name}! Локация: #{new_location}"
            )
          end
      end
    end
  end

  defp handle_wilderness_action(state, :explore) do
    new_location = GameContent.get_location()
    encounter_roll = :rand.uniform(100)

    cond do
      encounter_roll <= 30 ->
        monster = GameContent.get_random_monster(state.level)

        state
        |> Map.put(:location, new_location)
        |> Brain.add_memory(:location_visited, new_location)
        |> Map.put(:status, :combat_initiative)
        |> Map.put(:target, monster)
        |> add_to_log(
          "Исследуя окрестности, наткнулся на противника: #{monster.name}! Локация: #{new_location}"
        )

      encounter_roll <= 60 ->
        event = Enum.random(GameContent.random_events())
        found_gold = Enum.random(3..15)

        state
        |> Map.put(:location, new_location)
        |> Brain.add_memory(:location_visited, new_location)
        |> Map.put(:gold, state.gold + found_gold)
        |> add_to_log("Исследую... #{event.msg} Нашёл #{found_gold} золотых в #{new_location}.")

      true ->
        state
        |> Map.put(:location, new_location)
        |> Brain.add_memory(:location_visited, new_location)
        |> add_to_log("Исследуя местность, добрался до #{new_location}. Ничего интересного.")
    end
  end

  defp handle_wilderness_action(state, :camp) do
    state
    |> Map.put(:status, :camping)
    |> add_to_log("Разбил лагерь на ночь. Отдых восстановит силы.")
  end

  defp handle_wilderness_action(state, :dungeon) do
    dungeon = Enum.random(GameContent.dungeons())

    if Brain.should_avoid?(state, :location, dungeon.name) do
      state
      |> add_to_log(
        "Подземелье #{dungeon.name} вызывает плохие воспоминания. Лучше поискать что-то другое."
      )
      |> handle_wilderness_action(:travel)
    else
      quest = %{
        id: dungeon.id,
        name: "Исследовать: #{dungeon.name}",
        steps: dungeon.steps,
        reward: dungeon.difficulty * 50,
        type: :dungeon
      }

      state
      |> Map.put(:status, :questing)
      |> Map.put(:target, quest)
      |> Map.put(:quest_progress, 0)
      |> add_to_log("Нашел вход в подземелье: #{dungeon.name}! Начинаю исследование...")
    end
  end

  defp handle_wilderness_action(state, :quest) do
    start_quest(state)
  end

  defp handle_wilderness_action(state, action) do
    require Logger
    Logger.warning("[Hero] Unknown wilderness action: #{inspect(action)}. Defaulting to travel.")
    handle_wilderness_action(state, :travel)
  end

  defp weighted_encounter(state) do
    traits = state.traits
    base_weights = [safe: 40, monster: 25, event: 20, bandits: 15]

    adjusted =
      if traits.risk_tolerance > 70 do
        Keyword.replace(base_weights, :monster, 35)
      else
        base_weights
      end

    total = adjusted |> Keyword.values() |> Enum.sum()
    random = :rand.uniform() * total

    Enum.reduce_while(adjusted, random, fn {type, weight}, acc ->
      new_acc = acc - weight
      if new_acc <= 0, do: {:halt, type}, else: {:cont, {new_acc, type}}
    end)
  end

  defp random_bandit do
    Enum.random([
      %{id: "bandit", name: "Бандит", hp: 45, max_hp: 45, damage: 6, xp: 40, level: 3, ac: 13},
      %{
        id: "bandit_outlaw",
        name: "Бандит-дезертир",
        hp: 55,
        max_hp: 55,
        damage: 7,
        xp: 50,
        level: 4,
        ac: 13
      }
    ])
  end

  defp handle_status(status, state) do
    require Logger

    Logger.warning(
      "[Hero] Unknown or incompatible status: #{inspect(status)}. Recovering to :idle."
    )

    state
    |> Map.put(:status, :idle)
    |> add_to_log("Заблудился в закоулках разума... (Ошибка состояния: #{inspect(status)})")
  end

  # --- Helper functions ---

  defp attempt_emergency_flee(state) do
    attr_mod = Mechanics.modifier(state.agility)
    luck_value = state.luck
    dc = 17

    case Mechanics.roll_check(attr_mod, luck_value, dc, state.luck_modifier) do
      {:success, _roll, _total, log} ->
        target = state.target
        state = Brain.process_combat_outcome(state, :fled, target)

        state
        |> Map.put(:status, :fleeing)
        |> Map.put(:target, nil)
        |> Map.put(:stamina, state.stamina - 25)
        |> add_to_log("Побег: #{log}. Успешно сбежал из боя! (-25 Выносливости)")

      {:fail, _roll, _total, log} ->
        state
        |> Map.put(:stamina, state.stamina - 10)
        |> add_to_log("Побег: #{log}. Не удалось сбежать! (-10 Выносливости)")
    end
  end

  # --- Actions ---

  defp think(state) do
    thought = Brain.contextual_thought(state)
    add_to_log(state, "Мысли: \"#{thought}\"")
  end

  defp analyze_equipment(state) do
    thoughts = Items.analyze_equipment(state)
    thought = Enum.random(thoughts)
    add_to_log(state, "Анализ экипировки: #{thought}")
  end

  defp random_event(state) do
    event = Enum.random(GameContent.random_events())
    state = add_to_log(state, event.msg)

    case event.effect do
      :heal -> Map.put(state, :hp, min(state.hp + 10, state.max_hp))
      _ -> state
    end
  end

  defp start_quest(state) do
    quest_type = Enum.random([:bounty, :bounty, :delivery, :delivery, :gathering])

    quest =
      case quest_type do
        :bounty ->
          Enum.random(GameContent.quests_by_type(:bounty))

        :delivery ->
          Enum.random(GameContent.quests_by_type(:delivery))

        :gathering ->
          Enum.random(GameContent.quests_by_type(:gathering))
      end

    state
    |> Map.put(:status, :questing)
    |> Map.put(:target, quest)
    |> Map.put(:quest_progress, 0)
    |> add_to_log("Принял новый квест: #{quest.name}", %{type: "quest_started"})
  end

  defp start_combat(state) do
    monster = GameContent.get_random_monster(state.level)

    state
    |> Map.put(:status, :combat_initiative)
    |> Map.put(:target, monster)
    |> add_to_log("Заметил противника: #{monster.name}!")
  end

  defp attempt_steal(state) do
    attr_mod = Mechanics.modifier(state.agility)
    luck_value = state.luck
    dc = 15
    perk_bonus = if Enum.member?(state.perks, :lucky_thief), do: 5, else: 0

    case Mechanics.roll_check(attr_mod + perk_bonus, luck_value, dc) do
      {:success, roll, total, log} ->
        base_gold = 10
        earned_gold = TempleMechanics.apply_gold_bonus(state.temple, base_gold)

        state
        |> Map.put(:gold, state.gold + earned_gold)
        |> Map.put(
          :statistics,
          %{state.statistics | total_steals: state.statistics.total_steals + 1}
        )
        |> add_to_log("Воровство: #{log}. Спер #{earned_gold} золотых!", %{
          type: "skill_roll",
          action: "steal",
          roll: roll,
          total: total,
          success: true
        })

      {:fail, roll, total, log} ->
        state
        |> Map.put(:hp, state.hp - 5)
        |> add_to_log("Воровство: #{log}. Попался! (-5 HP).", %{
          type: "skill_roll",
          action: "steal",
          roll: roll,
          total: total,
          success: false
        })
    end
  end

  # --- Utilities ---

  defp maybe_rest(state) do
    if state.status == :idle && state.hp < state.max_hp * 0.3 do
      state
      |> Map.put(:status, :resting)
      |> add_to_log("Слишком много ран. Нужно отдохнуть.")
    else
      state
    end
  end

  defp regenerate_intervention_power(state) do
    if state.intervention_power < 100 do
      Map.put(state, :intervention_power, state.intervention_power + 1)
    else
      state
    end
  end

  defp regenerate_stamina(state) do
    if state.status not in [:combat, :combat_round, :combat_initiative] and
         state.stamina < state.stamina_max do
      Map.put(state, :stamina, min(state.stamina + 2, state.stamina_max))
    else
      state
    end
  end

  defp persist_log(%{id: nil}, _entry), do: :ok

  defp persist_log(%{id: hero_id}, %{
         message: msg,
         inserted_at: inserted_at,
         metadata: metadata,
         game_time: game_time
       }) do
    Task.start(fn ->
      %GodvilleSk.Game.HeroLog{}
      |> Ecto.Changeset.change(%{
        hero_id: hero_id,
        message: msg,
        metadata: metadata,
        inserted_at: inserted_at,
        game_time: game_time
      })
      |> Repo.insert()
    end)

    :ok
  end
end
