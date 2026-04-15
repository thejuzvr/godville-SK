defmodule GodvilleSk.Game.Achievements do
  @moduledoc """
  Achievement system with 20 achievements across 5 categories.
  """

  defmodule Achievement do
    defstruct [:id, :name, :description, :category, :requirement, :icon]

    def new(id, name, description, category, requirement, icon) do
      %__MODULE__{
        id: id,
        name: name,
        description: description,
        category: category,
        requirement: requirement,
        icon: icon
      }
    end
  end

  def get_all_achievements do
    [
      # Combat - 5 achievements
      Achievement.new(
        "first_blood",
        "Первая кровь",
        "Первая победа в бою",
        :combat,
        fn state -> (state.statistics.total_wins || 0) >= 1 end,
        "M13 10V3L4 14h7v7l9-11h-7z"
      ),
      Achievement.new(
        "monster_slayer",
        "Истребитель монстров",
        "Убить 50 монстров",
        :combat,
        fn state -> (state.statistics.total_monsters_killed || 0) >= 50 end,
        "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
      ),
      Achievement.new(
        "giant_hunter",
        "Охотник на великанов",
        "Убить 10 боссов",
        :combat,
        fn state -> (state.statistics.total_bosses_killed || 0) >= 10 end,
        "M12 2l2.24 4.48 4.76.48-3.52 3.52 3.52-3.52 4.76.48L12 22l-4.76-.48 4.76-.48-3.52-3.52-3.52 3.52L9.76 6.48 12 2z"
      ),
      Achievement.new(
        "master_of_escape",
        "Мастер побега",
        "10 успешных побегов из боя",
        :combat,
        fn state -> (state.statistics.successful_escapes || 0) >= 10 end,
        "M13 10V3L4 14h7v7l9-11h-7z"
      ),
      Achievement.new(
        "invincible",
        "Непобедимый",
        "5 побед подряд без получения урона",
        :combat,
        fn state -> (state.statistics.longest_combat_streak || 0) >= 5 end,
        "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
      ),

      # Exploration - 4 achievements
      Achievement.new(
        "wanderer",
        "Странник",
        "Посетить 10 городов",
        :exploration,
        fn state -> length(state.statistics.cities_visited || []) >= 10 end,
        "M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"
      ),
      Achievement.new(
        "discoverer",
        "Первооткрыватель",
        "Посетить все типы локаций",
        :exploration,
        fn state -> length(state.statistics.cities_visited || []) >= 5 end,
        "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
      ),
      Achievement.new(
        "dungeon_conqueror",
        "Покоритель подземелий",
        "Очистить 5 подземелий",
        :exploration,
        fn state -> (state.statistics.dungeons_cleared || 0) >= 5 end,
        "M19 11H5m14 0a2 2 0 012 2h6a2 2 0 012 2v6a2 2 0 01-2 2H7a2 2 0 01-2-2v-6z"
      ),
      Achievement.new(
        "pathfinder",
        "Следопыт",
        "Пройти 1000 единиц расстояния",
        :exploration,
        fn state -> (state.statistics.total_distance_traveled || 0) >= 1000 end,
        "M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"
      ),

      # Wealth - 4 achievements
      Achievement.new(
        "trader",
        "Торговец",
        "Заработать 1000 золотых",
        :wealth,
        fn state -> (state.statistics.total_gold_earned || 0) >= 1000 end,
        "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      ),
      Achievement.new(
        "rich",
        "Богач",
        "Накопить 5000 золотых одновременно",
        :wealth,
        fn state -> (state.gold || 0) >= 5000 end,
        "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      ),
      Achievement.new(
        "collector",
        "Коллекционер",
        "Собрать 100 предметов",
        :wealth,
        fn state -> (state.statistics.total_items_collected || 0) >= 100 end,
        "M19 11H5m14 0a2 2 0 012 2h6a2 2 0 012 2v6a2 2 0 01-2 2H7a2 2 0 01-2-2v-6z"
      ),
      Achievement.new(
        "investor",
        "Инвестор",
        "Вложить деньги в храм (1000+ золотых)",
        :wealth,
        fn state -> (state.temple.total_invested || 0) >= 1000 end,
        "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      ),

      # Skills - 4 achievements
      Achievement.new(
        "apprentice",
        "Ученик",
        "Достичь 5 уровня",
        :skill,
        fn state -> (state.level || 1) >= 5 end,
        "M13 10V3L4 14h7v7l9-11h-7z"
      ),
      Achievement.new(
        "veteran",
        "Ветеран",
        "Достичь 10 уровня",
        :skill,
        fn state -> (state.level || 1) >= 10 end,
        "M13 10V3L4 14h7v7l9-11h-7z"
      ),
      Achievement.new(
        "master",
        "Мастер",
        "Достичь 20 уровня",
        :skill,
        fn state -> (state.level || 1) >= 20 end,
        "M13 10V3L4 14h7v7l9-11h-7z"
      ),
      Achievement.new(
        "legend",
        "Легенда",
        "Достичь 30 уровня",
        :skill,
        fn state -> (state.level || 1) >= 30 end,
        "M13 10V3L4 14h7v7l9-11h-7z"
      ),

      # Special - 3 achievements
      Achievement.new(
        "death_and_resurrection",
        "Смерть и воскрешение",
        "Умереть и воскреснуть",
        :special,
        fn state -> (state.statistics.total_deaths || 0) >= 1 end,
        "M12 2v20M2 12h20"
      ),
      Achievement.new(
        "daedric_temple",
        "Храм Даэдра",
        "Построить храм до 25%",
        :special,
        fn state -> (state.temple.construction_progress || 0) >= 25 end,
        "M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
      ),
      Achievement.new(
        "believer",
        "Верующий",
        "Внести 10 пожертвований в храм",
        :special,
        fn state -> (state.temple.donations_count || 0) >= 10 end,
        "M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
      )
    ]
  end

  def get_achievements_by_category(category) do
    Enum.filter(get_all_achievements(), fn a -> a.category == category end)
  end

  def get_achievement(id) do
    Enum.find(get_all_achievements(), fn a -> a.id == id end)
  end

  def check_achievements(state) do
    unlocked = state.statistics.unlocked_achievements || []

    new_unlocked =
      Enum.reduce(get_all_achievements(), unlocked, fn achievement, acc ->
        if achievement.id in acc do
          acc
        else
          case achievement.requirement.(state) do
            true -> [achievement.id | acc]
            _ -> acc
          end
        end
      end)

    if new_unlocked != unlocked do
      newly_unlocked = new_unlocked -- unlocked

      statistics =
        if is_map(state.statistics) do
          Map.put(state.statistics, :unlocked_achievements, new_unlocked)
        else
          %{state.statistics | unlocked_achievements: new_unlocked}
        end

      state = Map.put(state, :statistics, statistics)
      {state, newly_unlocked}
    else
      {state, []}
    end
  end

  def get_achievement_progress(achievement_id, state) do
    achievement = get_achievement(achievement_id)

    case achievement do
      nil ->
        %{unlocked: false, progress: 0, max: 1, percentage: 0}

      _ ->
        stats = state.statistics
        level = state.level || 1
        gold = state.gold || 0
        temple = state.temple || %{}

        case achievement.id do
          "first_blood" ->
            wins = stats[:total_wins] || 0
            %{unlocked: wins >= 1, progress: wins, max: 1, percentage: min(wins * 100, 100)}

          "monster_slayer" ->
            killed = stats[:total_monsters_killed] || 0

            %{
              unlocked: killed >= 50,
              progress: killed,
              max: 50,
              percentage: min(div(killed * 100, 50), 100)
            }

          "giant_hunter" ->
            bosses = stats[:total_bosses_killed] || 0

            %{
              unlocked: bosses >= 10,
              progress: bosses,
              max: 10,
              percentage: min(div(bosses * 100, 10), 100)
            }

          "master_of_escape" ->
            escapes = stats[:successful_escapes] || 0

            %{
              unlocked: escapes >= 10,
              progress: escapes,
              max: 10,
              percentage: min(escapes * 10, 100)
            }

          "invincible" ->
            streak = stats[:longest_combat_streak] || 0
            %{unlocked: streak >= 5, progress: streak, max: 5, percentage: min(streak * 20, 100)}

          "wanderer" ->
            cities = length(stats[:cities_visited] || [])

            %{
              unlocked: cities >= 10,
              progress: cities,
              max: 10,
              percentage: min(cities * 10, 100)
            }

          "discoverer" ->
            locations = length(state.statistics.cities_visited || [])

            %{
              unlocked: locations >= 5,
              progress: locations,
              max: 5,
              percentage: min(locations * 20, 100)
            }

          "dungeon_conqueror" ->
            dungeons = stats[:dungeons_cleared] || 0

            %{
              unlocked: dungeons >= 5,
              progress: dungeons,
              max: 5,
              percentage: min(dungeons * 20, 100)
            }

          "pathfinder" ->
            distance = stats[:total_distance_traveled] || 0

            %{
              unlocked: distance >= 1000,
              progress: distance,
              max: 1000,
              percentage: min(div(distance, 10), 100)
            }

          "trader" ->
            earned = stats[:total_gold_earned] || 0

            %{
              unlocked: earned >= 1000,
              progress: earned,
              max: 1000,
              percentage: min(div(earned, 10), 100)
            }

          "rich" ->
            %{
              unlocked: gold >= 5000,
              progress: gold,
              max: 5000,
              percentage: min(div(gold * 100, 5000), 100)
            }

          "collector" ->
            items = stats[:total_items_collected] || 0
            %{unlocked: items >= 100, progress: items, max: 100, percentage: min(items, 100)}

          "investor" ->
            invested = temple[:total_invested] || 0

            %{
              unlocked: invested >= 1000,
              progress: invested,
              max: 1000,
              percentage: min(div(invested * 100, 1000), 100)
            }

          "apprentice" ->
            %{unlocked: level >= 5, progress: level, max: 5, percentage: min(level * 20, 100)}

          "veteran" ->
            %{unlocked: level >= 10, progress: level, max: 10, percentage: min(level * 10, 100)}

          "master" ->
            %{
              unlocked: level >= 20,
              progress: level,
              max: 20,
              percentage: min(div(level * 100, 20), 100)
            }

          "legend" ->
            %{
              unlocked: level >= 30,
              progress: level,
              max: 30,
              percentage: min(div(level * 100, 30), 100)
            }

          "death_and_resurrection" ->
            deaths = stats[:total_deaths] || 0
            %{unlocked: deaths >= 1, progress: deaths, max: 1, percentage: min(deaths * 100, 100)}

          "daedric_temple" ->
            progress = temple[:construction_progress] || 0

            %{
              unlocked: progress >= 25,
              progress: progress,
              max: 25,
              percentage: min(progress * 4, 100)
            }

          "believer" ->
            donations = temple[:donations_count] || 0

            %{
              unlocked: donations >= 10,
              progress: donations,
              max: 10,
              percentage: min(donations * 10, 100)
            }

          _ ->
            %{unlocked: false, progress: 0, max: 1, percentage: 0}
        end
    end
  end
end
