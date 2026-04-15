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
    <div class="flex flex-col h-screen bg-background text-foreground font-body overflow-hidden relative">
      <div class="absolute inset-0 bg-[url('/images/login-bg2.jpg')] bg-cover bg-center opacity-[0.08] pointer-events-none"></div>

      <div class="relative z-10 border-b-2 border-border/80 bg-background/90 backdrop-blur-sm">
        <.game_nav active_tab={:analytics} />
      </div>

      <main class="flex-1 overflow-y-auto p-6 max-w-6xl mx-auto w-full relative z-10 custom-scrollbar">
        <header class="mb-10 text-center border-b border-border/40 pb-6 relative">
          <div class="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-[1px] bg-primary/50"></div>
          <h1 class="font-headline text-3xl text-primary uppercase tracking-[0.2em] mb-4">
            Аналитика приключений
          </h1>
          <p class="text-foreground/40 text-[10px] uppercase tracking-widest font-headline">
            "Даже богам интересно, сколько дорог истоптал их смертный подопечный."
          </p>
        </header>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-1 mb-10 bg-border/30 border border-border/50 p-1">
          <.stat_card label="Уровень" value={Map.get(hero_state, :level, 1)} icon="M13 10V3L4 14h7v7l9-11h-7z" color="text-purple-400" border_color="border-purple-900/50" description="Текущий уровень героя" />
          <.stat_card label="XP" value={Map.get(hero_state, :xp, 0)} icon="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" color="text-yellow-500" border_color="border-yellow-900/50" description="Опыт" />
          <.stat_card label="Золото" value={Map.get(hero_state, :gold, 0)} icon="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" color="text-amber-400" border_color="border-amber-900/50" description="Текущее золото" />
          <.stat_card label="Победы" value={Map.get(stats, :total_wins, 0)} icon="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" color="text-emerald-400" border_color="border-emerald-900/50" description="Число поверженных врагов" />
        </div>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-1 mb-12 bg-border/30 border border-border/50 p-1">
          <.stat_card label="Монстры" value={Map.get(stats, :total_monsters_killed, 0)} icon="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" color="text-red-400" border_color="border-red-900/50" description="Убито монстров" />
          <.stat_card label="Подземелья" value={Map.get(stats, :dungeons_cleared, 0)} icon="M19 11H5m14 0a2 2 0 012 2h6a2 2 0 012 2v6a2 2 0 01-2 2H7a2 2 0 01-2-2v-6z" color="text-cyan-400" border_color="border-cyan-900/50" description="Очищено подземелий" />
          <.stat_card label="Города" value={length(Map.get(stats, :cities_visited, []))} icon="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" color="text-blue-400" border_color="border-blue-900/50" description="Посещено городов" />
          <.stat_card label="Квесты" value={Map.get(stats, :total_quests, 0)} icon="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" color="text-indigo-400" border_color="border-indigo-900/50" description="Выполнено квестов" />
        </div>

        <section class="mb-10 border border-border/50 bg-background/80 backdrop-blur-sm relative py-6">
          <div class="absolute top-0 right-0 w-3 h-3 border-t-2 border-r-2 border-primary/50"></div>
          <div class="absolute bottom-0 left-0 w-3 h-3 border-b-2 border-l-2 border-primary/50"></div>

          <div class="flex flex-col md:flex-row md:items-center justify-between mb-8 pb-4 px-6 border-b border-border/40 gap-4">
            <h2 class="font-headline text-xl text-primary/80 uppercase tracking-[0.2em] flex items-center gap-2">
              <span class="w-1.5 h-1.5 bg-primary transform rotate-45"></span>
              Достижения
            </h2>
            <div class="flex flex-wrap gap-0 border border-border/50 bg-background">
              <%= for {value, label} <- [{"all", "Все"}, {"combat", "Бой"}, {"exploration", "Поиск"}, {"wealth", "Богатство"}, {"skill", "Навыки"}, {"special", "Особые"}] do %>
                <button
                  phx-click="filter_category"
                  phx-value-category={value}
                  class={"text-[9px] font-headline uppercase tracking-widest px-4 py-2 transition-all #{if to_string(@selected_category) == value, do: "bg-primary/20 text-primary shadow-[inset_0_0_10px_rgba(var(--primary-rgb),0.2)]", else: "text-foreground/40 hover:bg-white/5 border-l border-border/30 first:border-l-0"}"}
                >
                  <%= label %>
                </button>
              <% end %>
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 px-6">
            <%= for achievement <- filtered_achievements do %>
              <% progress = Achievements.get_achievement_progress(achievement.id, %{statistics: stats, level: Map.get(hero_state, :level, 1), gold: Map.get(hero_state, :gold, 0), temple: %{construction_progress: 0, total_invested: 0, donations_count: 0}}) %>
              <div class={"p-4 border relative group transition-all #{if progress.unlocked, do: "bg-primary/5 border-primary/30", else: "bg-background/40 border-border/20 opacity-80"}"}>
                <div class={"absolute top-0 left-0 w-1 h-full #{if progress.unlocked, do: "bg-primary/80", else: "bg-border/30"}"}></div>
                
                <div class="flex items-start gap-4 mb-3 pl-2">
                  <div class={"w-10 h-10 border flex items-center justify-center shrink-0 #{if progress.unlocked, do: "border-primary/50 text-primary bg-background shadow-[0_0_10px_rgba(var(--primary-rgb),0.2)]", else: "border-border/30 text-foreground/20 bg-background"}"}>
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                      <path d={achievement.icon} />
                    </svg>
                  </div>
                  <div class="flex-1">
                    <h3 class={"font-headline text-[11px] uppercase tracking-widest mb-1 #{if progress.unlocked, do: "text-primary/90", else: "text-foreground/60"}"}><%= achievement.name %></h3>
                    <p class="text-[9px] font-body text-foreground/40 leading-relaxed"><%= achievement.description %></p>
                  </div>
                </div>

                <div class="w-full h-1 bg-background border border-border/40 relative overflow-hidden pl-2">
                  <div class="absolute inset-0 bg-[url('/images/noise.png')] opacity-10"></div>
                  <div
                    class={"h-full transition-all duration-500 shadow-[0_0_5px_currentColor] #{if progress.unlocked, do: "bg-primary", else: "bg-foreground/20"}"}
                    style={"width: #{progress.percentage}%"}
                  >
                  </div>
                </div>
                
                <div class="text-[9px] font-headline uppercase tracking-widest mt-2 text-right">
                  <%= if progress.unlocked do %>
                    <span class="text-primary/80">Достигнуто</span>
                  <% else %>
                    <span class="text-foreground/40"><%= progress.progress %> / <%= progress.max %></span>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </section>

        <footer class="mt-8 pt-4 border-t border-border/20 flex justify-between tracking-widest">
          <span class="text-[9px] text-foreground/30 font-headline uppercase">Записей открыто: <span class="text-primary/50"><%= length(unlocked_ids) %> / 20</span></span>
          <span class="text-[9px] text-foreground/20 font-headline uppercase border border-border/20 px-2 py-0.5">ВЫВОД [<%= @hero.id %>]</span>
        </footer>
      </main>
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class={"bg-background/80 p-6 relative border-l-4 transition-all group overflow-hidden #{@border_color}"}>
      <div class={"absolute -right-4 -bottom-4 opacity-[0.03] group-hover:opacity-10 transition-opacity #{@color} transform group-hover:scale-110 duration-500"}>
        <svg class="w-32 h-32" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path d={@icon} />
        </svg>
      </div>
      
      <div class="flex items-center gap-3 mb-4">
        <div class={"p-1.5 border #{@border_color} bg-background/50 #{@color}"}>
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
            <path d={@icon} />
          </svg>
        </div>
        <span class="text-[9px] font-headline text-foreground/40 uppercase tracking-[0.2em]">
          <%= @label %>
        </span>
      </div>
      
      <div class="text-3xl font-headline text-foreground/90 font-bold tracking-wider mb-2 drop-shadow-sm"><%= @value %></div>
      <p class="text-[9px] text-foreground/30 font-body uppercase tracking-wider"><%= @description %></p>
    </div>
    """
  end
end