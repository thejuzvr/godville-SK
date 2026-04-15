defmodule GodvilleSk.Hero.Persistence do
  @moduledoc """
  Database persistence: loading hero state from DB and saving GenServer state back to DB.
  Handles conversion between Ecto schema (GodvilleSk.Game.Hero) and runtime state (GodvilleSk.Hero).
  """

  alias GodvilleSk.Game
  alias GodvilleSk.Game.Hero, as: HeroSchema
  alias GodvilleSk.Game.HeroLog
  alias GodvilleSk.{Repo, WorldClock}
  import Ecto.Query, warn: false

  @max_log_size 60

  @doc """
  Loads hero by ID from the database and converts to runtime state struct.
  Also loads recent hero logs.
  """
  def load_from_db(id) do
    hero = Repo.get!(HeroSchema, id)

    # Extract TES attributes from the attributes map
    attrs = hero.attributes || %{}

    # Load recent logs
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

    # Build runtime state
    %GodvilleSk.Hero{
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
      # TES attributes from attributes blob
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
      inventory: hero.attributes["inventory"] || [],
      inventory_capacity: 50,
      location: hero.location || "Балмора",
      tavern_drink_count: hero.tavern_drink_count || 0,
      status: parse_status(hero.status),
      target: normalize_keys(hero.attributes["target"]),
      quest_progress: hero.quest_progress || 0,
      turn: if(t = hero.attributes["turn"], do: String.to_atom(t), else: :hero),
      # Embedded structures (now separate fields or embedded schemas)
      equipment: normalize_equipment(hero.equipment),
      statistics: normalize_statistics(hero.statistics),
      temple: normalize_temple(hero.temple),
      # New normalized columns
      stamina: hero.stamina || 100,
      stamina_max: hero.stamina_max || 100,
      luck_modifier: hero.luck_modifier || 0,
      respawn_at: parse_datetime(hero.respawn_at),
      # Combat stats
      ac: 14,
      # Log
      log: logs,
      # Last action tracking
      last_action: parse_last_action(hero.attributes["last_action"])
    }
  end

  @doc """
  Saves runtime hero state back to the database.
  """
  def save_to_db(state) do
    if state.id do
      hero = Repo.get(HeroSchema, state.id)

      # Prepare attributes map (TES stats only)
      attrs = %{
        "strength" => state.strength,
        "intelligence" => state.intelligence,
        "willpower" => state.willpower,
        "agility" => state.agility,
        "speed" => state.speed,
        "endurance" => state.endurance,
        "personality" => state.personality,
        "luck" => state.luck,
        # Additional dynamic state we keep in attributes for backwards compatibility or flexibility
        "inventory" => state.inventory,
        "target" => state.target,
        "turn" => Atom.to_string(state.turn),
        "status" => Atom.to_string(state.status),
        "respawn_at" =>
          if(state.respawn_at, do: DateTime.to_iso8601(state.respawn_at), else: nil),
        "quest_progress" => state.quest_progress,
        "location" => state.location,
        "last_action" => if(state.last_action, do: Atom.to_string(state.last_action), else: nil)
      }

      Game.update_hero(hero, %{
        gold: state.gold,
        hp: state.hp,
        level: state.level,
        exp: state.xp,
        intervention_power: state.intervention_power,
        stamina: state.stamina,
        stamina_max: state.stamina_max,
        luck_modifier: state.luck_modifier,
        status: Atom.to_string(state.status),
        inventory: state.inventory,
        location: state.location,
        tavern_drink_count: state.tavern_drink_count,
        quest_progress: state.quest_progress,
        turn: Atom.to_string(state.turn),
        respawn_at: state.respawn_at,
        equipment: serialize_equipment(state.equipment),
        statistics: serialize_statistics(state.statistics),
        temple: serialize_temple(state.temple),
        attributes: attrs
      })
    end
  end

  # --- Parsing ---

  defp parse_status(nil), do: :idle
  defp parse_status(status) when is_binary(status), do: String.to_atom(status)
  defp parse_status(_), do: :idle

  defp parse_last_action(nil), do: nil
  defp parse_last_action(action) when is_binary(action), do: String.to_atom(action)
  defp parse_last_action(_), do: nil

  defp parse_datetime(nil), do: nil

  defp parse_datetime(iso) when is_binary(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_datetime(_), do: nil

  defp normalize_keys(nil), do: nil

  defp normalize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), normalize_keys(v)}
      {k, v} -> {k, v}
    end)
  end

  defp normalize_keys(list) when is_list(list), do: Enum.map(list, &normalize_keys/1)
  defp normalize_keys(val), do: val

  defp normalize_equipment(nil), do: GodvilleSk.Game.HeroEquipment.default()
  defp normalize_equipment(%GodvilleSk.Game.HeroEquipment{} = eq), do: eq
  defp normalize_equipment(map) when is_map(map), do: struct(GodvilleSk.Game.HeroEquipment, map)

  defp normalize_statistics(nil), do: GodvilleSk.Game.HeroStatistics.default()
  defp normalize_statistics(%GodvilleSk.Game.HeroStatistics{} = stats), do: stats

  defp normalize_statistics(map) when is_map(map),
    do: struct(GodvilleSk.Game.HeroStatistics, map)

  defp normalize_temple(nil), do: GodvilleSk.Game.HeroTemple.default()
  defp normalize_temple(%GodvilleSk.Game.HeroTemple{} = temple), do: temple
  defp normalize_temple(map) when is_map(map), do: struct(GodvilleSk.Game.HeroTemple, map)

  defp serialize_equipment(%GodvilleSk.Game.HeroEquipment{} = eq), do: Map.from_struct(eq)
  defp serialize_equipment(other), do: other

  defp serialize_statistics(%GodvilleSk.Game.HeroStatistics{} = stats), do: Map.from_struct(stats)
  defp serialize_statistics(other), do: other

  defp serialize_temple(%GodvilleSk.Game.HeroTemple{} = temple), do: Map.from_struct(temple)
  defp serialize_temple(other), do: other

  defp log_entry_from_schema(%HeroLog{} = log) do
    %{
      id: log.id,
      message: log.message,
      metadata: log.metadata || %{},
      inserted_at: log.inserted_at,
      game_time: log.game_time || WorldClock.game_time_at(log.inserted_at)
    }
  end

  @doc """
  Fetches just the hero's name by ID. Used during start_link when only id is provided.
  """
  def fetch_name_from_db(id) do
    case Repo.get(HeroSchema, id) do
      %{name: name} -> name
      nil -> nil
    end
  end
end
