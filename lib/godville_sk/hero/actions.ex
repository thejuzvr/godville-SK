defmodule GodvilleSk.Hero.Actions do
  @moduledoc """
  Hero actions triggered by divine intervention, equipment changes, and debug operations.
  All functions are pure state transformations.
  """

  alias GodvilleSk.GameContent
  alias GodvilleSk.Game.Items
  alias GodvilleSk.{Repo, WorldClock}
  alias GodvilleSk.Game.{LogMetadata, HeroLog}

  @doc """
  Blesses the hero. Random effect: heal, gold, loot, or thanks.
  """
  def bless(state) do
    {state, msg} =
      case Enum.random([:heal, :gold, :loot, :thanks]) do
        :heal ->
          amount = Enum.random(10..30)
          new_hp = min(state.hp + amount, state.max_hp)

          {Map.put(state, :hp, new_hp),
           "Тепло коснулось плеча. Раны затянулись (+#{new_hp - state.hp} HP)."}

        :gold ->
          amount = Enum.random(15..60)

          {Map.put(state, :gold, state.gold + amount),
           "У ног звякнул мешочек — #{amount} золотых. Благословение принято."}

        :loot ->
          item_struct = Items.random_item(state.level)
          item_name = Items.to_string(item_struct)
          inv = [item_struct.name | state.inventory] |> Enum.take(state.inventory_capacity)
          {Map.put(state, :inventory, inv), "С неба упал дар: #{item_name}."}

        :thanks ->
          {state, "Небеса молчали, но стало спокойнее. Я тихо поблагодарил."}
      end

    state
    |> Map.put(:intervention_power, max(0, state.intervention_power - 50))
    |> add_to_log("[Благословение] " <> msg)
  end

  @doc """
  Punishes the hero or their foe in combat.
  """
  def punish(state) do
    {state, msg} =
      cond do
        state.status == :combat and is_map(state.target) ->
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

            {Map.put(state, :hp, new_hp),
             "Рядом со мной ударила молния… не стоит злить богов (-#{dmg} HP)."}
          end

        true ->
          if :rand.uniform() < 0.9 do
            dmg = Enum.random(3..12)
            new_hp = max(0, state.hp - dmg)

            {Map.put(state, :hp, new_hp),
             "Знак был недвусмысленным. Я споткнулся и ушибся (-#{dmg} HP)."}
          else
            dmg = Enum.random(15..35)
            new_hp = max(0, state.hp - dmg)

            {Map.put(state, :hp, new_hp),
             "Небеса разгневались. Меня будто придавило невидимой силой (-#{dmg} HP)."}
          end
      end

    state
    |> Map.put(:intervention_power, max(0, state.intervention_power - 50))
    |> add_to_log("[Наказание] " <> msg)
  end

  @doc """
  Divine Intervention: resurrects from Sovngarde if power is sufficient.
  """
  def divine_intervention(state) do
    if state.status == :sovngarde and state.intervention_power >= 100 do
      state
      |> add_to_log(
        "[БОЖЕСТВЕННОЕ ВМЕШАТЕЛЬСТВО] Небеса раскрылись, и властный голос вернул мою душу в мир живых! Я воскрес!",
        %{
          type: "resurrection"
        }
      )
      |> Map.put(:status, :idle)
      |> Map.put(:respawn_at, nil)
      |> Map.put(:hp, state.max_hp)
      |> Map.put(:intervention_power, 0)
      |> Map.put(:location, GameContent.get_location())
    else
      state
    end
  end

  @doc """
  Equips an item from inventory into a slot, swapping with old item if present.
  """
  def equip(state, item_name, slot) do
    if Enum.member?(state.inventory, item_name) do
      old_item = Map.get(state.equipment, slot)

      inventory = List.delete(state.inventory, item_name)
      inventory = if old_item, do: [old_item | inventory], else: inventory

      equipment = Map.put(state.equipment, slot, item_name)

      state
      |> Map.put(:inventory, inventory)
      |> Map.put(:equipment, equipment)
      |> add_to_log("Экипировал: #{item_name} в слот #{slot}")
    else
      state
    end
  end

  @doc """
  Unequips an item from a slot, returning it to inventory.
  """
  def unequip(state, slot) do
    item = Map.get(state.equipment, slot)

    if item do
      equipment = Map.put(state.equipment, slot, nil)
      inventory = [item | state.inventory] |> Enum.take(state.inventory_capacity)

      state
      |> Map.put(:inventory, inventory)
      |> Map.put(:equipment, equipment)
      |> add_to_log("Снял предмет: #{item}")
    else
      state
    end
  end

  # --- Debug actions ---

  def debug_update(state, updates) do
    Map.merge(state, updates)
  end

  def debug_force_tick(state) do
    send(self(), :tick)
    state
  end

  def debug_add_inventory(state, item) do
    new_inventory = [item | state.inventory] |> Enum.take(state.inventory_capacity)
    Map.put(state, :inventory, new_inventory)
  end

  def debug_remove_inventory(state, item) do
    new_inventory = List.delete(state.inventory, item)
    Map.put(state, :inventory, new_inventory)
  end

  # --- Helpers ---

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

        new_log = [entry | state.log] |> Enum.take(60)
        Map.put(state, :log, new_log)

      {:error, reason} ->
        require Logger
        Logger.error("[Hero] Invalid metadata for log entry: #{inspect(reason)}. Message: #{msg}")
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

  # --- Item Usage ---

  @doc """
  Uses a healing potion from hero's inventory.
  """
  def use_potion_heal(state, potion_name) do
    alias GodvilleSk.Hero.Items

    {result, msg} =
      case Items.use_potion_heal(state, potion_name) do
        {:ok, new_state, amount_healed} ->
          {:ok, new_state, "Выпил #{potion_name}. Раны зажили! (+#{amount_healed} HP)"}

        {:error, :not_found} ->
          {:error, state, "У меня нет #{potion_name}. Кажется, я где-то забыл её..."}

        {:error, :not_potion} ->
          {:error, state, "#{potion_name} — это не зелье лечения. Не буду пить такое."}
      end

    case result do
      :ok -> add_to_log(msg, msg, %{type: "potion_used", potion: potion_name})
      :error -> add_to_log(msg, msg)
    end
  end

  @doc """
  Uses a buff potion from hero's inventory.
  """
  def use_potion_buff(state, potion_name) do
    alias GodvilleSk.Hero.Items

    {result, msg} =
      case Items.use_potion_buff(state, potion_name) do
        {:ok, new_state, duration, effect, value} ->
          effect_name = translate_effect(effect)
          {:ok, new_state, "Выпил #{potion_name}! #{effect_name} +#{value} на #{duration} тиков."}

        {:error, :not_found} ->
          {:error, state, "#{potion_name} не нашлось. Пропащь."}

        {:error, :not_potion} ->
          {:error, state, "Что-то #{potion_name} выглядит подозрительно... Не буду."}
      end

    case result do
      :ok -> add_to_log(msg, msg, %{type: "potion_used", potion: potion_name})
      :error -> add_to_log(msg, msg)
    end
  end

  @doc """
  Uses a lockpick from hero's inventory.
  """
  def use_lockpick(state, lockpick_name) do
    alias GodvilleSk.Hero.Items

    {result, msg} =
      case Items.use_lockpick(state, lockpick_name) do
        {:ok, new_state, quality} ->
          {:ok, new_state, "Использовал #{lockpick_name} (качество: #{quality})"}

        {:error, :not_found} ->
          {:error, state, "Отмычек не осталось. Запертые двери — проблема."}

        {:error, :not_lockpick} ->
          {:error, state, "Это не отмычка. Что я вообще держу в руках?"}
      end

    case result do
      :ok -> add_to_log(msg, msg, %{type: "lockpick_used", lockpick: lockpick_name})
      :error -> add_to_log(msg, msg)
    end
  end

  defp translate_effect(:strength), do: "Сила"
  defp translate_effect(:agility), do: "Ловкость"
  defp translate_effect(:speed), do: "Скорость"
  defp translate_effect(:luck), do: "Удача"
  defp translate_effect(:endurance), do: "Выносливость"
  defp translate_effect(:intelligence), do: "Интеллект"
  defp translate_effect(:willpower), do: "Воля"
  defp translate_effect(:personality), do: "Обаяние"
  defp translate_effect(_), do: "Неизвестный эффект"
end
