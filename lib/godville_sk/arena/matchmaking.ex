defmodule GodvilleSk.Arena.Matchmaking do
  @moduledoc """
  Arena matchmaking queue - manages players waiting for arena battles.
  Supports: Duel (1v1), Team 3v3, Team 5v5

  Broadcasts to "arena:matchmaking" topic:
  - {:queue_joined, hero_id, queue_type, joined_at}
  - {:queue_left, hero_id}
  - {:match_found, hero_id, arena_id}
  """

  use GenServer
  require Logger

  alias GodvilleSk.Arena.Server, as: ArenaServer
  alias GodvilleSk.{Game, Repo}
  alias GodvilleSk.Game.Hero

  defstruct [:duel_queue, :team_3v3_queue, :team_5v5_queue]

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok,
     %__MODULE__{
       duel_queue: [],
       team_3v3_queue: [],
       team_5v5_queue: []
     }}
  end

  # --- Public API ---

  def join_queue(hero_id, :duel) do
    GenServer.cast(__MODULE__, {:join_duel, hero_id})
  end

  def join_queue(hero_id, :team_3v3) do
    GenServer.cast(__MODULE__, {:join_3v3, hero_id})
  end

  def join_queue(hero_id, :team_5v5) do
    GenServer.cast(__MODULE__, {:join_5v5, hero_id})
  end

  def leave_queue(hero_id) do
    GenServer.cast(__MODULE__, {:leave, hero_id})
  end

  def get_queue_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @doc "Returns true if the hero is currently waiting in any queue."
  def in_queue?(hero_id) do
    GenServer.call(__MODULE__, {:in_queue, hero_id})
  end

  @doc "Returns {queue_type, joined_at} if in queue, or nil."
  def get_queue_entry(hero_id) do
    GenServer.call(__MODULE__, {:get_entry, hero_id})
  end

  # --- Handle Casts ---

  def handle_cast({:join_duel, hero_id}, state) do
    state = remove_from_all_queues(state, hero_id)
    joined_at = DateTime.utc_now()

    new_queue =
      case state.duel_queue do
        [] ->
          broadcast_queue_joined(hero_id, :duel, joined_at)
          [%{hero_id: hero_id, joined_at: joined_at}]

        [%{hero_id: other_id} | _rest] ->
          {:ok, arena_id} = ArenaServer.create_duel(other_id, hero_id)
          Logger.info("[Matchmaking] Duel created: #{arena_id} (#{other_id} vs #{hero_id})")
          # Pause both heroes during arena
          pause_hero(other_id)
          pause_hero(hero_id)
          # Notify both via their personal topic
          broadcast_match_found(other_id, arena_id)
          broadcast_match_found(hero_id, arena_id)
          []
      end

    {:noreply, %{state | duel_queue: new_queue}}
  end

  def handle_cast({:join_3v3, hero_id}, state) do
    state = remove_from_all_queues(state, hero_id)
    joined_at = DateTime.utc_now()
    broadcast_queue_joined(hero_id, :team_3v3, joined_at)

    new_queue = state.team_3v3_queue ++ [%{hero_id: hero_id, joined_at: joined_at}]

    if length(new_queue) >= 6 do
      {team1, team2} = Enum.split(new_queue, 3)

      {:ok, arena_id} =
        ArenaServer.create_team_3v3(
          Enum.map(team1, & &1.hero_id),
          Enum.map(team2, & &1.hero_id)
        )

      Logger.info("[Matchmaking] 3v3 created: #{arena_id}")

      all_ids = Enum.map(team1 ++ team2, & &1.hero_id)
      Enum.each(all_ids, fn id ->
        pause_hero(id)
        broadcast_match_found(id, arena_id)
      end)

      {:noreply, %{state | team_3v3_queue: []}}
    else
      {:noreply, %{state | team_3v3_queue: new_queue}}
    end
  end

  def handle_cast({:join_5v5, hero_id}, state) do
    state = remove_from_all_queues(state, hero_id)
    joined_at = DateTime.utc_now()
    broadcast_queue_joined(hero_id, :team_5v5, joined_at)

    new_queue = state.team_5v5_queue ++ [%{hero_id: hero_id, joined_at: joined_at}]

    if length(new_queue) >= 10 do
      {team1, team2} = Enum.split(new_queue, 5)

      {:ok, arena_id} =
        ArenaServer.create_team_5v5(
          Enum.map(team1, & &1.hero_id),
          Enum.map(team2, & &1.hero_id)
        )

      Logger.info("[Matchmaking] 5v5 created: #{arena_id}")

      all_ids = Enum.map(team1 ++ team2, & &1.hero_id)
      Enum.each(all_ids, fn id ->
        pause_hero(id)
        broadcast_match_found(id, arena_id)
      end)

      {:noreply, %{state | team_5v5_queue: []}}
    else
      {:noreply, %{state | team_5v5_queue: new_queue}}
    end
  end

  def handle_cast({:leave, hero_id}, state) do
    new_state = remove_from_all_queues(state, hero_id)
    broadcast_queue_left(hero_id)
    {:noreply, new_state}
  end

  # --- Handle Calls ---

  def handle_call(:get_status, _from, state) do
    {:reply,
     %{
       duel_queue: length(state.duel_queue),
       team_3v3_queue: length(state.team_3v3_queue),
       team_5v5_queue: length(state.team_5v5_queue)
     }, state}
  end

  def handle_call({:in_queue, hero_id}, _from, state) do
    result =
      Enum.any?(state.duel_queue ++ state.team_3v3_queue ++ state.team_5v5_queue, fn entry ->
        entry.hero_id == hero_id
      end)

    {:reply, result, state}
  end

  def handle_call({:get_entry, hero_id}, _from, state) do
    all = [
      {state.duel_queue, :duel},
      {state.team_3v3_queue, :team_3v3},
      {state.team_5v5_queue, :team_5v5}
    ]

    result =
      Enum.find_value(all, fn {queue, type} ->
        case Enum.find(queue, &(&1.hero_id == hero_id)) do
          nil -> nil
          entry -> {type, entry.joined_at}
        end
      end)

    {:reply, result, state}
  end

  # --- Private ---

  defp remove_from_all_queues(state, hero_id) do
    was_in_queue =
      Enum.any?(
        state.duel_queue ++ state.team_3v3_queue ++ state.team_5v5_queue,
        &(&1.hero_id == hero_id)
      )

    if was_in_queue, do: broadcast_queue_left(hero_id)

    %{
      state
      | duel_queue: Enum.reject(state.duel_queue, &(&1.hero_id == hero_id)),
        team_3v3_queue: Enum.reject(state.team_3v3_queue, &(&1.hero_id == hero_id)),
        team_5v5_queue: Enum.reject(state.team_5v5_queue, &(&1.hero_id == hero_id))
    }
  end

  # Pause hero's AI tick during arena fight
  defp pause_hero(hero_id) do
    hero = Repo.get(Hero, hero_id)

    if hero do
      case Game.get_hero_live_state(hero) do
        nil -> :ok
        _state ->
          GodvilleSk.Hero.pause_for_arena(hero.name)
      end
    end
  end

  # PubSub broadcasts to hero-specific topic
  defp broadcast_queue_joined(hero_id, queue_type, joined_at) do
    Phoenix.PubSub.broadcast(
      GodvilleSk.PubSub,
      "hero:#{hero_id}",
      {:queue_joined, hero_id, queue_type, joined_at}
    )
  end

  defp broadcast_queue_left(hero_id) do
    Phoenix.PubSub.broadcast(
      GodvilleSk.PubSub,
      "hero:#{hero_id}",
      {:queue_left, hero_id}
    )
  end

  defp broadcast_match_found(hero_id, arena_id) do
    Phoenix.PubSub.broadcast(
      GodvilleSk.PubSub,
      "hero:#{hero_id}",
      {:match_found, arena_id}
    )
  end
end
