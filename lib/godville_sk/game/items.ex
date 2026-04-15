defmodule GodvilleSk.Game.Items do
  @moduledoc """
  Item definitions and types for the hero inventory system.
  Weapons, armor, potions, and lockpicks with their properties.
  """

  @type item_type :: :weapon | :armor | :potion_heal | :potion_buff | :lockpick
  @type item_slot :: :weapon | :head | :torso | :legs | :arms | :boots | :amulet | :ring
  @type potion_effect :: :heal | :strength | :agility | :speed | :luck

  @type t :: %__MODULE__{
          name: String.t(),
          type: item_type(),
          slot: item_slot() | nil,
          effect: potion_effect() | nil,
          value: integer() | nil,
          rarity: :common | :uncommon | :rare | :legendary,
          level_requirement: integer(),
          weight: float()
        }

  defstruct [:name, :type, :slot, :effect, :value, :rarity, :level_requirement, :weight]

  @doc """
  Creates a weapon item.
  """
  def weapon(name, damage, rarity \\ :common, level_req \\ 1, weight \\ 5.0) do
    %__MODULE__{
      name: name,
      type: :weapon,
      slot: :weapon,
      value: damage,
      rarity: rarity,
      level_requirement: level_req,
      weight: weight
    }
  end

  @doc """
  Creates an armor piece.
  """
  def armor(name, ac_bonus, slot, rarity \\ :common, level_req \\ 1, weight \\ 8.0) do
    %__MODULE__{
      name: name,
      type: :armor,
      slot: slot,
      value: ac_bonus,
      rarity: rarity,
      level_requirement: level_req,
      weight: weight
    }
  end

  @doc """
  Creates a healing potion.
  """
  def potion_heal(name, heal_amount, rarity \\ :common, weight \\ 0.5) do
    %__MODULE__{
      name: name,
      type: :potion_heal,
      slot: nil,
      effect: :heal,
      value: heal_amount,
      rarity: rarity,
      level_requirement: 1,
      weight: weight
    }
  end

  @doc """
  Creates a buff potion.
  """
  def potion_buff(name, effect, duration, rarity \\ :common, weight \\ 0.5) do
    %__MODULE__{
      name: name,
      type: :potion_buff,
      slot: nil,
      effect: effect,
      value: duration,
      rarity: rarity,
      level_requirement: 1,
      weight: weight
    }
  end

  @doc """
  Creates a lockpick.
  """
  def lockpick(name, quality \\ :common, weight \\ 0.1) do
    %__MODULE__{
      name: name,
      type: :lockpick,
      slot: nil,
      effect: nil,
      value: nil,
      rarity: quality,
      level_requirement: 1,
      weight: weight
    }
  end

  @doc """
  Gets a random item based on hero level.
  """
  def random_item(level \\ 1) do
    roll = :rand.uniform(100)

    cond do
      roll <= 40 ->
        random_weapon(level)

      roll <= 70 ->
        random_armor(level)

      roll <= 85 ->
        random_potion_heal(level)

      roll <= 95 ->
        random_potion_buff(level)

      true ->
        random_lockpick(level)
    end
  end

  defp random_weapon(level) do
    weapons = get_weapons()
    applicable = Enum.filter(weapons, &(&1.level_requirement <= level))
    Enum.random(applicable)
  end

  defp random_armor(level) do
    armor_pieces = get_armor_pieces()
    applicable = Enum.filter(armor_pieces, &(&1.level_requirement <= level))
    Enum.random(applicable)
  end

  defp random_potion_heal(level) do
    potions = get_healing_potions()
    applicable = Enum.filter(potions, &(!&1.level_requirement || &1.level_requirement <= level))
    Enum.random(applicable)
  end

  defp random_potion_buff(level) do
    potions = get_buff_potions()
    applicable = Enum.filter(potions, &(!&1.level_requirement || &1.level_requirement <= level))
    Enum.random(applicable)
  end

  defp random_lockpick(_level) do
    Enum.random(get_lockpicks())
  end

  @doc """
  Gets all defined weapons.
  """
  def get_weapons do
    [
      weapon("Ржавый меч", 3, :common, 1, 4.0),
      weapon("Стальной меч", 5, :common, 2, 5.0),
      weapon("Окаменелый меч", 7, :uncommon, 3, 5.5),
      weapon("Серебряный клинок", 9, :uncommon, 4, 4.5),
      weapon("Эльдарский меч", 12, :rare, 5, 4.0),
      weapon("Огненный меч", 15, :rare, 6, 6.0),
      weapon("Ледяной клинок", 10, :rare, 4, 4.5),
      weapon("Посох молний", 11, :rare, 5, 7.0),
      weapon("Клинок Шора", 20, :legendary, 8, 5.0),
      weapon("Оружие Молага Бала", 25, :legendary, 10, 8.0),
      weapon("Хаэш!", 30, :legendary, 12, 6.0),
      weapon("Умирающий свет", 35, :legendary, 15, 4.5)
    ]
  end

  @doc """
  Gets all defined armor pieces.
  """
  def get_armor_pieces do
    [
      armor("Кожаная куртка", 1, :torso, :common, 1, 5.0),
      armor("Кожаные сапоги", 1, :boots, :common, 1, 2.0),
      armor("Кожаные перчатки", 1, :arms, :common, 1, 1.0),
      armor("Кольчуга", 2, :torso, :common, 2, 12.0),
      armor("Стальные сапоги", 2, :boots, :common, 2, 4.0),
      armor("Стальные перчатки", 2, :arms, :common, 2, 2.5),
      armor("Шлем", 2, :head, :common, 2, 3.0),
      armor("Оркская броня", 4, :torso, :uncommon, 3, 15.0),
      armor("Нордская броня", 4, :torso, :uncommon, 3, 14.0),
      armor("Кираса", 3, :torso, :uncommon, 3, 10.0),
      armor("Тяжелый шлем", 3, :head, :uncommon, 3, 5.0),
      armor("Эбонитовая броня", 6, :torso, :rare, 5, 8.0),
      armor("Стеклянная броня", 6, :torso, :rare, 5, 6.0),
      armor("Двемерская броня", 7, :torso, :rare, 6, 18.0),
      armor("Драконья броня", 7, :torso, :rare, 7, 20.0),
      armor("Броня Пантера", 9, :torso, :legendary, 9, 9.0),
      armor("Японский доспех", 8, :torso, :legendary, 8, 12.0),
      armor("Кольцо силы", 1, :ring, :uncommon, 2, 0.3),
      armor("Кольцо удачи", 1, :ring, :rare, 4, 0.3),
      armor("Амулет здоровья", 1, :amulet, :common, 2, 0.5),
      armor("Амулет магии", 1, :amulet, :rare, 5, 0.5)
    ]
  end

  @doc """
  Gets all healing potions.
  """
  def get_healing_potions do
    [
      potion_heal("Малое зелье лечения", 15, :common, 0.3),
      potion_heal("Зелье лечения", 30, :common, 0.5),
      potion_heal("Большое зелье лечения", 50, :uncommon, 0.8),
      potion_heal("Потрясающее зелье лечения", 75, :rare, 1.0),
      potion_heal("Эликсиры жизни", 100, :legendary, 1.5)
    ]
  end

  @doc """
  Gets all buff potions.
  """
  def get_buff_potions do
    [
      potion_buff("Зелье силы", :strength, 5, :common, 0.4),
      potion_buff("Зелье ловкости", :agility, 5, :common, 0.4),
      potion_buff("Зелье скорости", :speed, 5, :common, 0.4),
      potion_buff("Зелье удачи", :luck, 3, :uncommon, 0.4),
      potion_buff("Зелье стойкости", :endurance, 5, :common, 0.4),
      potion_buff("Зелье интеллекта", :intelligence, 5, :uncommon, 0.4),
      potion_buff("Зелье воли", :willpower, 5, :rare, 0.5),
      potion_buff("Зелье обаяния", :personality, 5, :rare, 0.5)
    ]
  end

  @doc """
  Gets all lockpicks.
  """
  def get_lockpicks do
    [
      lockpick("Отмычка", :common, 0.1),
      lockpick("Качественная отмычка", :uncommon, 0.15),
      lockpick("Мастерская отмычка", :rare, 0.2)
    ]
  end

  @doc """
  Returns item as string for display.
  """
  def to_string(item) do
    rarity_str =
      case item.rarity do
        :common -> "Обычный"
        :uncommon -> "Редкий"
        :rare -> "Дикий"
        :legendary -> "Легендарный"
      end

    case item.type do
      :weapon -> "#{rarity_str} #{item.name} (урон: #{item.value})"
      :armor -> "#{rarity_str} #{item.name} (AC+#{item.value})"
      :potion_heal -> "#{item.name} (+#{item.value} HP)"
      :potion_buff -> "#{item.name} (эффект: #{item.effect})"
      :lockpick -> "#{item.name}"
    end
  end

  @doc """
  Checks if hero level meets requirement.
  """
  def can_use?(%__MODULE__{level_requirement: req}, hero_level) do
    hero_level >= req
  end
end
