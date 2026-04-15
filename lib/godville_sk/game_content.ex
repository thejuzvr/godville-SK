defmodule GodvilleSk.GameContent do
  @moduledoc """
  Hybrid source for game content:
  DB entries from admin panel first, static `GameData` fallback second.
  """

  import Ecto.Query, warn: false

  alias GodvilleSk.Game.ContentEntry
  alias GodvilleSk.GameData
  alias GodvilleSk.Repo

  def get_random_monster(hero_level) do
    monsters = list_payloads("monster")

    case monsters do
      [] ->
        GameData.get_random_monster(hero_level)

      db_monsters ->
        min_level = max(1, hero_level - 2)

        suitable =
          Enum.filter(db_monsters, fn m -> m[:level] >= min_level and m[:level] <= hero_level end)

        monster =
          if Enum.empty?(suitable) do
            max_level = db_monsters |> Enum.map(& &1[:level]) |> Enum.max()
            db_monsters |> Enum.filter(&(&1[:level] == max_level)) |> Enum.random()
          else
            Enum.random(suitable)
          end

        normalize_monster(monster)
    end
  end

  defp normalize_monster(m) when is_map(m) do
    hp = m[:hp] || 10

    %{
      id: m[:id] || "unknown",
      name: m[:name] || "Неизвестный",
      hp: hp,
      max_hp: m[:max_hp] || hp,
      damage: m[:damage] || 1,
      xp: m[:xp] || 10,
      level: m[:level] || 1,
      ac: m[:ac] || 10
    }
  end

  def get_random_loot(hero_level) do
    items = list_payloads("item")

    case items do
      [] ->
        GameData.get_random_loot(hero_level)

      db_items ->
        rarity =
          cond do
            hero_level >= 10 -> Enum.random([:uncommon, :uncommon, :rare, :rare])
            hero_level >= 5 -> Enum.random([:common, :uncommon, :uncommon, :rare])
            true -> Enum.random([:common, :common, :uncommon])
          end

        suitable = Enum.filter(db_items, fn item -> item[:rarity] == rarity end)
        item = if(Enum.empty?(suitable), do: db_items, else: suitable) |> Enum.random()
        item[:name]
    end
  end

  def get_location do
    case list_payloads("location") do
      [] -> GameData.get_location()
      locations -> locations |> Enum.map(& &1[:name]) |> Enum.random()
    end
  end

  def thoughts do
    case list_payloads("thought") do
      [] -> GameData.thoughts()
      values -> Enum.map(values, & &1[:text])
    end
  end

  def context_thought(location, level) do
    case list_payloads("thought") do
      [] -> GameData.get_context_thought(location, level)
      values -> Enum.random(Enum.map(values, & &1[:text]))
    end
  end

  def random_events do
    case list_payloads("random_event") do
      [] ->
        GameData.random_events()

      values ->
        Enum.map(values, fn event ->
          %{msg: event[:msg], effect: normalize_effect(event[:effect])}
        end)
    end
  end

  def quests do
    case list_payloads("quest") do
      [] -> GameData.quests()
      values -> values
    end
  end

  def sovngarde_tasks do
    case list_payloads("sovngarde_task") do
      [] -> GameData.sovngarde_tasks()
      values -> values
    end
  end

  def sovngarde_thoughts do
    case list_payloads("sovngarde_thought") do
      [] -> GameData.sovngarde_thoughts()
      values -> Enum.map(values, & &1[:text])
    end
  end

  def location_type(location_name) do
    GameData.location_type(location_name)
  end

  def is_city?(location_name) do
    GameData.is_city?(location_name)
  end

  def tavern_rumors do
    GameData.tavern_rumors()
  end

  def night_events do
    GameData.night_events()
  end

  def dungeons do
    GameData.dungeons()
  end

  def dungeon_room_events do
    GameData.dungeon_room_events()
  end

  def get_random_dungeon_room_event do
    GameData.get_random_dungeon_room_event()
  end

  def quests_by_type(type) do
    GameData.quests_by_type(type)
  end

  def list_locations_admin do
    ContentEntry
    |> where([e], e.kind == "location" and e.active == true)
    |> order_by([e], asc: e.key)
    |> Repo.all()
  end

  def create_location(name) when is_binary(name) do
    trimmed = String.trim(name)

    if trimmed == "" do
      {:error, :empty_name}
    else
      %ContentEntry{}
      |> ContentEntry.changeset(%{
        kind: "location",
        key: slugify_key(trimmed),
        payload: %{"name" => trimmed},
        active: true
      })
      |> Repo.insert()
    end
  end

  def delete_location(id) do
    case Repo.get(ContentEntry, id) do
      nil -> {:error, :not_found}
      entry -> Repo.delete(entry)
    end
  end

  defp list_payloads(kind) do
    ContentEntry
    |> where([e], e.kind == ^kind and e.active == true)
    |> select([e], e.payload)
    |> Repo.all()
    |> Enum.map(&normalize_map/1)
  end

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {normalize_key(k), normalize_map(v)}
      {k, v} -> {k, normalize_map(v)}
    end)
  end

  defp normalize_map(value) when is_list(value), do: Enum.map(value, &normalize_map/1)
  defp normalize_map(value), do: value

  defp normalize_effect(effect) when is_atom(effect), do: effect
  defp normalize_effect("heal"), do: :heal
  defp normalize_effect("none"), do: :none
  defp normalize_effect(_), do: :none

  defp normalize_key(key) do
    case key do
      "id" -> :id
      "name" -> :name
      "hp" -> :hp
      "max_hp" -> :max_hp
      "damage" -> :damage
      "xp" -> :xp
      "level" -> :level
      "ac" -> :ac
      "type" -> :type
      "rarity" -> :rarity
      "description" -> :description
      "slot" -> :slot
      "armor" -> :armor
      "steps" -> :steps
      "reward" -> :reward
      "text" -> :text
      "msg" -> :msg
      "effect" -> :effect
      "title" -> :title
      _ -> key
    end
  end

  defp slugify_key(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "_")
    |> String.trim("_")
    |> case do
      "" -> "location_#{System.unique_integer([:positive])}"
      key -> key
    end
  end
end
