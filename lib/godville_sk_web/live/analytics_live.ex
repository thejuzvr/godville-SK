defmodule GodvilleSkWeb.AnalyticsLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game
  alias GodvilleSk.Game.Achievements
  import GodvilleSkWeb.NavComponents

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    case Game.get_hero_by_user_id(user.id) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/hero/new")}

      hero ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(GodvilleSk.PubSub, "hero:#{hero.id}")
        end

        hero_state = Game.get_hero_live_state(hero)

        hero_state =
          if hero_state && hero_state.statistics do
            %{hero_state | statistics: Map.from_struct(hero_state.statistics)}
          else
            hero_state
          end

        {:ok,
         socket
         |> assign(:hero, hero)
         |> assign(:hero_state, hero_state || %{})
         |> assign(:selected_category, :all)}
    end
  end

  def handle_info({:hero_update, hero_state}, socket) do
    hero_state =
      if hero_state && hero_state.statistics do
        %{hero_state | statistics: Map.from_struct(hero_state.statistics)}
      else
        hero_state
      end

    {:noreply, assign(socket, :hero_state, hero_state || %{})}
  end

  def handle_event("filter_category", %{"category" => category}, socket) do
    {:noreply, assign(socket, :selected_category, String.to_atom(category))}
  end

  def render(assigns) do
    hero_state = @hero_state || %{}
    stats = Map.get(hero_state, :statistics) || %{}
    achievements = Achievements.get_all_achievements()

    filtered_achievements =
      case @selected_category do
        :all -> achievements
        cat -> Achievements.get_achievements_by_category(cat)
      end

    unlocked_ids = Map.get(stats, :unlocked_achievements, [])

    ~H"""
    <div class="flex flex-col h-screen bg-background text-foreground font-body overflow-hidden">
      <.game_nav active_tab={:analytics} />

      <main class="flex-1 overflow-y-auto p-6 max-w-5xl mx-auto w-full">
        <header class="mb-8">
          <h1 class="font-headline text-3xl text-primary uppercase tracking-widest mb-2">
            Аналитика приключений
          </h1>
          <p class="text-foreground/50 text-sm italic">
            "Даже богам интересно, сколько дорог истоптал их смертный подопечный."
          </p>
        </header>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-10">
          <.stat_card
            label="Уровень"
            value={Map.get(hero_state, :level, 1)}
            icon="M13 10V3L4 14h7v7l9-11h-7z"
            color="text-purple-500"
            description="Текущий уровень героя"
          />
          <.stat_card
            label="XP"
            value={Map.get(hero_state, :xp, 0)}
            icon="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            color="text-yellow-500"
            description="Опыт"
          />
          <.stat_card
            label="Золото"
            value={Map.get(hero_state, :gold, 0)}
            icon="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            color="text-amber-500"
            description="Текущее золото"
          />
          <.stat_card
            label="Победы"
            value={Map.get(stats, :total_wins, 0)}
            icon="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
            color="text-emerald-500"
            description="Число поверженных врагов"
          />
        </div>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-10">
          <.stat_card
            label="Монстры"
            value={Map.get(stats, :total_monsters_killed, 0)}
            icon="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            color="text-red-500"
            description="Убито монстров"
          />
          <.stat_card
            label="Подземелья"
            value={Map.get(stats, :dungeons_cleared, 0)}
            icon="M19 11H5m14 0a2 2 0 012 2h6a2 2 0 012 2v6a2 2 0 01-2 2H7a2 2 0 01-2-2v-6z"
            color="text-cyan-500"
            description="Очищено подземелий"
          />
          <.stat_card
            label="Города"
            value={length(Map.get(stats, :cities_visited, []))}
            icon="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"
            color="text-blue-500"
            description="Посещено городов"
          />
          <.stat_card
            label="Квесты"
            value={Map.get(stats, :total_quests, 0)}
            icon="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            color="text-indigo-500"
            description="Выполнено квестов"
          />
        </div>

        <section class="mb-10">
          <div class="flex items-center justify-between mb-6 border-b border-border/50 pb-2">
            <h2 class="font-headline text-xl text-foreground/80 uppercase tracking-wider">
              Достижения
            </h2>
            <div class="flex gap-2">
              <button
                phx-click="filter_category"
                phx-value-category="all"
                class={"text-xs px-2 py-1 rounded border #{if @selected_category == :all, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/50 hover:border-primary/40"}"}
              >
                Все
              </button>
              <button
                phx-click="filter_category"
                phx-value-category="combat"
                class={"text-xs px-2 py-1 rounded border #{if @selected_category == :combat, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/50 hover:border-primary/40"}"}
              >
                Бой
              </button>
              <button
                phx-click="filter_category"
                phx-value-category="exploration"
                class={"text-xs px-2 py-1 rounded border #{if @selected_category == :exploration, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/50 hover:border-primary/40"}"}
              >
                Поиск
              </button>
              <button
                phx-click="filter_category"
                phx-value-category="wealth"
                class={"text-xs px-2 py-1 rounded border #{if @selected_category == :wealth, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/50 hover:border-primary/40"}"}
              >
                Богатство
              </button>
              <button
                phx-click="filter_category"
                phx-value-category="skill"
                class={"text-xs px-2 py-1 rounded border #{if @selected_category == :skill, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/50 hover:border-primary/40"}"}
              >
                Навыки
              </button>
              <button
                phx-click="filter_category"
                phx-value-category="special"
                class={"text-xs px-2 py-1 rounded border #{if @selected_category == :special, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/50 hover:border-primary/40"}"}
              >
                Особые
              </button>
            </div>
          </div>

          <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            <%= for achievement <- filtered_achievements do %>
              <% progress =
                Achievements.get_achievement_progress(achievement.id, %{
                  statistics: stats,
                  level: Map.get(hero_state, :level, 1),
                  gold: Map.get(hero_state, :gold, 0),
                  temple: %{construction_progress: 0, total_invested: 0, donations_count: 0}
                }) %>
              <div class={"p-4 rounded-lg border transition-all #{if progress.unlocked, do: "bg-card/50 border-primary/30", else: "bg-card/20 border-border/30 opacity-70"}"}>
                <div class="flex items-center gap-3 mb-3">
                  <div class={"w-10 h-10 rounded-full flex items-center justify-center #{if progress.unlocked, do: "bg-primary/20 text-primary", else: "bg-background/40 text-foreground/30"}"}>
                    <svg
                      class="w-5 h-5"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      stroke-width="2"
                    >
                      <path d={achievement.icon} />
                    </svg>
                  </div>
                </div>
                <h3 class="font-headline text-sm text-foreground mb-1">{achievement.name}</h3>
                <p class="text-[10px] text-foreground/40 mb-2">{achievement.description}</p>
                <div class="w-full h-1.5 bg-background/40 rounded-full overflow-hidden">
                  <div
                    class={"h-full transition-all duration-500 #{if progress.unlocked, do: "bg-primary", else: "bg-foreground/20"}"}
                    style={"width: #{progress.percentage}%"}
                  >
                  </div>
                </div>
                <div class="text-[9px] text-foreground/30 mt-1 text-right">
                  <%= if progress.unlocked do %>
                    Разблокировано
                  <% else %>
                    <%= progress.progress %>/<%= progress.max %>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </section>

        <footer class="mt-12 pt-8 border-t border-border/20 flex justify-between text-[10px] text-foreground/30 uppercase tracking-widest">
          <span>Разблокировано: <%= length(unlocked_ids) %>/20</span>
          <span>Hero ID: <%= @hero.id %></span>
        </footer>
      </main>
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class="bg-card/30 border border-border/50 p-5 rounded-lg backdrop-blur-sm hover:border-primary/40 transition-all group overflow-hidden relative">
      <div class={"absolute -right-4 -top-4 opacity-5 group-hover:opacity-10 transition-opacity #{@color}"}>
        <svg class="w-24 h-24" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path d={@icon} />
        </svg>
      </div>
      <div class="flex items-center gap-3 mb-4">
        <div class={"p-2 rounded-md bg-background/50 border border-border/30 #{@color}"}>
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path d={@icon} />
          </svg>
        </div>
        <span class="text-xs font-headline text-foreground/50 uppercase tracking-wider">
          <%= @label %>
        </span>
      </div>
      <div class="text-4xl font-headline text-foreground mb-2"><%= @value %></div>
      <p class="text-[10px] text-foreground/40 leading-relaxed"><%= @description %></p>
    </div>
    """
  end
end
