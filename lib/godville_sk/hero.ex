defmodule GodvilleSk.Hero do
  @moduledoc """
  Продвинутый "Мозг" героя в мире Elder Scrolls.
  Реализует машину состояний (State Machine) с использованием атрибутов TES и D20 механик.
  Интегрирован с Ecto для сохранения состояния и Phoenix.PubSub для real-time обновлений.
  """

  use GenServer
  import Ecto.Query, warn: false

  alias GodvilleSk.GameData
  alias GodvilleSk.Game
  alias GodvilleSk.Game.Hero, as: HeroSchema
  alias GodvilleSk.Game.HeroLog
  alias GodvilleSk.Game.LogMetadata
  alias GodvilleSk.Repo
  alias GodvilleSk.WorldClock
  require Logger

  @tick_interval :timer.seconds(2)
  @save_interval :timer.minutes(1)
  @max_log_size 60

  defstruct [
    # Базовые
    :id, :name, :race, :class, :user_id,
    level: 1,
    gold: 0,
    hp: 100,
    max_hp: 100,
    xp: 0,
    inventory: [],
    inventory_capacity: 10,
    location: "Балмора",
    # Атрибуты TES (0-100+)
    strength: 50,
    intelligence: 50,
    willpower: 50,
    agility: 50,
    speed: 50,
    endurance: 50,
    personality: 50,
    luck: 50,
    # RPG статы
    ac: 14,
    perks: [],
    intervention_power: 100,
    # Контекст
    status: :idle, # :idle, :combat_initiative, :combat_round, :resting, :questing
    target: nil,
    turn: :hero, # :hero | :enemy
    quest_progress: 0,
    log: [],
    # Добавленные поля
    equipment: %{
      weapon: nil, head: nil, torso: nil, legs: nil, 
      arms: nil, boots: nil, amulet: nil, ring: nil
    },
    statistics: %{
      total_steals: 0,
      total_wins: 0,
      total_quests: 0,
      total_deaths: 0
    },
    temple: %{
      construction_progress: 0,
      enemies: ["Мерунес Дагон", "Молаг Бал"]
    },
    # Новые поля
    stamina: 100,
    stamina_max: 100,
    luck_modifier: 0,
    respawn_at: nil # Время возвращения из Совнгарда
  ]

  # --- Client API ---

  @doc """
  Запускает процесс героя. Если передан id, загружает состояние из базы.
  """
  def start_link(opts) do
    id = opts[:id]
    name = opts[:name] || (id && fetch_name_from_db(id))
    GenServer.start_link(__MODULE__, opts, name: via_tuple(name))
  end

  def child_spec(opts) do
    %{
      id: {__MODULE__, opts[:name] || opts[:id]},
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient
    }
  end

  @doc "Returns the current state of the hero GenServer."
  def get_state(hero_name, timeout \\ 5000) do
    GenServer.call(via_tuple(hero_name), :get_state, timeout)
  end

  @doc "Sends a divine whisper message to the hero's log."
  def send_whisper(hero_name, text) do
    GenServer.cast(via_tuple(hero_name), {:divine_whisper, text})
  end

  @doc "Blesses the hero (heal, gold, loot, or gratitude)."
  def bless(hero_name) do
    GenServer.cast(via_tuple(hero_name), :bless)
  end

  @doc "Punishes the hero (or their foe in combat)."
  def punish(hero_name) do
    GenServer.cast(via_tuple(hero_name), :punish)
  end

  @doc "Early resurrection from Sovngarde using Divine Intervention."
  def divine_intervention(hero_name) do
    GenServer.cast(via_tuple(hero_name), :divine_intervention)
  end

  @doc "Equips an item from inventory to a slot."
  def equip(hero_name, item_name, slot) do
    GenServer.cast(via_tuple(hero_name), {:equip, item_name, slot})
  end

  @doc "Unequips an item from a slot."
  def unequip(hero_name, slot) do
    GenServer.cast(via_tuple(hero_name), {:unequip, slot})
  end

  # --- Debug API ---
  
  def debug_update(hero_name, updates) do
    GenServer.cast(via_tuple(hero_name), {:debug_update, updates})
  end

  def debug_force_tick(hero_name) do
    GenServer.cast(via_tuple(hero_name), :debug_force_tick)
  end

  def debug_add_inventory(hero_name, item) do
    GenServer.cast(via_tuple(hero_name), {:debug_add_inventory, item})
  end

  def debug_remove_inventory(hero_name, item) do
    GenServer.cast(via_tuple(hero_name), {:debug_remove_inventory, item})
  end

  defp fetch_name_from_db(id) do
    Repo.get(HeroSchema, id).name
  end

  # --- Server Callbacks ---

  @impl true
  def init(opts) do
    state = 
      if id = opts[:id] do
        load_from_db(id)
      else
        initialize_new_hero(opts)
      end

    schedule_tick()
    schedule_save()

    Logger.info("[Hero] Character '#{state.name}' (LVL #{state.level}) initialized. Status: #{state.status}")

    {:ok, add_to_log(state, "Пронулся в таверне. Пора за работу!")}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = handle_status(state.status, state)
    
    # Если HP упало слишком низко и мы не в бою - идем отдыхать
    new_state = maybe_rest(new_state)

    # Регенерация силы вмешательства
    new_state = if new_state.intervention_power < 100 do
      Map.put(new_state, :intervention_power, new_state.intervention_power + 1)
    else
      new_state
    end

    # Регенерация выносливости (если не в бою)
    new_state = if new_state.status not in [:combat, :combat_round, :combat_initiative] and new_state.stamina < new_state.stamina_max do
      Map.put(new_state, :stamina, min(new_state.stamina + 2, new_state.stamina_max))
    else
      new_state
    end

    # Рассылаем обновление через PubSub
    broadcast_update(new_state)

    schedule_tick()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:save, state) do
    save_to_db(state)
    schedule_save()
    {:noreply, state}
  end

  @impl true
  def handle_info({:deliver_whisper, text}, state) do
    phrasing =
      Enum.random([
        "Сидел у костра, и вдруг уголь рассыпался в слова: \"#{text}\".",
        "Ветер прошептал: \"#{text}\" — и я понял, что это знак.",
        "На мокром камне проступила надпись: \"#{text}\". Странные дела.",
        "В голове вспыхнула мысль, будто чужая: \"#{text}\"."
      ])

    state = add_to_log(state, phrasing)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:divine_whisper, text}, state) do
    delay_ms = Enum.random(10_000..90_000)
    Process.send_after(self(), {:deliver_whisper, text}, delay_ms)

    state =
      state
      |> Map.put(:intervention_power, max(0, state.intervention_power - 50))
      |> add_to_log("Небеса дрогнули. Кажется, до меня пытаются достучаться...")

    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:bless, state) do
    {state, msg} =
      case Enum.random([:heal, :gold, :loot, :thanks]) do
        :heal ->
          amount = Enum.random(10..30)
          new_hp = min(state.hp + amount, state.max_hp)
          {Map.put(state, :hp, new_hp), "Тепло коснулось плеча. Раны затянулись (+#{new_hp - state.hp} HP)."}

        :gold ->
          amount = Enum.random(15..60)
          {Map.put(state, :gold, state.gold + amount), "У ног звякнул мешочек — #{amount} золотых. Благословение принято."}

        :loot ->
          item = GameData.get_random_loot(state.level)
          inv = [item | state.inventory] |> Enum.take(state.inventory_capacity)
          {Map.put(state, :inventory, inv), "С неба упал дар: #{item}."}

        :thanks ->
          {state, "Небеса молчали, но стало спокойнее. Я тихо поблагодарил."}
      end

    state = 
      state
      |> Map.put(:intervention_power, max(0, state.intervention_power - 50))
      |> add_to_log("[Благословение] " <> msg)

    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:punish, state) do
    {state, msg} =
      cond do
        state.status == :combat and is_map(state.target) ->
          # Punishment may hit foe instead of hero.
          if :rand.uniform() < 0.6 do
            dmg = Enum.random(5..15)
            new_hp = state.target.hp - dmg
            target = Map.put(state.target, :hp, new_hp)

            state =
              if new_hp <= 0 do
                state
                |> Map.put(:status, :idle)
                |> Map.put(:target, nil)
                |> Map.put(:xp, state.xp + state.target.level * 5)
                |> Map.put(:gold, state.gold + state.level * 5)
              else
                Map.put(state, :target, target)
              end

            {state, "Молния ударила рядом и зацепила врага (-#{dmg} HP)."}
          else
            dmg = Enum.random(5..18)
            new_hp = max(0, state.hp - dmg)
            {Map.put(state, :hp, new_hp), "Рядом со мной ударила молния… не стоит злить богов (-#{dmg} HP)."}
          end

        true ->
          # Out of combat: mostly small nudges, rarely severe.
          if :rand.uniform() < 0.9 do
            dmg = Enum.random(3..12)
            new_hp = max(0, state.hp - dmg)
            {Map.put(state, :hp, new_hp), "Знак был недвусмысленным. Я споткнулся и ушибся (-#{dmg} HP)."}
          else
            dmg = Enum.random(15..35)
            new_hp = max(0, state.hp - dmg)
            {Map.put(state, :hp, new_hp), "Небеса разгневались. Меня будто придавило невидимой силой (-#{dmg} HP)."}
          end
      end

    state = 
      state
      |> Map.put(:intervention_power, max(0, state.intervention_power - 50))
      |> add_to_log("[Наказание] " <> msg)
      
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:divine_intervention, state) do
    if state.status == :sovngarde and state.intervention_power >= 100 do
      state =
        state
        |> Map.put(:status, :idle)
        |> Map.put(:respawn_at, nil)
        |> Map.put(:hp, state.max_hp) # Full heal upon resurrection
        |> Map.put(:intervention_power, 0)
        |> Map.put(:location, GameData.get_location())
        |> add_to_log("[БОЖЕСТВЕННОЕ ВМЕШАТЕЛЬСТВО] Небеса раскрылись, и властный голос вернул мою душу в мир живых! Я воскрес!", %{
          type: "resurrection"
        })

      broadcast_update(state)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:equip, item_name, slot}, state) do
    if Enum.member?(state.inventory, item_name) do
      # If something already in slot, put it back to inventory
      old_item = state.equipment[slot]
      
      inventory = List.delete(state.inventory, item_name)
      inventory = if old_item, do: [old_item | inventory], else: inventory
      
      equipment = Map.put(state.equipment, slot, item_name)
      
      state = 
        state
        |> Map.put(:inventory, inventory)
        |> Map.put(:equipment, equipment)
        |> add_to_log("Экипировал: #{item_name} в слот #{slot}")
      
      broadcast_update(state)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:unequip, slot}, state) do
    item = state.equipment[slot]
    if item do
      equipment = Map.put(state.equipment, slot, nil)
      inventory = [item | state.inventory] |> Enum.take(state.inventory_capacity)
      
      state = 
        state
        |> Map.put(:inventory, inventory)
        |> Map.put(:equipment, equipment)
        |> add_to_log("Снял предмет: #{item}")
      
      broadcast_update(state)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end
  @impl true
  def handle_cast({:debug_update, updates}, state) do
    new_state = Map.merge(state, updates)
    broadcast_update(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:debug_force_tick, state) do
    # Trigger tick immediately
    send(self(), :tick)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:debug_add_inventory, item}, state) do
    new_inventory = [item | state.inventory] |> Enum.take(state.inventory_capacity)
    new_state = Map.put(state, :inventory, new_inventory)
    broadcast_update(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:debug_remove_inventory, item}, state) do
    new_inventory = List.delete(state.inventory, item)
    new_state = Map.put(state, :inventory, new_inventory)
    broadcast_update(new_state)
    {:noreply, new_state}
  end

  # --- State Handlers ---

  # --- State Machine Normalization ---

  # 1. Level Up (Highest priority for all active statuses)
  defp handle_status(_status, %{xp: xp, level: level} = state) when xp >= level * 100 do
    attributes = [:strength, :intelligence, :willpower, :agility, :speed, :endurance, :personality, :luck]
    attr = Enum.random(attributes)
    current_val = Map.get(state, attr)

    state
    |> Map.put(:status, :leveling_up)
    |> Map.put(:level, level + 1)
    |> Map.put(:xp, 0)
    |> Map.put(:max_hp, state.max_hp + 10)
    |> Map.put(:hp, state.max_hp + 10)
    |> Map.put(attr, (current_val || 50) + 1)
    |> tap(fn _ -> Logger.info("[Hero] '#{state.name}' reached LEVEL #{level + 1}! #{attr} increased.") end)
    |> add_to_log("УРОВЕНЬ ПОВЫШЕН! Теперь вы уровень #{level + 1}! #{attr} +1.")
  end

  # 2. Leveling Up (Transition back to idle)
  defp handle_status(:leveling_up, state) do
    Map.put(state, :status, :idle)
  end

  # 3. Sovngarde (Afterlife)
  defp handle_status(:sovngarde, %{respawn_at: respawn_at, hp: hp, max_hp: max_hp, stamina: st, stamina_max: st_max} = state) do
    now = DateTime.utc_now()
    
    # Если время вышло - возвращаемся в мир живых
    if respawn_at && DateTime.compare(now, respawn_at) in [:gt, :eq] do
      state
      |> Map.put(:status, :idle)
      |> Map.put(:respawn_at, nil)
      |> Map.put(:location, GameData.get_location())
      |> add_to_log("Шор милостиво открыл портал. Срок в Совнгарде окончен. Возвращаюсь!")
    else
      # Иначе продолжаем выполнять задания и лечиться
      state = case Enum.random([:task, :thought, :heal]) do
        :task ->
          task = Enum.random(GameData.sovngarde_tasks())
          add_to_log(state, "Совнгард: [Задание] #{task.title}. #{task.description}", %{
            type: "sovngarde_task",
            task_id: task.id,
            title: task.title
          })
        :thought ->
          thought = Enum.random(GameData.sovngarde_thoughts())
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

  # 4. Resting
  defp handle_status(:resting, %{hp: hp, max_hp: max} = state) do
    if hp >= max do
      state
      |> Map.put(:status, :idle)
      |> add_to_log("Отдохнул и восстановил силы. Пора в путь!")
    else
      Map.put(state, :hp, min(hp + 5, max))
    end
  end

  # 5. Fleeing
  defp handle_status(:fleeing, state) do
    state
    |> Map.put(:status, :idle)
    |> add_to_log("Скрылся от опасности. Перевожу дух.")
  end

  # 6. Trading
  defp handle_status(:trading, state) do
    state
    |> Map.put(:status, :idle)
    |> add_to_log("Торговля окончена. Карманы звенят.")
  end

  # 7. Questing (Requires safety check)
  defp handle_status(:questing, state) do
    if is_nil(state.target) do
      Logger.error("[Hero] '#{state.name}' normalized from :questing to :idle (target missing)")
      Map.put(state, :status, :idle)
    else
      progress = state.quest_progress + 1
      total = state.target.steps

      if progress >= total do
        new_xp = state.xp + 10
        stats = update_in(state.statistics, [:total_quests], fn val -> (val || 0) + 1 end)

        state
        |> Map.put(:status, :idle)
        |> Map.put(:gold, state.gold + state.target.reward)
        |> Map.put(:xp, new_xp)
        |> Map.put(:statistics, stats)
        |> add_to_log("Квест '#{state.target.name}' выполнен! Получено #{state.target.reward} золотых.")
      else
        state
        |> Map.put(:quest_progress, progress)
        |> add_to_log("Выполняю квест: #{state.target.name} (#{progress}/#{total})")
      end
    end
  end

  # 8. Combat Initiative (Requires safety check)
  defp handle_status(:combat_initiative, state) do
    if is_nil(state.target) do
      Logger.error("[Hero] '#{state.name}' normalized from :combat_initiative to :idle (target missing)")
      Map.put(state, :status, :idle)
    else
      do_combat_initiative(state)
    end
  end

  # 9. Combat Round (Handles Fleeing and Safety)
  defp handle_status(:combat_round, state) do
    cond do
      is_nil(state.target) ->
        Logger.error("[Hero] '#{state.name}' normalized from :combat_round to :idle (target missing)")
        Map.put(state, :status, :idle)

      state.hp < state.max_hp * 0.15 && state.stamina >= 25 ->
        # Low HP - attempt to flee
        attempt_emergency_flee(state)
      
      true ->
        do_combat_round(state)
    end
  end

  # 10. Idle
  defp handle_status(:idle, %{inventory: inv, inventory_capacity: cap} = state) when length(inv) >= cap do
    num_items = length(inv)
    earned_gold = Enum.reduce(1..num_items, 0, fn _, acc -> acc + Enum.random(5..15) end)

    state
    |> Map.put(:status, :trading)
    |> Map.put(:inventory, [])
    |> Map.put(:gold, state.gold + earned_gold)
    |> add_to_log("Инвентарь полон! Продал #{num_items} вещей за #{earned_gold} золотых.")
  end

  defp handle_status(:idle, state) do
    if :rand.uniform() <= 0.2 do
      new_location = GameData.get_location()
      state
      |> Map.put(:location, new_location)
      |> add_to_log("Отправился в путешествие... Новая локация: #{new_location}")
    else
      case Enum.random([:think, :event, :quest, :combat, :steal]) do
        :think  -> think(state)
        :event  -> random_event(state)
        :quest  -> start_quest(state)
        :combat -> start_combat(state)
        :steal  -> attempt_steal(state)
      end
    end
  end

  # 11. Catch-all for unknown states
  defp handle_status(status, state) do
    Logger.warning("[Hero] Unknown or incompatible status: #{inspect(status)}. Recovering to :idle.")
    state
    |> Map.put(:status, :idle)
    |> add_to_log("Заблудился в закоулках разума... (Ошибка состояния: #{inspect(status)})")
  end

  # --- State Logic Helpers ---

  defp attempt_emergency_flee(state) do
    attr_mod = modifier(state.agility)
    luck_value = state.luck
    dc = 17

    case roll_check(attr_mod, luck_value, dc, state.luck_modifier) do
      {:success, _roll, _total, log} ->
        state
        |> Map.put(:status, :fleeing)
        |> Map.put(:target, nil)
        |> Map.put(:stamina, state.stamina - 25)
        |> add_to_log("Побег: #{log}. Успешно сбежал из боя! (-25 Выносливости)")

      {:fail, _roll, _total, log} ->
        state = 
          state 
          |> Map.put(:stamina, state.stamina - 10)
          |> add_to_log("Побег: #{log}. Не удалось сбежать! (-10 Выносливости)")
        
        # We don't call do_combat_round directly to avoid stack overflow or priority issues.
        # Instead, we stay in :combat_round and let the next tick handle the fight.
        state
    end
  end

  defp do_combat_initiative(state) do
    hero_mod = modifier(state.agility)
    enemy_mod = modifier(state.target.level * 5 + 50) # approximate enemy agility

    hero_roll = Enum.random(1..20)
    enemy_roll = Enum.random(1..20)
    
    hero_total = hero_roll + hero_mod
    enemy_total = enemy_roll + enemy_mod

    first_turn = if hero_total >= enemy_total, do: :hero, else: :enemy

    # Emit an event for initiative rolls so UI can show it
    state = add_to_log(state, "Бросок инициативы! Герой: #{hero_total} (#{hero_roll}+#{hero_mod}), #{state.target.name}: #{enemy_total} (#{enemy_roll}+#{enemy_mod})", %{
      type: "initiative_roll",
      hero_roll: hero_roll,
      enemy_roll: enemy_roll,
      turn: first_turn
    })

    state
    |> Map.put(:status, :combat_round)
    |> Map.put(:turn, first_turn)
  end

  defp do_combat_round(state) do
    if state.turn == :hero do
      # Бросок Героя
      {is_hit, damage, total, roll, log_msg} = perform_attack(state, state.target)
      
      new_target_hp = state.target.hp - damage
      updated_target = Map.put(state.target, :hp, new_target_hp)

      state = add_to_log(state, log_msg, %{
        type: "combat_roll",
        actor: "hero",
        target: updated_target.name,
        roll: roll,
        total: total,
        damage: damage,
        is_hit: is_hit
      })

      if new_target_hp <= 0 do
        handle_victory(state, updated_target)
      else
        state
        |> Map.put(:target, updated_target)
        |> Map.put(:turn, :enemy)
      end
    else
      # Бросок Врага
      {is_hit, damage, total, roll, log_msg} = perform_enemy_attack(state.target, state)
      
      new_hero_hp = state.hp - damage

      state = add_to_log(state, log_msg, %{
        type: "combat_roll",
        actor: "enemy",
        target: state.name,
        roll: roll,
        total: total,
        damage: damage,
        is_hit: is_hit
      })

      if new_hero_hp <= 0 do
        # 10-20 минут реального времени
        duration_mins = Enum.random(10..20)
        respawn_at = DateTime.add(DateTime.utc_now(), duration_mins, :minute)

        state
        |> Map.put(:hp, 0)
        |> Map.put(:status, :sovngarde)
        |> Map.put(:location, "Совнгард")
        |> Map.put(:target, nil)
        |> Map.put(:gold, max(0, state.gold - 100))
        |> Map.put(:luck_modifier, -2)
        |> Map.put(:respawn_at, respawn_at)
        |> Map.put(:statistics, update_in(state.statistics, [:total_deaths], fn val -> (val || 0) + 1 end))
        |> add_to_log("Дух покидает тело... Отправление в Совнгард на #{duration_mins} мин. (-100 золота, эффект: Ослабленность -2)", %{
          type: "death",
          duration_minutes: duration_mins
        })
      else
        state
        |> Map.put(:hp, new_hero_hp)
        |> Map.put(:turn, :hero)
      end
    end
  end

  defp handle_victory(state, target) do
    new_xp = state.xp + (target.level * 5)
    loot = GameData.get_random_loot(state.level)
    new_inventory = [loot | state.inventory]

    state
    |> Map.put(:status, :idle)
    |> Map.put(:target, nil)
    |> Map.put(:gold, state.gold + (state.level * 5))
    |> Map.put(:xp, new_xp)
    |> Map.put(:inventory, new_inventory)
    |> Map.put(:statistics, update_in(state.statistics, [:total_wins], fn val -> (val || 0) + 1 end))
    |> add_to_log("Победа над #{target.name}! Получен предмет: #{loot}")
  end

  # --- Actions ---

  defp think(state) do
    thought = Enum.random(GameData.thoughts())
    add_to_log(state, "Мысли: \"#{thought}\"")
  end

  defp random_event(state) do
    event = Enum.random(GameData.random_events())
    state = add_to_log(state, event.msg)
    case event.effect do
      :heal -> Map.put(state, :hp, min(state.hp + 10, state.max_hp))
      _ -> state
    end
  end

  defp start_quest(state) do
    quest = Enum.random(GameData.quests())
    state
    |> Map.put(:status, :questing)
    |> Map.put(:target, quest)
    |> Map.put(:quest_progress, 0)
    |> add_to_log("Принял новый квест: #{quest.name}")
  end

  defp start_combat(state) do
    monster = GameData.get_random_monster(state.level)
    state
    |> Map.put(:status, :combat_initiative)
    |> Map.put(:target, monster)
    |> add_to_log("Заметил противника: #{monster.name}!")
  end

  defp attempt_steal(state) do
    attr_mod = modifier(state.agility)
    luck_value = state.luck
    dc = 15
    perk_bonus = if Enum.member?(state.perks, :lucky_thief), do: 5, else: 0

    case roll_check(attr_mod + perk_bonus, luck_value, dc) do
      {:success, roll, total, log} ->
        state
        |> Map.put(:gold, state.gold + 10)
        |> Map.put(:statistics, update_in(state.statistics, [:total_steals], fn val -> (val || 0) + 1 end))
        |> add_to_log("Воровство: #{log}. Спер 10 золотых!", %{type: "skill_roll", action: "steal", roll: roll, total: total, success: true})

      {:fail, roll, total, log} ->
        state
        |> Map.put(:hp, state.hp - 5)
        |> add_to_log("Воровство: #{log}. Попался! (-5 HP).", %{type: "skill_roll", action: "steal", roll: roll, total: total, success: false})
    end
  end

  # --- Mechanics Helpers ---

  defp roll_check(attr_mod, luck_value, dc, bonus_mod \\ 0) do
    roll = Enum.random(1..20)
    luck_bonus = div(luck_value, 10)
    total = roll + attr_mod + luck_bonus + bonus_mod

    case roll do
      1 -> {:fail, 1, total, "Натуральная 1! Критический провал"}
      20 -> {:success, 20, total, "Натуральная 20! Критический успех"}
      _ ->
        mod_str = if bonus_mod != 0, do: " + Эфф #{bonus_mod}", else: ""
        if total >= dc, 
          do: {:success, roll, total, "Бросок #{roll} + Мод #{attr_mod} + Удача #{luck_bonus}#{mod_str} = #{total} (DC #{dc})"},
          else: {:fail, roll, total, "Бросок #{roll} + Мод #{attr_mod} + Удача #{luck_bonus}#{mod_str} = #{total} (DC #{dc})"}
    end
  end

  defp perform_attack(state, target) do
    attr_mod = modifier(state.strength) + state.level
    luck_value = state.luck
    dc = target.ac

    case roll_check(attr_mod, luck_value, dc, state.luck_modifier) do
      {:success, 20, total, log} ->
        damage = (state.level * 4) + (modifier(state.strength) * 2)
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

  defp perform_enemy_attack(enemy, hero) do
    attr_mod = enemy.level
    luck_value = 50 # monsters have standard luck
    dc = hero.ac

    case roll_check(attr_mod, luck_value, dc) do
      {:success, 20, total, log} ->
        damage = enemy.damage * 2
        {true, damage, total, 20, "Враг #{log}: Критический удар на #{damage} урона!"}

      {:success, roll, total, log} ->
        damage = enemy.damage
        {true, damage, total, roll, "Враг #{log}: Попадает на #{damage} урона!"}

      {:fail, 1, total, log} ->
        {false, 0, total, 1, "Враг #{log}: Критический промах!"}

      {:fail, roll, total, log} ->
        {false, 0, total, roll, "Враг #{log}: Промах!"}
    end
  end

  defp modifier(value), do: div(value - 50, 10)

  # --- DB & Engine Helpers ---

  defp load_from_db(id) do
    hero = Repo.get!(HeroSchema, id)
    attrs = hero.attributes || %{}

    logs =
      HeroLog
      |> where([l], l.hero_id == ^id)
      |> order_by([l], desc: l.inserted_at)
      |> limit(@max_log_size)
      |> Repo.all()
      |> Enum.map(&log_entry_from_schema/1)
      |> Enum.map(fn entry ->
        metadata = entry.metadata || %{}
        if is_nil(metadata[:context]) do
          %{entry | metadata: Map.put(metadata, :context, :normal)}
        else
          entry
        end
      end)
    
    %__MODULE__{
      id: hero.id,
      name: hero.name,
      race: hero.race,
      class: hero.class,
      user_id: hero.user_id,
      level: hero.level,
      gold: hero.gold,
      hp: hero.hp,
      max_hp: hero.max_hp,
      xp: hero.exp,
      strength: attrs["strength"] || 50,
      intelligence: attrs["intelligence"] || 50,
      willpower: attrs["willpower"] || 50,
      agility: attrs["agility"] || 50,
      speed: attrs["speed"] || 50,
      endurance: attrs["endurance"] || 50,
      personality: attrs["personality"] || 50,
      luck: attrs["luck"] || 50,
      perks: hero.perks || [],
      intervention_power: hero.intervention_power || 100,
      equipment: normalize_keys(hero.equipment || %{weapon: nil, head: nil, torso: nil, legs: nil, arms: nil, boots: nil, amulet: nil, ring: nil}),
      statistics: normalize_keys(Map.merge(%{total_steals: 0, total_wins: 0, total_quests: 0, total_deaths: 0}, hero.statistics || %{})),
      temple: normalize_keys(hero.temple || %{construction_progress: 0, enemies: ["Мерунес Дагон", "Молаг Бал"]}),
      stamina: hero.attributes["stamina"] || 100,
      stamina_max: hero.attributes["stamina_max"] || 100,
      luck_modifier: hero.attributes["luck_modifier"] || 0,
      respawn_at: parse_datetime(hero.attributes["respawn_at"]),
      status: parse_status(hero.attributes["status"]),
      inventory: hero.attributes["inventory"] || [],
      location: hero.attributes["location"] || "Балмора",
      target: normalize_keys(hero.attributes["target"]),
      quest_progress: hero.attributes["quest_progress"] || 0,
      turn: (if t = hero.attributes["turn"], do: String.to_existing_atom(t), else: :hero),
      log: logs
    }
  end

  defp parse_status(nil), do: :idle
  defp parse_status(status) when is_binary(status), do: String.to_existing_atom(status)
  defp parse_status(_), do: :idle

  defp parse_datetime(nil), do: nil
  defp parse_datetime(iso) when is_binary(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_datetime(_), do: nil

  defp initialize_new_hero(opts) do
    %__MODULE__{
      name: opts[:name],
      race: opts[:race] || "Nord",
      class: opts[:class] || "Adventurer",
      perks: opts[:perks] || [],
      log: []
    }
  end

  defp save_to_db(state) do
    if state.id do
      hero = Repo.get(HeroSchema, state.id)
      attrs = %{
        "strength" => state.strength,
        "intelligence" => state.intelligence,
        "willpower" => state.willpower,
        "agility" => state.agility,
        "speed" => state.speed,
        "endurance" => state.endurance,
        "personality" => state.personality,
        "luck" => state.luck
      }
      
      Game.update_hero(hero, %{
        gold: state.gold,
        hp: state.hp,
        level: state.level,
        exp: state.xp,
        intervention_power: state.intervention_power,
        equipment: state.equipment,
        statistics: state.statistics,
        temple: state.temple,
        attributes: Map.merge(attrs, %{
          "stamina" => state.stamina,
          "stamina_max" => state.stamina_max,
          "luck_modifier" => state.luck_modifier,
          "status" => Atom.to_string(state.status),
          "respawn_at" => (if state.respawn_at, do: DateTime.to_iso8601(state.respawn_at), else: nil),
          "inventory" => state.inventory,
          "location" => state.location,
          "target" => state.target,
          "quest_progress" => state.quest_progress,
          "turn" => Atom.to_string(state.turn)
        })
      })
    end
  end

  defp broadcast_update(state) do
    if state.id do
      Phoenix.PubSub.broadcast(GodvilleSk.PubSub, "hero:#{state.id}", {:hero_update, state})
    end
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, @tick_interval)
  defp schedule_save, do: Process.send_after(self(), :save, @save_interval)

  defp maybe_rest(state) do
    if state.status == :idle && state.hp < state.max_hp * 0.3 do
      state
      |> Map.put(:status, :resting)
      |> add_to_log("Слишком много ран. Нужно отдохнуть.")
    else
      state
    end
  end

  defp add_to_log(state, msg, metadata \\ %{}) do
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
        Logger.error("[Hero] Invalid metadata for log entry: #{inspect(reason)}. Message: #{msg}")
        state
    end
  end

  defp persist_log(%{id: nil}, _entry), do: :ok

  defp persist_log(%{id: hero_id}, %{message: msg, inserted_at: inserted_at, metadata: metadata}) do
    # Store message + inserted_at + metadata. Game time is derived from inserted_at via WorldClock.
    # Asynchronous logging to prevent GenServer/Pool bottlenecks
    Task.start(fn ->
      %HeroLog{}
      |> Ecto.Changeset.change(%{hero_id: hero_id, message: msg, metadata: metadata, inserted_at: inserted_at})
      |> Repo.insert()
    end)
    :ok
  end

  defp log_entry_from_schema(%HeroLog{} = log) do
    inserted_at = log.inserted_at

    %{
      id: log.id,
      message: log.message,
      metadata: log.metadata || %{},
      inserted_at: inserted_at,
      game_time: WorldClock.game_time_at(inserted_at)
    }
  end

  defp via_tuple(name), do: {:global, {:hero, name}}

  defp normalize_keys(nil), do: nil
  defp normalize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), normalize_keys(v)}
      {k, v} -> {k, v}
    end)
  end
  defp normalize_keys(list) when is_list(list), do: Enum.map(list, &normalize_keys/1)
  defp normalize_keys(val), do: val
end
