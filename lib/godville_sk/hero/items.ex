defmodule GodvilleSk.Hero.Items do
  @moduledoc """
  Hero item management: equipping items, using potions, managing inventory.
  Works with GodvilleSk.Game.Items for item definitions.
  """

  alias GodvilleSk.Game.Items
  alias GodvilleSk.GameData

  @type item :: Items.t()

  @doc """
  Equips an item to the appropriate slot in hero equipment.
  Returns updated hero state or error if requirements not met.
  """
  def equip_item(state, item_name) do
    case find_item(state.inventory, item_name) do
      nil ->
        {:error, :not_found}

      item ->
        if Items.can_use?(item, state.level) do
          case item.type do
            :weapon -> equip_to_slot(state, item, :weapon, item_name)
            :armor -> equip_to_slot(state, item, item.slot, item_name)
            :potion_heal -> {:error, :is_potion}
            :potion_buff -> {:error, :is_potion}
            :lockpick -> {:error, :is_lockpick}
          end
        else
          {:error, :level_too_low}
        end
    end
  end

  @doc """
  Uses a healing potion from inventory.
  """
  def use_potion_heal(state, potion_name) do
    case find_item(state.inventory, potion_name) do
      nil ->
        {:error, :not_found}

      item when item.type == :potion_heal ->
        heal_amount = item.value
        new_hp = min(state.hp + heal_amount, state.max_hp)
        actual_healed = new_hp - state.hp

        new_state =
          state
          |> Map.put(:hp, new_hp)
          |> remove_from_inventory(potion_name)

        {:ok, new_state, actual_healed}

      _ ->
        {:error, :not_potion}
    end
  end

  @doc """
  Uses a buff potion from inventory.
  Returns {:ok, state, duration, effect}
  """
  def use_potion_buff(state, potion_name) do
    case find_item(state.inventory, potion_name) do
      nil ->
        {:error, :not_found}

      item when item.type == :potion_buff ->
        duration = item.value
        effect = item.effect
        attribute = attribute_from_effect(effect)

        buff_value =
          case item.rarity do
            :common -> 5
            :uncommon -> 10
            :rare -> 15
            :legendary -> 20
          end

        current_val = Map.get(state, attribute, 0)

        new_state =
          state
          |> Map.put(attribute, current_val + buff_value)
          |> apply_buff(effect, duration, buff_value)
          |> remove_from_inventory(potion_name)

        {:ok, new_state, duration, effect, buff_value}

      _ ->
        {:error, :not_potion}
    end
  end

  @doc """
  Uses a lockpick. Returns lockpick quality and removes it from inventory.
  """
  def use_lockpick(state, lockpick_name) do
    case find_item(state.inventory, lockpick_name) do
      nil ->
        {:error, :not_found}

      item when item.type == :lockpick ->
        quality =
          case item.rarity do
            :common -> 1
            :uncommon -> 2
            :rare -> 3
            :legendary -> 4
          end

        new_state = remove_from_inventory(state, lockpick_name)
        {:ok, new_state, quality}

      _ ->
        {:error, :not_lockpick}
    end
  end

  @doc """
  Unequips an item from a slot.
  """
  def unequip_item(state, slot) do
    current_item = Map.get(state.equipment, slot)

    if current_item do
      new_equipment = Map.put(state.equipment, slot, nil)
      new_inventory = [current_item | state.inventory]

      new_state =
        state
        |> Map.put(:equipment, new_equipment)
        |> Map.put(:inventory, new_inventory |> Enum.take(state.inventory_capacity))

      {:ok, new_state, current_item}
    else
      {:error, :slot_empty}
    end
  end

  @doc """
  Analyzes hero's equipment and generates thoughts.
  Returns a list of thought strings.
  """
  def analyze_equipment(state) do
    thoughts = []

    # Check weapon
    thought =
      case state.equipment.weapon do
        nil -> "Моя рука пуста... Нужен меч или посох."
        weapon -> "Мой #{weapon} служит мне верно."
      end

    thoughts = thoughts ++ [thought]

    # Check armor coverage
    equip_map = Map.from_struct(state.equipment)

    armored_slots =
      Enum.count([:head, :torso, :legs, :arms, :boots], fn slot ->
        not is_nil(Map.get(equip_map, slot))
      end)

    armor_thought =
      case armored_slots do
        0 -> "Я абсолютно беззащитен без брони."
        1..2 -> "Немного бронировки было бы неплохо."
        3..4 -> "Моя защита надежна, но можно лучше."
        _ -> "Я закован в броню как краб!"
      end

    thoughts = thoughts ++ [armor_thought]

    # Check accessories
    accessories_thoughts =
      cond do
        is_nil(state.equipment.amulet) and is_nil(state.equipment.ring) ->
          ["У меня нет амулетов или колец — упускаю магические бонусы."]

        is_nil(state.equipment.amulet) ->
          ["Без амулета я чувствую себя неполным."]

        is_nil(state.equipment.ring) ->
          ["Кольцо придавало бы мне вес в битве."]

        true ->
          ["Моя магическая экипировка работает как надо."]
      end

    thoughts = thoughts ++ accessories_thoughts

    # Potions available?
    potions_count = Enum.count(state.inventory, &is_potion?/1)

    potion_thought =
      case potions_count do
        0 -> "Нет зельев в запасах... Опасно идти в пустоту."
        1 -> "Осталось одно зелье. Буду беречь его."
        _ -> "Запас зельев пополнен — спокойнее за жизнь."
      end

    thoughts = thoughts ++ [potion_thought]

    # Lockpicks?
    lockpicks_count = Enum.count(state.inventory, &is_lockpick?/1)

    lockpick_thought =
      case lockpicks_count do
        0 -> "Отмычки закончились. Запирающиеся двери — проблема."
        1 -> "Последняя отмычка... Буду аккуратнее."
        _ -> "Отмычек хватит на любое замыкание."
      end

    thoughts = thoughts ++ [lockpick_thought]

    thoughts
  end

  @doc """
  Suggests items to equip from inventory based on slot preferences.
  Returns list of equipable item names.
  """
  def suggest_equipment(state) do
    state.inventory
    |> Enum.filter(&can_equip_in_empty_slot?(state, &1))
    |> Enum.map(& &1.name)
  end

  @doc """
  Calculates total weight of all items in inventory.
  """
  def calculate_inventory_weight(inventory) do
    Enum.reduce(inventory, 0.0, fn item_name, acc ->
      case find_item([], item_name) do
        nil -> acc
        item -> acc + (item.weight || 0.0)
      end
    end)
  end

  @doc """
  Checks if hero is overloaded (weight > 50).
  Returns {is_overloaded, penalty}
  """
  def check_overload(weight) when weight > 50 do
    {true, -2}
  end

  def check_overload(_weight) do
    {false, 0}
  end

  # --- Private helpers ---

  def find_item(inventory, name) do
    Enum.find(get_all_items(), fn item -> item.name == name end)
  end

  defp get_all_items do
    Items.get_weapons() ++
      Items.get_armor_pieces() ++
      Items.get_healing_potions() ++
      Items.get_buff_potions() ++
      Items.get_lockpicks() ++
      GameData.items()
  end

  defp equip_to_slot(state, item, slot, item_name) do
    old_item = Map.get(state.equipment, slot)

    inventory = List.delete(state.inventory, item_name)
    inventory = if old_item, do: [old_item | inventory], else: inventory

    new_equipment = Map.put(state.equipment, slot, item_name)

    new_state =
      state
      |> Map.put(:equipment, new_equipment)
      |> Map.put(:inventory, inventory)

    {:ok, new_state}
  end

  defp remove_from_inventory(state, item_name) do
    new_inventory = List.delete(state.inventory, item_name)
    Map.put(state, :inventory, new_inventory)
  end

  defp apply_buff(state, effect, duration, value) do
    # In a more complex implementation, we'd track active buffs with expiration
    state
  end

  defp attribute_from_effect(:strength), do: :strength
  defp attribute_from_effect(:agility), do: :agility
  defp attribute_from_effect(:speed), do: :speed
  defp attribute_from_effect(:luck), do: :luck
  defp attribute_from_effect(:endurance), do: :endurance
  defp attribute_from_effect(:intelligence), do: :intelligence
  defp attribute_from_effect(:willpower), do: :willpower
  defp attribute_from_effect(:personality), do: :personality
  defp attribute_from_effect(_), do: nil

  defp is_potion?(item_name) do
    item = find_item([], item_name)
    item && item.type in [:potion_heal, :potion_buff]
  end

  defp is_lockpick?(item_name) do
    item = find_item([], item_name)
    item && item.type == :lockpick
  end

  defp can_equip_in_empty_slot?(state, item_name) do
    item = find_item([], item_name)

    item &&
      item.type in [:weapon, :armor] &&
      Items.can_use?(item, state.level) &&
      is_nil(Map.get(state.equipment, item.slot))
  end
end
