defmodule GodvilleSk.Arena.Matchmaking do
  @moduledoc """
  Arena matchmaking queue - manages players waiting for arena battles.
  Supports: Duel (1v1), Team 3v3, Team 5v5
  """

  use GenServer
  require Logger

  defstruct [:duel_queue, :team_3v3_queue, :team_5v5_queue]

  @default_queue_ttl :timer.minutes(5)

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

  def handle_cast({:join_duel, hero_id}, state) do
    state = remove_from_all_queues(state, hero_id)

    new_queue =
      case state.duel_queue do
        [] ->
          [%{hero_id: hero_id, joined_at: DateTime.utc_now()}]

        [%{hero_id: other_id} | _] ->
          {:ok, arena_id} = Arena.Server.create_duel(other_id, hero_id)
          Logger.info("[Matchmaking] Duel created: #{arena_id}")
          state.duel_queue
      end

    {:noreply, %{state | duel_queue: new_queue}}
  end

  def handle_cast({:join_3v3, hero_id}, state) do
    state = remove_from_all_queues(state, hero_id)

    new_queue = state.team_3v3_queue ++ [%{hero_id: hero_id, joined_at: DateTime.utc_now()}]

    if length(new_queue) >= 6 do
      {team1, team2} = Enum.split(new_queue, 3)

      {:ok, arena_id} =
        Arena.Server.create_team_3v3(
          Enum.map(team1, & &1.hero_id),
          Enum.map(team2, & &1.hero_id)
        )

      Logger.info("[Matchmaking] 3v3 created: #{arena_id}")
      {:noreply, %{state | team_3v3_queue: []}}
    else
      {:noreply, %{state | team_3v3_queue: new_queue}}
    end
  end

  def handle_cast({:join_5v5, hero_id}, state) do
    state = remove_from_all_queues(state, hero_id)

    new_queue = state.team_5v5_queue ++ [%{hero_id: hero_id, joined_at: DateTime.utc_now()}]

    if length(new_queue) >= 10 do
      {team1, team2} = Enum.split(new_queue, 5)

      {:ok, arena_id} =
        Arena.Server.create_team_5v5(
          Enum.map(team1, & &1.hero_id),
          Enum.map(team2, & &1.hero_id)
        )

      Logger.info("[Matchmaking] 5v5 created: #{arena_id}")
      {:noreply, %{state | team_5v5_queue: []}}
    else
      {:noreply, %{state | team_5v5_queue: new_queue}}
    end
  end

  def handle_cast({:leave, hero_id}, state) do
    {:noreply, remove_from_all_queues(state, hero_id)}
  end

  def handle_call(:get_status, _from, state) do
    {:reply,
     %{
       duel_queue: length(state.duel_queue),
       team_3v3_queue: length(state.team_3v3_queue),
       team_5v5_queue: length(state.team_5v5_queue)
     }, state}
  end

  defp remove_from_all_queues(state, hero_id) do
    %{
      state
      | duel_queue: Enum.reject(state.duel_queue, &(&1.hero_id == hero_id)),
        team_3v3_queue: Enum.reject(state.team_3v3_queue, &(&1.hero_id == hero_id)),
        team_5v5_queue: Enum.reject(state.team_5v5_queue, &(&1.hero_id == hero_id))
    }
  end
end
