defmodule GodvilleSk.Hero do
  @moduledoc """
  Advanced "Brain" of the hero with TES/D20 mechanics.
  GenServer manages live state; logic delegated to sub-modules.
  """

  use GenServer
  alias GodvilleSk.Hero.{Persistence, StateMachine, Combat, Actions, Mechanics}
  alias GodvilleSk.God
  alias GodvilleSk.TickProfile
  require Logger

  @tick_interval Application.compile_env(:godville_sk, :tick_interval)
                 |> Keyword.get(Mix.env(), 2_000)
  @save_interval :timer.minutes(1)

  defstruct [
    :id,
    :name,
    :race,
    :class,
    :user_id,
    level: 1,
    gold: 0,
    xp: 0,
    hp: 100,
    max_hp: 100,
    ac: 14,
    strength: 50,
    intelligence: 50,
    willpower: 50,
    agility: 50,
    speed: 50,
    endurance: 50,
    personality: 50,
    luck: 50,
    perks: [],
    intervention_power: 100,
    status: :idle,
    target: nil,
    turn: :hero,
    quest_progress: 0,
    inventory: [],
    inventory_capacity: 50,
    inventory_weight: 0,
    overload_penalty: 0,
    equipment: GodvilleSk.Game.HeroEquipment.default(),
    statistics: GodvilleSk.Game.HeroStatistics.default(),
    temple: GodvilleSk.Game.HeroTemple.default(),
    stamina: 100,
    stamina_max: 100,
    luck_modifier: 0,
    location: "Балмора",
    tavern_drink_count: 0,
    respawn_at: nil,
    body_parts: %{
      left_arm: :healthy,
      right_arm: :healthy,
      left_leg: :healthy,
      right_leg: :healthy,
      head: :healthy
    },
    permanent_injuries: 0,
    log: [],
    battle_log: [],
    mood: :neutral,
    mood_intensity: 50,
    secondary_mood: nil,
    secondary_intensity: 0,
    mood_history: [],
    traits: %{
      risk_tolerance: 50,
      greediness: 50,
      bravery: 50,
      sociability: 50,
      curiosity: 50,
      stubbornness: 50
    },
    memory: [],
    fears: %{monsters: %{}, locations: %{}, conditions: %{}},
    goals: [],
    mood_timer: 0,
    fatigue: 0,
    memory_recall_cooldown: 0,
    tick_profile: TickProfile.default_profile(),
    last_action: nil,
    city_phase: :arrived,
    visited_cities: [],
    tavern_visited: false,
    walked_in_city: false,
    quest_checked: false,
    tick_counter: 0
  ]

  # --- Client API ---

  @doc """
  Starts the hero GenServer. Loads from DB if `:id` is provided.
  """
  def start_link(opts) do
    id = opts[:id]
    name = opts[:name] || (id && Persistence.fetch_name_from_db(id))
    GenServer.start_link(__MODULE__, opts, name: via_tuple(name))
  end

  def child_spec(opts) do
    %{
      id: {__MODULE__, opts[:name] || opts[:id]},
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient
    }
  end

  @doc "Returns the full hero state."
  def get_state(hero_name, timeout \\ 5000) do
    GenServer.call(via_tuple(hero_name), :get_state, timeout)
  end

  @doc "Sends a divine whisper to the hero's log."
  def send_whisper(hero_name, text) do
    GenServer.cast(via_tuple(hero_name), {:divine_whisper, text})
  end

  @doc "Heals the hero."
  def heal(hero_name, amount \\ nil) do
    GenServer.cast(via_tuple(hero_name), {:heal, amount})
  end

  @doc "Blesses the hero with a random positive effect."
  def bless(hero_name) do
    GenServer.cast(via_tuple(hero_name), :bless)
  end

  @doc "Sends a valuable item to the hero."
  def send_loot(hero_name) do
    GenServer.cast(via_tuple(hero_name), :send_loot)
  end

  @doc "Strikes with lightning."
  def lightning(hero_name) do
    GenServer.cast(via_tuple(hero_name), :lightning)
  end

  @doc "Instills fear in the hero."
  def fear(hero_name) do
    GenServer.cast(via_tuple(hero_name), :fear)
  end

  @doc "Punishes the hero."
  def punish(hero_name) do
    GenServer.cast(via_tuple(hero_name), :punish)
  end

  @doc "Heals an injured body part."
  def heal_injury(hero_name, part) do
    GenServer.cast(via_tuple(hero_name), {:heal_injury, part})
  end

  @doc "Divine Intervention: resurrects from Sovngarde."
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

  @doc "Uses a healing potion from inventory."
  def use_potion_heal(hero_name, potion_name) do
    GenServer.cast(via_tuple(hero_name), {:use_potion_heal, potion_name})
  end

  @doc "Uses a buff potion from inventory."
  def use_potion_buff(hero_name, potion_name) do
    GenServer.cast(via_tuple(hero_name), {:use_potion_buff, potion_name})
  end

  @doc "Uses a lockpick from inventory."
  def use_lockpick(hero_name, lockpick_name) do
    GenServer.cast(via_tuple(hero_name), {:use_lockpick, lockpick_name})
  end

  @doc "Donates gold to the temple."
  def donate(hero_name, amount) do
    GenServer.cast(via_tuple(hero_name), {:donate, amount})
  end

  # --- Debug API ---

  @doc "Pauses hero AI tick during an arena fight. Saves status to restore after."
  def pause_for_arena(hero_name) do
    GenServer.cast(via_tuple(hero_name), :pause_for_arena)
  end

  @doc "Resumes hero AI after arena fight ends."
  def resume_from_arena(hero_name) do
    GenServer.cast(via_tuple(hero_name), :resume_from_arena)
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

  def set_tick_profile(hero_name, profile) do
    GenServer.cast(via_tuple(hero_name), {:set_tick_profile, profile})
  end

  def get_tick_profile(hero_name) do
    GenServer.call(via_tuple(hero_name), :get_tick_profile)
  end

  # --- Server Callbacks ---

  @impl true
  def init(opts) do
    state =
      if id = opts[:id] do
        Persistence.load_from_db(id)
      else
        initialize_new_hero(opts)
      end

    schedule_tick()
    schedule_save()

    Logger.info(
      "[Hero] Character '#{state.name}' (LVL #{state.level}) initialized. Status: #{state.status}"
    )

    {:ok, StateMachine.add_to_log(state, "Пронулся в таверне. Пора за работу!")}
  end

  @impl true
  def handle_info(:tick, %{status: :arena_paused} = state) do
    # Hero is in arena — skip AI tick, just reschedule
    schedule_tick()
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = StateMachine.tick(state)
    broadcast_update(new_state)
    interval = calculate_tick_interval(new_state)
    schedule_tick(interval)
    {:noreply, new_state}
  end

  defp calculate_tick_interval(state) do
    profile = Map.get(state, :tick_profile, TickProfile.default_profile())
    TickProfile.get_interval(profile, state.status)
  end

  @impl true
  def handle_info(:save, state) do
    Persistence.save_to_db(state)
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

    state = StateMachine.add_to_log(state, phrasing)
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
      |> Map.put(:intervention_power, max(0, state.intervention_power - 5))
      |> StateMachine.add_to_log("Небеса дрогнули. Шепот летит...")

    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:heal, amount}, state) do
    state = God.heal(state, amount)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:bless, state) do
    state = God.bless(state)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:send_loot, state) do
    state = God.send_loot(state)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:lightning, state) do
    state = God.lightning(state)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:fear, state) do
    state = God.fear(state)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:punish, state) do
    state = God.punish(state)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:heal_injury, part}, state) do
    state = God.heal_injury(state, part)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:divine_intervention, state) do
    state = God.divine_intervention(state)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:equip, item_name, slot}, state) do
    state = Actions.equip(state, item_name, slot)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:unequip, slot}, state) do
    state = Actions.unequip(state, slot)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:use_potion_heal, potion_name}, state) do
    state = Actions.use_potion_heal(state, potion_name)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:use_potion_buff, potion_name}, state) do
    state = Actions.use_potion_buff(state, potion_name)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:use_lockpick, lockpick_name}, state) do
    state = Actions.use_lockpick(state, lockpick_name)
    broadcast_update(state)
    {:noreply, state}
  end

  def handle_cast({:donate, amount}, state) when amount > 0 do
    if state.gold >= amount do
      {new_temple, progress} = GodvilleSk.Game.TempleMechanics.donate(state.temple, amount)

      state = Map.put(state, :gold, state.gold - amount)
      state = Map.put(state, :temple, new_temple)

      message =
        if progress >= 100 do
          "Храм Даэдра построен! Теперь он приносит полные бонусы!"
        else
          "Пожертвование принято. Храм: #{progress}%"
        end

      state = StateMachine.add_to_log(state, message)
      broadcast_update(state)
      {:noreply, state}
    else
      state = StateMachine.add_to_log(state, "Недостаточно золота для пожертвования!")
      broadcast_update(state)
      {:noreply, state}
    end
  end

  def handle_cast({:donate, _}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:debug_update, updates}, state) do
    state = Actions.debug_update(state, updates)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:debug_force_tick, state) do
    _ = Actions.debug_force_tick(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:debug_add_inventory, item}, state) do
    state = Actions.debug_add_inventory(state, item)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:debug_remove_inventory, item}, state) do
    state = Actions.debug_remove_inventory(state, item)
    broadcast_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:pause_for_arena, state) do
    # Save current status so we can restore it after arena
    paused_state =
      state
      |> Map.put(:pre_arena_status, state.status)
      |> Map.put(:status, :arena_paused)

    broadcast_update(paused_state)
    {:noreply, paused_state}
  end

  @impl true
  def handle_cast(:resume_from_arena, state) do
    restored_status = Map.get(state, :pre_arena_status, :idle)

    resumed_state =
      state
      |> Map.put(:status, restored_status)
      |> Map.put(:pre_arena_status, nil)
      |> StateMachine.add_to_log("Бой на арене завершён. Продолжаю обычные дела.")

    broadcast_update(resumed_state)
    {:noreply, resumed_state}
  end

  @impl true
  def handle_cast({:set_tick_profile, profile}, state) do
    if TickProfile.get_profile(profile) do
      new_state = Map.put(state, :tick_profile, profile)
      Logger.info("[Hero] Tick profile changed to #{profile}")
      broadcast_update(new_state)
      {:noreply, new_state}
    else
      Logger.warn("[Hero] Unknown tick profile: #{profile}")
      {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_tick_profile, _from, state) do
    profile = Map.get(state, :tick_profile, TickProfile.default_profile())
    {:reply, profile, state}
  end

  # --- Helpers ---

  defp via_tuple(name), do: {:global, {:hero, name}}

  defp schedule_tick(interval \\ @tick_interval), do: Process.send_after(self(), :tick, interval)
  defp schedule_save, do: Process.send_after(self(), :save, @save_interval)

  defp broadcast_update(state) do
    if state.id do
      Phoenix.PubSub.broadcast(GodvilleSk.PubSub, "hero:#{state.id}", {:hero_update, state})
    end
  end

  defp initialize_new_hero(opts) do
    %__MODULE__{
      name: opts[:name],
      race: opts[:race] || "Nord",
      class: opts[:class] || "Adventurer",
      perks: opts[:perks] || [],
      log: [],
      battle_log: []
    }
  end
end
