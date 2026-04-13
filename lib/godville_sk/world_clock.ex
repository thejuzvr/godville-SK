defmodule GodvilleSk.WorldClock do
  @moduledoc """
  Single source of truth for real time, game time and world conditions.

  Game time scale: 1 real second = 1 game minute.
  World conditions are global for all players.
  """

  use GenServer

  @topic "world"
  @tick_ms 1_000

  # Tamriel-inspired calendar (simplified):
  # 12 months, 28 days each => 336 days/year.
  @days_in_month 28
  @months_in_year 12
  @days_in_year @days_in_month * @months_in_year

  @start_day 8
  @start_month_num 4
  @start_year 202
  @start_era 4

  @months [
    "Утренняя Звезда",
    "Восход Солнца",
    "Первый Зерен",
    "Рука Дождей",
    "Второй Зерен",
    "Середина Лета",
    "Высь Солнца",
    "Последний Зерен",
    "Домашний Огонь",
    "Морозный Листопад",
    "Закат Солнца",
    "Вечерняя Звезда"
  ]

  @days_of_week ["Мондас", "Тирдас", "Мидас", "Турдас", "Фредас", "Лорредас", "Сандас"]

  @weather_pool ["Ясно", "Облачно", "Туман", "Снегопад", "Гроза"]

  # --- Public API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Returns the latest published world snapshot."
  def snapshot do
    GenServer.call(__MODULE__, :snapshot)
  end

  @doc "Converts a real DateTime to a game time struct."
  def game_time_at(%DateTime{} = dt) do
    epoch = :persistent_term.get(:godville_sk_epoch, nil) || DateTime.utc_now()
    compute_game_time(epoch, dt)
  end

  def game_time_at(%NaiveDateTime{} = ndt) do
    game_time_at(DateTime.from_naive!(ndt, "Etc/UTC"))
  end

  @doc "Formats game time as HH:MM."
  def format_clock(%{hour: h, minute: m}) when is_integer(h) and is_integer(m) do
    "#{String.pad_leading(to_string(h), 2, "0")}:#{String.pad_leading(to_string(m), 2, "0")}"
  end

  # --- Callbacks ---

  require Logger

  @impl true
  def init(_state) do
    started_at_real = DateTime.utc_now()
    :persistent_term.put(:godville_sk_epoch, started_at_real)

    state = %{
      started_at_real: started_at_real,
      last_snapshot: build_snapshot(started_at_real, started_at_real)
    }

    Logger.info("[WorldClock] Engine started at #{started_at_real}. Initial game time: #{format_clock(state.last_snapshot.game_time)}")

    schedule_tick()
    {:ok, state}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, state.last_snapshot, state}
  end

  @impl true
  def handle_info(:tick, state) do
    now = DateTime.utc_now()
    snap = build_snapshot(state.started_at_real, now)

    # Heartbeat log every 60 real seconds (approx 60 game minutes)
    if rem(DateTime.diff(now, state.started_at_real), 60) == 0 do
      gt = snap.game_time
      Logger.info("[World] Game Time: #{gt.day_name}, #{gt.day} #{gt.month} #{gt.year} - #{format_clock(gt)} (#{gt.weather})")
    end

    Phoenix.PubSub.broadcast(GodvilleSk.PubSub, @topic, {:world_update, snap})

    schedule_tick()
    {:noreply, %{state | last_snapshot: snap}}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_ms)
  end

  defp build_snapshot(started_at_real, now) do
    game_time = compute_game_time(started_at_real, now)

    %{
      real_time: now,
      game_time: game_time,
      season: game_time.season,
      time_of_day: game_time.time_of_day,
      weather: game_time.weather
    }
  end

  defp compute_game_time(started_at_real, now) do
    seconds_elapsed = DateTime.diff(now, started_at_real)

    # 1 real second = 1 game minute
    game_minutes_elapsed = seconds_elapsed
    game_hour = rem(div(game_minutes_elapsed, 60), 24)
    game_minute = rem(game_minutes_elapsed, 60)
    total_game_days = div(game_minutes_elapsed, 60 * 24)

    # Start day-of-year in a 336-day year:
    start_day_of_year = (@start_month_num - 1) * @days_in_month + (@start_day - 1)
    total_from_start = start_day_of_year + total_game_days

    year_offset = div(total_from_start, @days_in_year)
    day_of_year = rem(total_from_start, @days_in_year)
    month_num = div(day_of_year, @days_in_month) + 1
    day_num = rem(day_of_year, @days_in_month) + 1

    month_name = Enum.at(@months, month_num - 1) || hd(@months)
    day_name = Enum.at(@days_of_week, rem(total_game_days, 7)) || hd(@days_of_week)

    season =
      cond do
        month_num in [3, 4, 5] -> "Весна"
        month_num in [6, 7, 8] -> "Лето"
        month_num in [9, 10, 11] -> "Осень"
        true -> "Зима"
      end

    time_of_day =
      cond do
        game_hour in 5..11 -> "Утро"
        game_hour in 12..17 -> "День"
        game_hour in 18..21 -> "Вечер"
        true -> "Ночь"
      end

    weather =
      Enum.at(@weather_pool, rem(total_game_days * 7 + 3, length(@weather_pool))) ||
        hd(@weather_pool)

    %{
      day_name: day_name,
      day: day_num,
      month: month_name,
      year: @start_year + year_offset,
      era: @start_era,
      hour: game_hour,
      minute: game_minute,
      season: season,
      time_of_day: time_of_day,
      weather: weather
    }
  end
end

