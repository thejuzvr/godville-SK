defmodule GodvilleSk.Arenas do
  @moduledoc """
  Arena context - public API for arena operations.
  """

  import Ecto.Query, warn: false
  alias GodvilleSk.{Repo, Game}
  alias GodvilleSk.Game.Hero
  alias GodvilleSk.Arena.{Arena, ArenaParticipant, Matchmaking}

  def list_arenas do
    Repo.all(Arena)
  end

  def get_arena!(id), do: Repo.get!(Arena, id)

  def get_active_arena_for_hero(hero_id) do
    Repo.get_by(ArenaParticipant, character_id: hero_id)
    |> case do
      nil ->
        nil

      participant ->
        arena = Repo.get(Arena, participant.arena_id)
        if arena && arena.status in [:waiting, :active], do: arena
    end
  end

  def join_arena(hero_id, arena_type) do
    hero = Repo.get(Hero, hero_id)

    cond do
      !hero ->
        {:error, :hero_not_found}

      hero.status == :sovngarde ->
        {:error, :hero_dead}

      hero.status == :combat ->
        {:error, :hero_in_combat}

      get_active_arena_for_hero(hero_id) ->
        {:error, :already_in_arena}

      true ->
        case arena_type do
          :duel -> Matchmaking.join_queue(hero_id, :duel)
          :team_3v3 -> Matchmaking.join_queue(hero_id, :team_3v3)
          :team_5v5 -> Matchmaking.join_queue(hero_id, :team_5v5)
        end

        {:ok, :queued}
    end
  end

  def leave_arena(hero_id) do
    Matchmaking.leave_queue(hero_id)
  end

  def get_queue_status do
    Matchmaking.get_queue_status()
  end

  def get_arena_battles(hero_id) do
    query =
      from(ap in "arena_participants",
        join: a in "arenas",
        on: ap.arena_id == a.id,
        where: ap.character_id == ^hero_id,
        order_by: [desc: a.inserted_at],
        limit: 10,
        select: ap
      )

    Repo.all(query)
  end
end
