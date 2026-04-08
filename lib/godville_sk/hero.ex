defmodule GodvilleSk.Hero do
  @moduledoc """
  Продвинутый "Мозг" героя в мире Elder Scrolls.
  Реализует машину состояний (State Machine) с использованием атрибутов TES и D20 механик.
  Интегрирован с Ecto для сохранения состояния и Phoenix.PubSub для real-time обновлений.
  """

  use GenServer
  alias GodvilleSk.GameData
  alias GodvilleSk.Game
  alias GodvilleSk.Game.Hero, as: HeroSchema
  alias GodvilleSk.Repo

  @tick_interval :timer.seconds(2)
  @save_interval :timer.minutes(1)
  @max_log_size 10

  defstruct [
    # Базовые
    :id, :name, :race, :class, :user_id,
    level: 1,
    gold: 0,
    hp: 100,
    max_hp: 100,
    exp: 0,
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
    # Контекст
    status: :idle, # :idle, :combat, :resting, :questing
    target: nil,
    quest_progress: 0,
    log: []
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

    {:ok, add_to_log(state, "Пронулся в таверне. Пора за работу!")}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = handle_status(state.status, state)
    
    # Если HP упало слишком низко и мы не в бою - идем отдыхать
    new_state = maybe_rest(new_state)

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

  # --- State Handlers ---

  defp handle_status(:idle, state) do
    case Enum.random([:think, :event, :quest, :combat, :steal]) do
      :think  -> think(state)
      :event  -> random_event(state)
      :quest  -> start_quest(state)
      :combat -> start_combat(state)
      :steal  -> attempt_steal(state)
    end
  end

  defp handle_status(:resting, state) do
    heal_amount = round(state.max_hp * 0.1)
    new_hp = min(state.hp + heal_amount, state.max_hp)
    
    if new_hp >= state.max_hp do
      state
      |> Map.put(:hp, state.max_hp)
      |> Map.put(:status, :idle)
      |> add_to_log("Полон сил и готов к новым свершениям!")
    else
      Map.put(state, :hp, new_hp)
      |> add_to_log("Отдыхаю у костра... HP: #{new_hp}/#{state.max_hp}")
    end
  end

  defp handle_status(:questing, state) do
    progress = state.quest_progress + 1
    total = state.target.steps

    if progress >= total do
      new_exp = state.exp + 10
      state
      |> Map.put(:status, :idle)
      |> Map.put(:gold, state.gold + state.target.reward)
      |> Map.put(:exp, new_exp)
      |> add_to_log("Квест '#{state.target.name}' выполнен! Получено #{state.target.reward} золотых.")
      |> maybe_level_up()
    else
      state
      |> Map.put(:quest_progress, progress)
      |> add_to_log("Выполняю квест: #{state.target.name} (#{progress}/#{total})")
    end
  end

  defp handle_status(:combat, state) do
    {_hero_hits, damage, log_msg} = perform_attack(state, state.target)
    
    new_target_hp = state.target.hp - damage
    updated_target = Map.put(state.target, :hp, new_target_hp)

    state = add_to_log(state, log_msg)

    if new_target_hp <= 0 do
      new_exp = state.exp + (state.target.level * 5)
      state
      |> Map.put(:status, :idle)
      |> Map.put(:target, nil)
      |> Map.put(:gold, state.gold + (state.level * 5))
      |> Map.put(:exp, new_exp)
      |> add_to_log("Победа над #{updated_target.name}!")
      |> maybe_level_up()
    else
      monster_damage = max(1, updated_target.damage - modifier(state.agility)) 
      new_hero_hp = state.hp - monster_damage
      
      state
      |> Map.put(:hp, new_hero_hp)
      |> Map.put(:target, updated_target)
      |> add_to_log("#{updated_target.name} бьет в ответ на #{monster_damage} урона!")
    end
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
    monster = Enum.random(GameData.monsters())
    state
    |> Map.put(:status, :combat)
    |> Map.put(:target, monster)
    |> add_to_log("Заметил противника: #{monster.name}!")
  end

  defp attempt_steal(state) do
    attr_mod = modifier(state.agility)
    luck_value = state.luck
    dc = 15
    perk_bonus = if Enum.member?(state.perks, :lucky_thief), do: 5, else: 0

    case roll_check(attr_mod + perk_bonus, luck_value, dc) do
      {:success, _roll, _total, log} ->
        state
        |> Map.put(:gold, state.gold + 10)
        |> add_to_log("Воровство: #{log}. Спер 10 золотых!")

      {:fail, _roll, _total, log} ->
        state
        |> Map.put(:hp, state.hp - 5)
        |> add_to_log("Воровство: #{log}. Попался! (-5 HP).")
    end
  end

  # --- Mechanics Helpers ---

  defp roll_check(attr_mod, luck_value, dc) do
    roll = Enum.random(1..20)
    luck_bonus = div(luck_value, 10)
    total = roll + attr_mod + luck_bonus

    case roll do
      1 -> {:fail, 1, total, "Натуральная 1! Критический провал"}
      20 -> {:success, 20, total, "Натуральная 20! Критический успех"}
      _ ->
        if total >= dc, 
          do: {:success, roll, total, "Бросок #{roll} + Мод #{attr_mod} + Удача #{luck_bonus} = #{total} (DC #{dc})"},
          else: {:fail, roll, total, "Бросок #{roll} + Мод #{attr_mod} + Удача #{luck_bonus} = #{total} (DC #{dc})"}
    end
  end

  defp perform_attack(state, target) do
    attr_mod = modifier(state.strength) + state.level
    luck_value = state.luck
    dc = target.ac

    case roll_check(attr_mod, luck_value, dc) do
      {:success, 20, _total, log} ->
        damage = (state.level * 4) + (modifier(state.strength) * 2)
        {true, damage, "#{log}: Сокрушительный удар на #{damage} урона!"}

      {:success, _roll, _total, log} ->
        damage = max(1, 5 + modifier(state.strength))
        {true, damage, "#{log}: Попадание на #{damage} урона!"}

      {:fail, 1, _total, log} ->
        {false, 0, "#{log}: Споткнулся."}

      {:fail, _roll, _total, log} ->
        {false, 0, "#{log}: Промах!"}
    end
  end

  defp modifier(value), do: div(value - 50, 10)

  defp maybe_level_up(state) do
    needed_exp = state.level * 100
    if state.exp >= needed_exp do
      state
      |> Map.put(:level, state.level + 1)
      |> Map.put(:exp, 0)
      |> Map.put(:max_hp, state.max_hp + 10)
      |> Map.put(:hp, state.max_hp + 10)
      |> add_to_log("УРОВЕНЬ ПОВЫШЕН! Теперь вы уровень #{state.level + 1}!")
    else
      state
    end
  end

  # --- DB & Engine Helpers ---

  defp load_from_db(id) do
    hero = Repo.get!(HeroSchema, id)
    attrs = hero.attributes || %{}
    
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
      exp: hero.exp,
      strength: attrs["strength"] || 50,
      intelligence: attrs["intelligence"] || 50,
      willpower: attrs["willpower"] || 50,
      agility: attrs["agility"] || 50,
      speed: attrs["speed"] || 50,
      endurance: attrs["endurance"] || 50,
      personality: attrs["personality"] || 50,
      luck: attrs["luck"] || 50,
      perks: hero.perks || [],
      log: ["Возвращение в мир..."]
    }
  end

  defp initialize_new_hero(opts) do
    %__MODULE__{
      name: opts[:name],
      race: opts[:race] || "Nord",
      class: opts[:class] || "Adventurer",
      perks: opts[:perks] || [],
      log: ["Да начнутся приключения!"]
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
        exp: state.exp,
        attributes: attrs
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

  defp add_to_log(state, msg) do
    new_log = [msg | state.log] |> Enum.take(@max_log_size)
    Map.put(state, :log, new_log)
  end

  defp via_tuple(name), do: {:global, {:hero, name}}
end
