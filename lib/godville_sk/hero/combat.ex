defmodule GodvilleSk.Hero.Combat do
  @moduledoc """
  Combat logic: initiative, combat rounds, attacks, and victory handling.
  All functions are pure and take/return hero state.
  """

  alias GodvilleSk.GameContent
  alias GodvilleSk.Game.Items
  alias GodvilleSk.Hero.{Mechanics, Brain, BodyParts}
  alias GodvilleSk.{Repo, WorldClock}
  alias GodvilleSk.Game.{LogMetadata, HeroLog}

  @doc """
  Handles combat initiative phase. Rolls initiative and transitions to combat_round.
  """
  def do_combat_initiative(state) do
    hero_mod = Mechanics.modifier(state.agility)
    enemy_mod = Mechanics.modifier(state.target.level * 5 + 50)

    hero_roll = :rand.uniform(20)
    enemy_roll = :rand.uniform(20)

    hero_total = hero_roll + hero_mod
    enemy_total = enemy_roll + enemy_mod

    first_turn = if hero_total >= enemy_total, do: :hero, else: :enemy

    state =
      add_to_log(
        state,
        "Бросок инициативы! Герой: #{hero_total} (#{hero_roll}+#{hero_mod}), #{state.target.name}: #{enemy_total} (#{enemy_roll}+#{enemy_mod})",
        %{
          type: "initiative_roll",
          hero_roll: hero_roll,
          enemy_roll: enemy_roll,
          turn: first_turn
        }
      )

    state
    |> Map.put(:status, :combat_round)
    |> Map.put(:turn, first_turn)
    |> Map.put(:battle_log, [])
  end

  @doc """
  Handles one combat round. Alternates turns between hero and enemy.
  """
  def do_combat_round(state) do
    if state.turn == :hero do
      do_hero_attack(state)
    else
      do_enemy_attack(state)
    end
  end

  defp do_hero_attack(state) do
    {is_hit, damage, total, roll, log_msg} = Mechanics.perform_attack(state, state.target)

    new_target_hp = state.target.hp - damage
    updated_target = Map.put(state.target, :hp, new_target_hp)

    state =
      add_to_log(state, log_msg, %{
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
  end

  defp do_enemy_attack(state) do
    {is_hit, damage, total, roll, log_msg} = Mechanics.perform_enemy_attack(state.target, state)

    new_hero_hp = state.hp - damage
    hp_ratio = new_hero_hp / state.max_hp

    state =
      add_to_log(state, log_msg, %{
        type: "combat_roll",
        actor: "enemy",
        target: state.name,
        roll: roll,
        total: total,
        damage: damage,
        is_hit: is_hit
      })

    state = maybe_apply_injury(state, hp_ratio, damage)

    if new_hero_hp <= 0 do
      handle_defeat(state)
    else
      state
      |> Map.put(:hp, new_hero_hp)
      |> Map.put(:turn, :hero)
    end
  end

  defp maybe_apply_injury(state, hp_ratio, damage) do
    cond do
      damage >= 20 and hp_ratio < 0.3 ->
        case BodyParts.random_limb_loss?(state.level, hp_ratio) do
          {:loss, part} ->
            body_parts = BodyParts.apply_loss(state.body_parts, part)
            permanent_injuries = state.permanent_injuries + 1
            body_desc = BodyParts.describe_state(body_parts)

            state
            |> Map.put(:body_parts, body_parts)
            |> Map.put(:permanent_injuries, permanent_injuries)
            |> add_to_log(
              "КРИТИЧЕСКОЕ ПОРАЖЕНИЕ! Потеряна #{part_to_russian(part)}! #{body_desc}",
              %{
                type: "limb_loss",
                part: part
              }
            )

          nil ->
            maybe_add_injury(state, hp_ratio)
        end

      true ->
        maybe_add_injury(state, hp_ratio)
    end
  end

  defp maybe_add_injury(state, hp_ratio) do
    case BodyParts.random_injury(state.level) do
      {:injury, part} ->
        body_parts = BodyParts.apply_injury(state.body_parts, part)
        permanent_injuries = state.permanent_injuries + 1

        state
        |> Map.put(:body_parts, body_parts)
        |> Map.put(:permanent_injuries, permanent_injuries)
        |> add_to_log("Получена травма: #{part_to_russian(part)}!", %{
          type: "injury",
          part: part
        })

      nil ->
        state
    end
  end

  defp part_to_russian(:left_arm), do: "левая рука"
  defp part_to_russian(:right_arm), do: "правая рука"
  defp part_to_russian(:left_leg), do: "левая нога"
  defp part_to_russian(:right_leg), do: "правая нога"
  defp part_to_russian(:head), do: "голова"

  @doc """
  Handles victory over the target. Awards XP, gold, loot and updates statistics.
  """
  def handle_victory(state, target) do
    new_xp = state.xp + target.level * 5
    item_struct = Items.random_item(state.level)
    item_name = Items.to_string(item_struct)
    new_inventory = [item_struct.name | state.inventory]

    state = Brain.process_combat_outcome(state, :victory, target)

    state
    |> Map.put(:status, :idle)
    |> Map.put(:target, nil)
    |> Map.put(:gold, state.gold + state.level * 5)
    |> Map.put(:xp, new_xp)
    |> Map.put(:inventory, new_inventory)
    |> Map.put(
      :statistics,
      %{state.statistics | total_wins: state.statistics.total_wins + 1}
    )
    |> add_to_log("Победа над #{target.name}! Получен предмет: #{item_name}")
  end

  @doc """
  Handles hero defeat (HP <= 0). Transitions to Sovngarde afterlife.
  """
  def handle_defeat(state) do
    duration_mins = Enum.random(10..20)
    respawn_at = DateTime.add(DateTime.utc_now(), duration_mins, :minute)

    target = state.target
    state = Brain.process_combat_outcome(state, :defeat, target)

    state
    |> add_to_log(
      "Дух покидает тело... Отправление в Совнгаре на #{duration_mins} мин. (-100 золота, эффект: Ослабленность -2)",
      %{
        type: "death",
        duration_minutes: duration_mins
      }
    )
    |> Map.put(:hp, 0)
    |> Map.put(:status, :sovngarde)
    |> Map.put(:location, "Совнгард")
    |> Map.put(:target, nil)
    |> Map.put(:gold, max(0, state.gold - 100))
    |> Map.put(:luck_modifier, -2)
    |> Map.put(:respawn_at, respawn_at)
    |> Map.put(
      :statistics,
      %{state.statistics | total_deaths: state.statistics.total_deaths + 1}
    )
  end

  # Private log helpers

  defp add_to_log(state, msg, metadata \\ %{}) do
    context = if state.status == :sovngarde, do: :sovngarde, else: :normal
    metadata_type = metadata[:type]

    {context_to_use, is_combat_roll} =
      if metadata_type in ["combat_roll", "initiative_roll"] do
        {:battle_keeper, true}
      else
        {context, false}
      end

    case LogMetadata.validate(metadata, context_to_use) do
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
        state = Map.put(state, :log, new_log)

        if is_combat_roll do
          new_battle_log = [entry | state.battle_log] |> Enum.take(60)
          Map.put(state, :battle_log, new_battle_log)
        else
          state
        end

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
end
