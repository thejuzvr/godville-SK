defmodule GodvilleSk.Arena.Server do
  @moduledoc """
  Arena battle server - manages a single arena match.
  Each arena is a GenServer that coordinates the battle between teams.
  """

  use GenServer
  require Logger

  alias GodvilleSk.{Repo, Game}
  alias GodvilleSk.Game.Hero

  @tick_interval 500
  @max_rounds 50

  defstruct [
    :id,
    :type,
    :status,
    :team1,
    :team2,
    :round,
    :winner,
    :rewards,
    log: []
  ]

  def start_link(opts) do
    id = opts[:id] || Ecto.UUID.generate()
    GenServer.start_link(__MODULE__, opts, name: via_tuple(id))
  end

  def via_tuple(id), do: {:global, {:arena, id}}

  def create_duel(hero1_id, hero2_id) do
    id = Ecto.UUID.generate()
    spec = {__MODULE__, [id: id, type: :duel, team1: [hero1_id], team2: [hero2_id]]}

    case DynamicSupervisor.start_child(GodvilleSk.ArenaSupervisor, spec) do
      {:ok, _pid} ->
        {:ok, id}

      error ->
        error
    end
  end

  def create_team_3v3(team1_ids, team2_ids) do
    id = Ecto.UUID.generate()
    spec = {__MODULE__, [id: id, type: :team_3v3, team1: team1_ids, team2: team2_ids]}

    case DynamicSupervisor.start_child(GodvilleSk.ArenaSupervisor, spec) do
      {:ok, _pid} ->
        {:ok, id}

      error ->
        error
    end
  end

  def create_team_5v5(team1_ids, team2_ids) do
    id = Ecto.UUID.generate()
    spec = {__MODULE__, [id: id, type: :team_5v5, team1: team1_ids, team2: team2_ids]}

    case DynamicSupervisor.start_child(GodvilleSk.ArenaSupervisor, spec) do
      {:ok, _pid} ->
        {:ok, id}

      error ->
        error
    end
  end

  def get_arena(id) do
    case :global.whereis_name({:arena, id}) do
      :undefined -> nil
      pid -> GenServer.call(pid, :get_state)
    end
  end

  def init(opts) do
    state = %__MODULE__{
      id: opts[:id],
      type: opts[:type],
      status: :waiting,
      team1: opts[:team1] || [],
      team2: opts[:team2] || [],
      round: 0,
      winner: nil,
      rewards: %{}
    }

    schedule_tick()
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:tick, state) do
    new_state = process_round(state)

    if new_state.status == :finished do
      broadcast_arena_result(new_state)
      {:stop, :normal, new_state}
    else
      schedule_tick()
      {:noreply, new_state}
    end
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, @tick_interval)

  defp process_round(state) do
    case state.status do
      :waiting ->
        broadcast_start(state)
        Map.put(state, :status, :active)

      :active ->
        state = %{state | round: state.round + 1}
        state = process_team_turn(state, :team1)
        state = process_team_turn(state, :team2)

        if state.round >= @max_rounds do
          determine_winner_by_remaining_hp(state)
        else
          check_victory_condition(state)
        end

      _ ->
        state
    end
  end

  defp process_team_turn(state, team) do
    team_ids = if team == :team1, do: state.team1, else: state.team2

    Enum.reduce(team_ids, state, fn hero_id, acc_state ->
      hero_state = Game.get_hero_live_state(%Hero{id: hero_id})

      if hero_state && hero_state.hp > 0 do
        opponent_ids = if team == :team1, do: acc_state.team2, else: acc_state.team1
        target_id = Enum.random(opponent_ids)

        case attack_in_arena(hero_state, target_id) do
          {:ok, updated_target_hp} ->
            broadcast_attack(hero_id, target_id, acc_state.id)
            acc_state

          :target_dead ->
            acc_state
        end
      else
        acc_state
      end
    end)
  end

  defp attack_in_arena(attacker_state, target_id) do
    target = Repo.get(Hero, target_id)

    if target && target.hp > 0 do
      damage = calculate_arena_damage(attacker_state)
      new_hp = max(0, target.hp - damage)

      target
      |> Hero.changeset(%{hp: new_hp})
      |> Repo.update()

      {:ok, new_hp}
    else
      :target_dead
    end
  end

  defp calculate_arena_damage(attacker_state) do
    base_damage = attacker_state.strength / 10
    weapon_bonus = :rand.uniform(10)
    round(base_damage + weapon_bonus)
  end

  defp check_victory_condition(state) do
    team1_alive = count_alive(state.team1)
    team2_alive = count_alive(state.team2)

    cond do
      team1_alive == 0 ->
        finish_arena(state, :team2)

      team2_alive == 0 ->
        finish_arena(state, :team1)

      true ->
        state
    end
  end

  defp determine_winner_by_remaining_hp(state) do
    team1_hp = total_team_hp(state.team1)
    team2_hp = total_team_hp(state.team2)

    winner = if team1_hp >= team2_hp, do: :team1, else: :team2
    finish_arena(state, winner)
  end

  defp count_alive(team_ids) do
    Enum.count(team_ids, fn id ->
      hero = Repo.get(Hero, id)
      hero && hero.hp > 0
    end)
  end

  defp total_team_hp(team_ids) do
    Enum.reduce(team_ids, 0, fn id, acc ->
      hero = Repo.get(Hero, id)
      acc + ((hero && hero.hp) || 0)
    end)
  end

  defp finish_arena(state, winner) do
    rewards = calculate_rewards(state, winner)

    Enum.each(state.team1 ++ state.team2, fn hero_id ->
      hero = Repo.get(Hero, hero_id)

      if hero do
        team = if hero_id in state.team1, do: :team1, else: :team2
        reward = Map.get(rewards, team, %{})
        apply_rewards(hero, reward, winner == team)
      end
    end)

    %{state | status: :finished, winner: winner, rewards: rewards}
  end

  defp calculate_rewards(state, winner) do
    base_gold = 100 * length(state.team1)
    base_xp = 50 * length(state.team1)

    cond do
      winner == :team1 ->
        %{
          team1: %{gold: base_gold, xp: base_xp},
          team2: %{gold: div(base_gold, 2), xp: div(base_xp, 2)}
        }

      winner == :team2 ->
        %{
          team2: %{gold: base_gold, xp: base_xp},
          team1: %{gold: div(base_gold, 2), xp: div(base_xp, 2)}
        }

      true ->
        %{
          team1: %{gold: div(base_gold, 2), xp: div(base_xp, 2)},
          team2: %{gold: div(base_gold, 2), xp: div(base_xp, 2)}
        }
    end
  end

  defp apply_rewards(hero, reward, won?) do
    gold = reward[:gold] || 0
    xp = reward[:xp] || 0

    hero
    |> Hero.changeset(%{
      gold: hero.gold + gold,
      xp: hero.xp + xp,
      status: :idle
    })
    |> Repo.update()

    if won? do
      Phoenix.PubSub.broadcast(GodvilleSk.PubSub, "hero:#{hero.id}", {:arena_victory, reward})
    else
      Phoenix.PubSub.broadcast(GodvilleSk.PubSub, "hero:#{hero.id}", {:arena_defeat, reward})
    end
  end

  defp broadcast_start(state) do
    Enum.each(state.team1 ++ state.team2, fn hero_id ->
      Phoenix.PubSub.broadcast(GodvilleSk.PubSub, "hero:#{hero_id}", {:arena_start, state.id})
    end)
  end

  defp broadcast_attack(attacker_id, target_id, arena_id) do
    Phoenix.PubSub.broadcast(
      GodvilleSk.PubSub,
      "hero:#{attacker_id}",
      {:arena_attack, %{arena_id: arena_id, target_id: target_id}}
    )
  end

  defp broadcast_arena_result(state) do
    Enum.each(state.team1 ++ state.team2, fn hero_id ->
      Phoenix.PubSub.broadcast(
        GodvilleSk.PubSub,
        "hero:#{hero_id}",
        {:arena_result, %{arena_id: state.id, winner: state.winner, rewards: state.rewards}}
      )
    end)
  end
end
