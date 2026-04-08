defmodule GodvilleSk.GameFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GodvilleSk.Game` context.
  """

  @doc """
  Generate a hero.
  """
  def hero_fixture(attrs \\ %{}) do
    {:ok, hero} =
      attrs
      |> Enum.into(%{
        attributes: %{},
        class: "some class",
        exp: 42,
        gold: 42,
        hp: 42,
        level: 42,
        max_hp: 42,
        name: "some name",
        perks: ["option1", "option2"],
        race: "some race"
      })
      |> GodvilleSk.Game.create_hero()

    hero
  end
end
