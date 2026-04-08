defmodule GodvilleSk.Game do
  import Ecto.Query, warn: false
  alias GodvilleSk.Repo
  alias GodvilleSk.Game.Hero
  alias GodvilleSk.Game.HeroLog

  def get_hero!(id), do: Repo.get!(Hero, id)

  def get_hero_by_user_id(user_id) do
    Repo.get_by(Hero, user_id: user_id)
  end

  def create_hero(attrs \\ %{}) do
    %Hero{}
    |> Hero.changeset(attrs)
    |> Repo.insert()
  end

  def update_hero(%Hero{} = hero, attrs) do
    hero
    |> Hero.changeset(attrs)
    |> Repo.update()
  end

  def delete_hero(%Hero{} = hero) do
    Repo.delete(hero)
  end

  def list_hero_logs(hero_id, limit \\ 100) do
    HeroLog
    |> where(hero_id: ^hero_id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def create_hero_log(attrs \\ %{}) do
    %HeroLog{}
    |> HeroLog.changeset(attrs)
    |> Repo.insert()
  end
end
