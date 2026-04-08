defmodule GodvilleSk.GameData do
  @moduledoc """
  Статические данные игры, перенесенные из TypeScript репозитория.
  """

  @monsters [
    %{id: "wolf", name: "Волк", hp: 20, max_hp: 20, damage: 3, xp: 15, level: 1, ac: 11},
    %{id: "frost_spider", name: "Морозный паук", hp: 30, max_hp: 30, damage: 4, xp: 25, level: 2, ac: 12},
    %{id: "bandit", name: "Бандит", hp: 45, max_hp: 45, damage: 6, xp: 40, level: 3, ac: 13},
    %{id: "draugr", name: "Драугр", hp: 60, max_hp: 60, damage: 8, xp: 60, level: 4, ac: 14},
    %{id: "bear", name: "Медведь", hp: 80, max_hp: 80, damage: 12, xp: 90, level: 5, ac: 13},
    %{id: "troll", name: "Тролль", hp: 120, max_hp: 120, damage: 15, xp: 150, level: 7, ac: 14},
    %{id: "dragon", name: "Дракон", hp: 500, max_hp: 500, damage: 40, xp: 1000, level: 15, ac: 18}
  ]

  @items [
    %{id: "food_bread", name: "Хлеб", type: :food, rarity: :common},
    %{id: "food_cheese", name: "Козий сыр", type: :food, rarity: :common},
    %{id: "food_venison", name: "Жареная оленина", type: :food, rarity: :uncommon},
    %{id: "potion_health_weak", name: "Слабое зелье лечения", type: :potion, rarity: :common},
    %{id: "weapon_iron_sword", name: "Железный меч", type: :weapon, rarity: :common},
    %{id: "weapon_steel_sword", name: "Стальной меч", type: :weapon, rarity: :uncommon},
    %{id: "armor_leather", name: "Кожаная броня", type: :armor, rarity: :common},
    %{id: "gem_garnet", name: "Гранат", type: :gem, rarity: :uncommon},
    %{id: "gem_diamond", name: "Бриллиант", type: :gem, rarity: :rare}
  ]

  @quests [
    %{id: "bounty_bandits_whiterun", name: "Награда за бандитов", steps: 5, reward: 150, level: 3},
    %{id: "side_spriggan_whiterun", name: "Сердце сприггана", steps: 4, reward: 113, level: 4},
    %{id: "main_dragon_rising", name: "Дракон в небе", steps: 10, reward: 500, level: 10}
  ]

  @locations [
    "Солитьюд",
    "Виндхельм",
    "Вайтран",
    "Маркарт",
    "Рифтен",
    "Окрестности Вайтрана",
    "Окрестности Солитьюда",
    "Окрестности Виндхельма",
    "Окрестности Рифтена",
    "Окрестности Маркарта",
    "Данстар",
    "Винтерхолд",
    "Морфал",
    "Фолкрит"
  ]

  @thoughts [
    "Может, податься в наемники?",
    "Стрела в колено - это больно.",
    "Кто-то украл мой сладкий рулет...",
    "Скайрим для нордов!",
    "Холодно тут."
  ]

  @random_events [
    %{msg: "Нашел старую монету на дороге.", effect: :none},
    %{msg: "Споткнулся о корень, но ничего не сломал.", effect: :none},
    %{msg: "Выпил воды из ручья и почувствовал себя лучше.", effect: :heal}
  ]

  def monsters, do: @monsters
  def items, do: @items
  def quests, do: @quests
  def locations, do: @locations
  def thoughts, do: @thoughts
  def random_events, do: @random_events

  @doc """
  Возвращает случайного монстра, чей уровень примерно равен или чуть ниже уровня героя.
  """
  def get_random_monster(hero_level) do
    # Фильтруем монстров: уровень от hero_level - 2 до hero_level
    min_level = max(1, hero_level - 2)
    suitable_monsters = Enum.filter(@monsters, fn m -> m.level >= min_level and m.level <= hero_level end)

    # Если не нашли подходящих (например, уровень героя выше всех монстров), берем самых сильных
    monsters_to_choose = if Enum.empty?(suitable_monsters) do
      max_monster_level = @monsters |> Enum.map(& &1.level) |> Enum.max()
      Enum.filter(@monsters, fn m -> m.level == max_monster_level end)
    else
      suitable_monsters
    end

    Enum.random(monsters_to_choose)
  end

  @doc """
  Возвращает случайный предмет, ценность (редкость) которого зависит от уровня героя.
  """
  def get_random_loot(hero_level) do
    # Увеличиваем шанс выпадения редких предметов с уровнем
    rarity = cond do
      hero_level >= 10 -> Enum.random([:uncommon, :uncommon, :rare, :rare])
      hero_level >= 5  -> Enum.random([:common, :uncommon, :uncommon, :rare])
      true             -> Enum.random([:common, :common, :uncommon])
    end

    suitable_items = Enum.filter(@items, fn item -> item.rarity == rarity end)

    items_to_choose = if Enum.empty?(suitable_items) do
      @items
    else
      suitable_items
    end

    item = Enum.random(items_to_choose)
    item.name
  end

  @doc """
  Возвращает случайную локацию.
  """
  def get_location do
    Enum.random(@locations)
  end
end
