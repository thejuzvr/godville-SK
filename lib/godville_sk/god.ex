defmodule GodvilleSk.God do
  @moduledoc """
  God interventions - actions a player can take to influence their hero.
  Each intervention costs prana (divine power).
  """

  alias GodvilleSk.Game.Items
  alias GodvilleSk.{Repo, WorldClock}
  alias GodvilleSk.Game.LogMetadata
  alias GodvilleSk.Hero.Brain

  @prana_costs %{
    heal: 10,
    bless: 20,
    send_loot: 15,
    lightning: 5,
    fear: 8,
    punish: 12,
    whisper: 5,
    divine_intervention: 100
  }

  def prana_costs, do: @prana_costs

  @doc """
  Heals the hero by a specified amount.
  """
  def heal(state, amount \\ nil) do
    heal_amount = amount || Enum.random(15..35)
    new_hp = min(state.hp + heal_amount, state.max_hp)
    actual_heal = new_hp - state.hp

    state
    |> Map.put(:hp, new_hp)
    |> Map.put(:intervention_power, max(0, state.intervention_power - @prana_costs.heal))
    |> add_log("[Божественное исцеление] Тепло разлилось по телу... (+#{actual_heal} HP)")
  end

  @doc """
  Blesses the hero with a random positive effect.
  """
  def bless(state) do
    {state, msg} =
      case Enum.random([:heal, :gold, :loot, :strength_buff, :thanks]) do
        :heal ->
          amount = Enum.random(20..40)
          new_hp = min(state.hp + amount, state.max_hp)
          actual = new_hp - state.hp

          {Map.put(state, :hp, new_hp),
           "Божественное тепло окутало тело. Раны затянулись (+#{actual} HP)."}

        :gold ->
          amount = Enum.random(30..100)

          {Map.put(state, :gold, state.gold + amount),
           "Золотые монеты с небес! #{amount} золотых received."}

        :loot ->
          item = Items.random_item(state.level)
          inv = [item.name | state.inventory] |> Enum.take(state.inventory_capacity)
          {Map.put(state, :inventory, inv), "Дар с небес: #{item.name}!"}

        :strength_buff ->
          {Map.put(state, :strength, state.strength + 5),
           "Божественная сила наполнила мышцы! (+5 Сила)"}

        :thanks ->
          {state, "Небеса молчали, но стало спокойнее на душе."}
      end

    state
    |> Map.put(:intervention_power, max(0, state.intervention_power - @prana_costs.bless))
    |> add_log("[Благословение] " <> msg)
  end

  @doc """
  Sends a valuable item directly to hero's inventory.
  """
  def send_loot(state) do
    item = Items.random_item(state.level + 1)
    inv = [item.name | state.inventory] |> Enum.take(state.inventory_capacity)

    state
    |> Map.put(:inventory, inv)
    |> Map.put(:intervention_power, max(0, state.intervention_power - @prana_costs.send_loot))
    |> add_log("[Божественный дар] С неба упал #{item.name}!")
  end

  @doc """
  Strikes the hero or their enemy with lightning.
  """
  def lightning(state) do
    {state, msg} =
      cond do
        state.status == :combat and is_map(state.target) ->
          if :rand.uniform() < 0.7 do
            dmg = Enum.random(15..30)
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

            {state, "Молния поразила врага! (-#{dmg} HP врага)"}
          else
            dmg = Enum.random(10..20)
            new_hp = max(0, state.hp - dmg)

            {Map.put(state, :hp, new_hp), "Молния ударила слишком близко! (-#{dmg} HP)"}
          end

        true ->
          dmg = Enum.random(8..25)
          new_hp = max(0, state.hp - dmg)

          {Map.put(state, :hp, new_hp), "Небеса вспыхнули! Меня ударила молния! (-#{dmg} HP)"}
      end

    state
    |> Map.put(:intervention_power, max(0, state.intervention_power - @prana_costs.lightning))
    |> add_log("[Молния] " <> msg)
  end

  @doc """
  Instills fear in the hero, causing them to flee or cower.
  """
  def fear(state) do
    phrases = [
      "Ужас охватил душу! Плохие предчувствия...",
      "Что-то темное шепчет в уши... Страх.",
      "Холод пробежал по спине. Бежать!",
      "Невидимая рука сжала сердце. Опасность!"
    ]

    state =
      if state.status == :combat do
        state
        |> Map.put(:status, :idle)
        |> Map.put(:target, nil)
        |> Brain.add_fear(:conditions, :god_fear, 3)
        |> add_log("[Страх] Герой обратился в бегство!")
      else
        state
        |> Brain.add_fear(:conditions, :god_fear, 2)
        |> add_log("[Страх] " <> Enum.random(phrases))
      end

    state
    |> Map.put(:intervention_power, max(0, state.intervention_power - @prana_costs.fear))
  end

  @doc """
  Punishes the hero with damage or debuff.
  """
  def punish(state) do
    {state, msg} =
      cond do
        state.status == :combat and is_map(state.target) ->
          if :rand.uniform() < 0.5 do
            dmg = Enum.random(20..35)
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

            {state, "Гнев небес обрушился на врага! (-#{dmg} HP)"}
          else
            dmg = Enum.random(15..30)
            new_hp = max(0, state.hp - dmg)

            {Map.put(state, :hp, new_hp), "Гнев небес! Меня задело... (-#{dmg} HP)"}
          end

        true ->
          if :rand.uniform() < 0.8 do
            dmg = Enum.random(10..25)
            new_hp = max(0, state.hp - dmg)

            {Map.put(state, :hp, new_hp), "Небеса разгневались. (-#{dmg} HP)"}
          else
            dmg = Enum.random(30..50)
            new_hp = max(0, state.hp - dmg)

            {Map.put(state, :hp, new_hp), "СУРОВЫЙ ГНЕВ БОЖИЙ! (-#{dmg} HP)"}
          end
      end

    state
    |> Map.put(:intervention_power, max(0, state.intervention_power - @prana_costs.punish))
    |> add_log("[Наказание] " <> msg)
  end

  @doc """
  Heals an injured body part (cannot heal lost limbs).
  """
  def heal_injury(state, part) do
    current = Map.get(state.body_parts, part, :healthy)

    case current do
      :healthy ->
        add_log(state, "[Исцеление] #{part_to_russian(part)} и так здорова.")

      :injured ->
        body_parts = GodvilleSk.Hero.BodyParts.heal_injury(state.body_parts, part)

        state
        |> Map.put(:body_parts, body_parts)
        |> Map.put(:intervention_power, max(0, state.intervention_power - 25))
        |> add_log("[Исцеление] #{part_to_russian(part)} полностью восстановлена!")

      :lost ->
        add_log(
          state,
          "[Исцеление] Ампутированную #{part_to_russian(part)} нельзя восстановить..."
        )
    end
  end

  @doc """
  Divine Intervention: resurrects from Sovngarde.
  """
  def divine_intervention(state) do
    if state.status == :sovngarde do
      new_location = GodvilleSk.GameContent.get_location()

      state
      |> add_log(
        "[БОЖЕСТВЕННОЕ ВМЕШАТЕЛЬСТВО] Небеса раскрылись! Голос вернул душу в мир живых!",
        %{type: "resurrection"}
      )
      |> Map.put(:status, :idle)
      |> Map.put(:respawn_at, nil)
      |> Map.put(:hp, state.max_hp)
      |> Map.put(:intervention_power, 0)
      |> Map.put(:location, new_location)
    else
      state
    end
  end

  @doc """
  Schedules a divine whisper to be delivered after a random delay.
  """
  def schedule_whisper(state, text) do
    delay_ms = Enum.random(10_000..90_000)
    Process.send_after(self(), {:deliver_whisper, text}, delay_ms)

    state
    |> Map.put(:intervention_power, max(0, state.intervention_power - @prana_costs.whisper))
    |> add_log("Небеса дрогнули. Шепот отправлен...")
  end

  @doc """
  Checks if the hero has enough prana for an intervention.
  """
  def can_intervene?(state, intervention) do
    cost = Map.get(@prana_costs, intervention, 0)
    state.intervention_power >= cost
  end

  @doc """
  Gets the cost of an intervention in prana.
  """
  def intervention_cost(intervention), do: Map.get(@prana_costs, intervention, 0)

  # --- Private Helpers ---

  defp add_log(state, msg, metadata \\ %{}) do
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
        Logger.error("[God] Invalid metadata: #{inspect(reason)}. Msg: #{msg}")
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

  defp part_to_russian(:left_arm), do: "левая рука"
  defp part_to_russian(:right_arm), do: "правая рука"
  defp part_to_russian(:left_leg), do: "левая нога"
  defp part_to_russian(:right_leg), do: "правая нога"
  defp part_to_russian(:head), do: "голова"
end
