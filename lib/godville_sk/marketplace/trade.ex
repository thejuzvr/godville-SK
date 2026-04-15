defmodule GodvilleSk.Marketplace.Trade do
  @moduledoc """
  Trade listing schema for the marketplace.
  Supports both item trades and soul (character) trades.
  Items are stored as item_name strings since there's no Item schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "trades" do
    field(:type, Ecto.Enum, values: [:item, :soul])
    field(:price, :integer)
    field(:status, Ecto.Enum, values: [:active, :completed, :cancelled])
    field(:item_name, :string)

    belongs_to(:seller, GodvilleSk.Accounts.User)
    belongs_to(:character, GodvilleSk.Game.Hero)

    timestamps(type: :utc_datetime)
  end

  def changeset(trade, attrs) do
    trade
    |> cast(attrs, [:type, :price, :status, :seller_id, :character_id, :item_name])
    |> validate_required([:type, :price, :status, :seller_id])
    |> validate_number(:price, greater_than: 0)
    |> validate_inclusion(:type, [:item, :soul])
    |> validate_inclusion(:status, [:active, :completed, :cancelled])
  end

  def item_trade_changeset(trade, attrs) do
    trade
    |> changeset(attrs)
    |> validate_required([:item_name])
    |> validate_exclusion(:character_id, ["must be null for item trades"])
  end

  def soul_trade_changeset(trade, attrs) do
    trade
    |> changeset(attrs)
    |> validate_required([:character_id])
    |> validate_exclusion(:item_name, ["must be null for soul trades"])
  end
end
