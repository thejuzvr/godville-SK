defmodule GodvilleSk.Marketplace do
  @moduledoc """
  Marketplace for trading items and hero souls (characters).
  Uses Ecto.Multi for atomic transactions.
  """

  import Ecto.Query, warn: false
  alias GodvilleSk.Repo
  alias GodvilleSk.Game.Hero
  alias GodvilleSk.Arena
  alias GodvilleSk.Game
  alias GodvilleSk.Accounts.User
  alias GodvilleSk.Marketplace.Trade

  def list_active_trades do
    Trade
    |> where(status: :active)
    |> preload([:seller, :character])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_trade!(id), do: Repo.get!(Trade, id)

  def create_trade(attrs \\ %{}) do
    %Trade{}
    |> Trade.changeset(attrs)
    |> Repo.insert()
  end

  def create_item_trade(seller_id, item_id, price) when is_integer(price) and price > 0 do
    %Trade{}
    |> Trade.changeset(%{
      seller_id: seller_id,
      item_id: item_id,
      price: price,
      status: :active
    })
    |> Repo.insert()
  end

  def create_soul_trade(seller_id, character_id, price) when is_integer(price) and price > 0 do
    character = Repo.get(Hero, character_id)

    cond do
      !character ->
        {:error, :character_not_found}

      character.user_id != seller_id ->
        {:error, :not_owner}

      character.status == :combat ->
        {:error, :character_in_combat}

      Arena.get_active_arena_for_hero(character_id) ->
        {:error, :character_in_arena}

      true ->
        %Trade{}
        |> Trade.changeset(%{
          seller_id: seller_id,
          character_id: character_id,
          price: price,
          status: :active
        })
        |> Repo.insert()
    end
  end

  def complete_trade(trade_id, buyer_id) do
    trade = Repo.get!(Trade, trade_id)

    cond do
      trade.status != :active ->
        {:error, :trade_not_active}

      trade.seller_id == buyer_id ->
        {:error, :cannot_buy_own}

      true ->
        buyer = Repo.get!(User, buyer_id)

        if buyer.gold < trade.price do
          {:error, :insufficient_gold}
        else
          Repo.transaction(fn ->
            case trade.type do
              :item ->
                complete_item_trade(trade, buyer)

              :soul ->
                complete_soul_trade(trade, buyer)
            end
          end)
        end
    end
  end

  defp complete_item_trade(trade, buyer) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :deduct_gold,
      User.query_update_gold(buyer.id, -trade.price)
    )
    |> Ecto.Multi.update(
      :add_gold,
      User.query_update_gold(trade.seller_id, trade.price)
    )
    |> Ecto.Multi.update(
      :trade_status,
      Trade.changeset(trade, %{status: :completed}),
      prefix: nil
    )
    |> Repo.transaction()
    |> case do
      {:ok, _} -> {:ok, :completed}
      error -> error
    end
  end

  defp complete_soul_trade(trade, buyer) do
    character = Repo.get!(Hero, trade.character_id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :deduct_gold,
      User.query_update_gold(buyer.id, -trade.price)
    )
    |> Ecto.Multi.update(
      :add_gold,
      User.query_update_gold(trade.seller_id, trade.price)
    )
    |> Ecto.Multi.update(
      :transfer_character,
      Hero.changeset(character, %{user_id: buyer.id}),
      prefix: nil
    )
    |> Ecto.Multi.update(
      :trade_status,
      Trade.changeset(trade, %{status: :completed}),
      prefix: nil
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{transfer_character: character}} ->
        Game.ensure_hero_running(character)

        Phoenix.PubSub.broadcast(
          GodvilleSk.PubSub,
          "hero:#{character.id}",
          {:soul_sold, %{new_owner_id: buyer.id}}
        )

        {:ok, character}

      error ->
        error
    end
  end

  def cancel_trade(trade_id, user_id) do
    trade = Repo.get!(Trade, trade_id)

    cond do
      trade.seller_id != user_id ->
        {:error, :not_owner}

      trade.status != :active ->
        {:error, :trade_not_active}

      true ->
        trade
        |> Trade.changeset(%{status: :cancelled})
        |> Repo.update()
    end
  end

  def get_seller_trades(seller_id) do
    Trade
    |> where(seller_id: ^seller_id)
    |> preload([:item, :character])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_character_trades(character_id) do
    Trade
    |> where(character_id: ^character_id, status: :active)
    |> Repo.all()
  end

  def search_trades(params) do
    Trade
    |> where(status: :active)
    |> filter_by_type(params[:type])
    |> filter_by_price_range(params[:min_price], params[:max_price])
    |> preload([:seller, :character])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  defp filter_by_type(query, nil), do: query
  defp filter_by_type(query, type) when is_atom(type), do: where(query, type: ^type)

  defp filter_by_type(query, type) when is_binary(type) do
    type_atom = String.to_existing_atom(type)
    where(query, type: ^type_atom)
  end

  defp filter_by_price_range(query, nil, nil), do: query

  defp filter_by_price_range(query, min, nil) when is_integer(min) do
    where(query, [t], t.price >= ^min)
  end

  defp filter_by_price_range(query, nil, max) when is_integer(max) do
    where(query, [t], t.price <= ^max)
  end

  defp filter_by_price_range(query, min, max) when is_integer(min) and is_integer(max) do
    where(query, [t], t.price >= ^min and t.price <= ^max)
  end
end
