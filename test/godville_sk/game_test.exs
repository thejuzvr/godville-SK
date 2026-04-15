defmodule GodvilleSk.GameTest do
  use GodvilleSk.DataCase

  alias GodvilleSk.Game

  describe "heroes" do
    alias GodvilleSk.Game.Hero

    import GodvilleSk.GameFixtures

    @invalid_attrs %{
      attributes: nil,
      class: nil,
      exp: nil,
      gold: nil,
      hp: nil,
      level: nil,
      max_hp: nil,
      name: nil,
      perks: nil,
      race: nil
    }

    test "list_heroes/0 returns all heroes" do
      hero = hero_fixture()
      assert Game.list_heroes() == [hero]
    end

    test "get_hero!/1 returns the hero with given id" do
      hero = hero_fixture()
      assert Game.get_hero!(hero.id) == hero
    end

    test "create_hero/1 with valid data creates a hero" do
      valid_attrs = %{
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
      }

      assert {:ok, %Hero{} = hero} = Game.create_hero(valid_attrs)
      assert hero.attributes == %{}
      assert hero.class == "some class"
      assert hero.exp == 42
      assert hero.gold == 42
      assert hero.hp == 42
      assert hero.level == 42
      assert hero.max_hp == 42
      assert hero.name == "some name"
      assert hero.perks == ["option1", "option2"]
      assert hero.race == "some race"
    end

    test "create_hero/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_hero(@invalid_attrs)
    end

    test "update_hero/2 with valid data updates the hero" do
      hero = hero_fixture()

      update_attrs = %{
        attributes: %{},
        class: "some updated class",
        exp: 43,
        gold: 43,
        hp: 43,
        level: 43,
        max_hp: 43,
        name: "some updated name",
        perks: ["option1"],
        race: "some updated race"
      }

      assert {:ok, %Hero{} = hero} = Game.update_hero(hero, update_attrs)
      assert hero.attributes == %{}
      assert hero.class == "some updated class"
      assert hero.exp == 43
      assert hero.gold == 43
      assert hero.hp == 43
      assert hero.level == 43
      assert hero.max_hp == 43
      assert hero.name == "some updated name"
      assert hero.perks == ["option1"]
      assert hero.race == "some updated race"
    end

    test "update_hero/2 with invalid data returns error changeset" do
      hero = hero_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_hero(hero, @invalid_attrs)
      assert hero == Game.get_hero!(hero.id)
    end

    test "delete_hero/1 deletes the hero" do
      hero = hero_fixture()
      assert {:ok, %Hero{}} = Game.delete_hero(hero)
      assert_raise Ecto.NoResultsError, fn -> Game.get_hero!(hero.id) end
    end

    test "change_hero/1 returns a hero changeset" do
      hero = hero_fixture()
      assert %Ecto.Changeset{} = Game.change_hero(hero)
    end
  end
end
