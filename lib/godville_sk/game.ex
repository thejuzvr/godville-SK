defmodule GodvilleSk.Game do
  @moduledoc """
  The Game context.
  """

  import Ecto.Query, warn: false
  alias GodvilleSk.Repo
  alias GodvilleSk.Game.Hero

  def list_heroes do
    Repo.all(Hero)
  end

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

  def change_hero(%Hero{} = hero, attrs \\ %{}) do
    Hero.changeset(hero, attrs)
  end

  @doc """
  Ensures the hero's GenServer process is running. Starts it if not already running.
  """
  def ensure_hero_running(%Hero{} = hero) do
    case :global.whereis_name({:hero, hero.name}) do
      :undefined ->
        spec = {GodvilleSk.Hero, [id: hero.id, name: hero.name]}

        case DynamicSupervisor.start_child(GodvilleSk.HeroSupervisor, spec) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          error -> error
        end

      pid ->
        {:ok, pid}
    end
  end

  @doc """
  Gets the live state of a hero from its GenServer process.
  Returns nil if the process is not running.
  """
  def get_hero_live_state(%Hero{} = hero) do
    case :global.whereis_name({:hero, hero.name}) do
      :undefined ->
        nil

      _pid ->
        try do
          GodvilleSk.Hero.get_state(hero.name, 2000)
        catch
          :exit, _reason -> nil
        end
    end
  end
end
