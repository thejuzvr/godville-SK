defmodule GodvilleSkWeb.TempleLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game
  alias GodvilleSk.Game.HeroTemple
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
          if hero_state && hero_state.temple do
            %{hero_state | temple: Map.from_struct(hero_state.temple)}
          else
            hero_state
          end

        {:ok,
         socket
         |> assign(:hero, hero)
         |> assign(:hero_state, hero_state || %{})
         |> assign(:donation_amount, 100)}
    end
  end

  def handle_info({:hero_update, hero_state}, socket) do
    hero_state =
      if hero_state && hero_state.temple do
        %{hero_state | temple: Map.from_struct(hero_state.temple)}
      else
        hero_state
      end

    {:noreply, assign(socket, :hero_state, hero_state || %{})}
  end

  def handle_event("donate", %{"amount" => amount}, socket) do
    hero = socket.assigns.hero
    hero_state = socket.assigns.hero_state

    case Integer.parse(amount) do
      {donation, _} when donation > 0 ->
        if hero_state.gold >= donation do
          :ok = GodvilleSk.Hero.donate(hero.name, donation)
          {:noreply, socket}
        else
          {:noreply, put_flash(socket, :error, "Недостаточно золота!")}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("set_donation", %{"amount" => amount}, socket) do
    {:noreply, assign(socket, :donation_amount, String.to_integer(amount))}
  end

  def render(assigns) do
    hero_state = @hero_state || %{}

    temple = Map.get(hero_state, :temple) || %{}
    progress = temple[:construction_progress] || 0
    total_invested = temple[:total_invested] || 0
    donations_count = temple[:donations_count] || 0
    residents = temple[:residents] || []
    enemies = temple[:enemies] || []
    events = temple[:temple_events] || []

    temple_struct = struct(GodvilleSk.Game.HeroTemple, temple)
    bonuses = HeroTemple.get_bonuses(temple_struct)

    ~H"""
    <div class="flex flex-col h-screen bg-background text-foreground font-body overflow-hidden relative">
      <div class="absolute inset-0 bg-[url('/images/login-bg2.jpg')] bg-cover bg-center opacity-10 pointer-events-none"></div>

      <div class="relative z-10 border-b-2 border-border/80 bg-background/90 backdrop-blur-sm">
        <.game_nav active_tab={:temple} />
      </div>

      <main class="flex-1 overflow-y-auto p-4 lg:p-8 max-w-6xl mx-auto w-full relative z-10 custom-scrollbar">
        <header class="mb-10 text-center relative py-12 border-y-4 border-double border-primary/30 bg-gradient-to-b from-primary/5 to-transparent">
          <div class="absolute inset-0 opacity-[0.03] pointer-events-none">
            <svg class="w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
              <path d="M0 100 L50 0 L100 100 Z" fill="currentColor" />
            </svg>
          </div>
          <div class="absolute top-0 left-1/2 -translate-x-1/2 w-48 h-1 bg-primary/40"></div>
          
          <h1 class="font-headline text-5xl text-primary uppercase tracking-[0.3em] mb-4 drop-shadow-[0_0_15px_rgba(200,150,50,0.5)]">
            Храм Даэдра
          </h1>
          <p class="text-foreground/50 text-[11px] uppercase tracking-widest max-w-xl mx-auto leading-loose font-headline">
            Ваше величие измеряется камнями этого храма. Возведите монумент, достойный Принца, и последователи стекутся под вашу тень.
          </p>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 mb-8">
          <!-- Construction Progress -->
          <section class="lg:col-span-7 bg-background/80 border border-border/80 p-8 backdrop-blur-md relative transform">
            <div class="absolute top-0 right-0 w-3 h-3 border-t-2 border-r-2 border-primary/50"></div>
            <div class="absolute bottom-0 left-0 w-3 h-3 border-b-2 border-l-2 border-primary/50"></div>

            <h2 class="font-headline text-xl text-primary uppercase tracking-[0.2em] mb-8 pb-4 border-b border-border/40 flex items-center justify-between">
              <span class="flex items-center gap-3">
                <span class="w-1.5 h-1.5 bg-primary transform rotate-45"></span>
                Статус строительства
              </span>
              <span class="text-[10px] text-primary/40">СВЕТИЛИЩЕ: УРОВЕНЬ <%= trunc(progress / 25) %></span>
            </h2>

            <div class="space-y-10">
              <div>
                <div class="flex justify-between items-end mb-2">
                  <span class="text-[10px] text-foreground/40 font-headline uppercase tracking-widest">Прогресс возведения</span>
                  <span class="text-4xl font-headline text-primary tracking-widest drop-shadow-md"><%= progress %>%</span>
                </div>
                <div class="w-full h-3 bg-background border border-border/50 p-[1px]">
                  <div
                    class="h-full bg-primary shadow-[0_0_15px_rgba(var(--primary-rgb),0.5)] transition-all duration-1000 relative overflow-hidden"
                    style={"width: #{progress}%"}
                  >
                    <div class="absolute inset-0 bg-[url('/images/noise.png')] opacity-10 mix-blend-overlay"></div>
                  </div>
                </div>
              </div>

              <div class="grid grid-cols-2 gap-px bg-border/40 border border-border/60">
                <div class="p-5 bg-background/90 text-center">
                  <span class="text-[9px] text-foreground/40 font-headline uppercase tracking-widest block mb-2">
                    Вложено септимов
                  </span>
                  <span class="text-xl font-headline text-yellow-500 tracking-wider"><%= total_invested %> / 5000</span>
                </div>
                <div class="p-5 bg-background/90 text-center">
                  <span class="text-[9px] text-foreground/40 font-headline uppercase tracking-widest block mb-2">
                    Акты веры
                  </span>
                  <span class="text-xl font-headline text-primary tracking-wider"><%= donations_count %></span>
                </div>
              </div>

              <div class="pt-2 border-t border-border/30">
                <h3 class="text-[9px] text-foreground/30 font-headline uppercase tracking-widest mb-3 text-center">
                  Сумма пожертвования
                </h3>
                <div class="flex gap-1 mb-4 border border-border/40 bg-background/50 p-1">
                  <%= for amount <- [50, 100, 500, 1000] do %>
                    <button
                      phx-click="set_donation"
                      phx-value-amount={amount}
                      class={"flex-1 py-3 text-[10px] font-headline uppercase tracking-widest transition-all #{if @donation_amount == amount, do: "bg-primary/20 text-primary border border-primary/50 shadow-[inset_0_0_10px_rgba(var(--primary-rgb),0.1)]", else: "text-foreground/50 hover:bg-white/5 border border-transparent"}"}
                    >
                      <%= amount %>
                    </button>
                  <% end %>
                </div>

                <button
                  phx-click="donate"
                  phx-value-amount={@donation_amount}
                  class="w-full py-4 text-xs font-headline uppercase tracking-[0.2em] border border-primary/50 bg-primary/10 text-primary hover:bg-primary/20 transition-all disabled:opacity-30 relative group overflow-hidden"
                  disabled={@hero_state.gold < @donation_amount}
                >
                  <div class="absolute inset-0 bg-primary/20 translate-y-full group-hover:translate-y-0 transition-transform duration-300"></div>
                  <span class="relative z-10 flex items-center justify-center gap-2">
                    Пожертвовать <span class="font-bold border-b border-primary/40"><%= @donation_amount %></span> септимов
                  </span>
                </button>
                <div class="text-center mt-2 text-[9px] font-headline uppercase tracking-widest text-foreground/40">
                  Баланс: <span class="text-yellow-500/70"><%= @hero_state.gold %></span> зол.
                </div>
              </div>
            </div>
          </section>

          <!-- Active Benefits -->
          <section class="lg:col-span-5 bg-background/80 border border-border/80 p-8 backdrop-blur-md relative">
            <div class="absolute top-0 right-0 w-3 h-3 border-t-2 border-r-2 border-primary/50"></div>
            <div class="absolute bottom-0 left-0 w-3 h-3 border-b-2 border-l-2 border-primary/50"></div>

            <h2 class="font-headline text-xl text-primary uppercase tracking-[0.2em] mb-8 pb-4 border-b border-border/40 flex items-center gap-3">
              <span class="w-1.5 h-1.5 bg-primary transform rotate-45"></span>
              Влияние храма
            </h2>

            <div class="space-y-4">
              <%= if bonuses.gold_bonus > 0 do %>
                <div class="flex items-center gap-4 p-4 bg-background border border-emerald-900/30 border-l-4 border-l-emerald-500 relative">
                  <div class="absolute right-0 top-0 bottom-0 w-16 bg-gradient-to-l from-emerald-900/20 to-transparent pointer-events-none"></div>
                  <div class="text-emerald-500 border border-emerald-900/50 p-2 bg-emerald-900/20">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <div>
                    <div class="text-[10px] font-headline uppercase tracking-widest text-emerald-400 mb-1">Благословение Злата</div>
                    <div class="text-sm font-bold text-foreground/80">
                      +<%= bonuses.gold_bonus %>% к добыче
                    </div>
                  </div>
                </div>
              <% else %>
                <div class="border border-dashed border-border/20 p-6 text-center text-[9px] uppercase font-headline tracking-widest text-foreground/30">
                  Ауры молчат.<br/>Заложите первый камень.
                </div>
              <% end %>

              <%= if bonuses.luck_bonus > 0 do %>
                <div class="flex items-center gap-4 p-4 bg-background border border-amber-900/30 border-l-4 border-l-amber-500 relative">
                  <div class="absolute right-0 top-0 bottom-0 w-16 bg-gradient-to-l from-amber-900/20 to-transparent pointer-events-none"></div>
                  <div class="text-amber-500 border border-amber-900/50 p-2 bg-amber-900/20">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                    </svg>
                  </div>
                  <div>
                    <div class="text-[10px] font-headline uppercase tracking-widest text-amber-400 mb-1">Щит Судьбы</div>
                    <div class="text-sm font-bold text-foreground/80">
                      +<%= bonuses.luck_bonus %> к удаче
                    </div>
                  </div>
                </div>
              <% end %>

              <%= if bonuses.xp_bonus > 0 do %>
                <div class="flex items-center gap-4 p-4 bg-background border border-purple-900/30 border-l-4 border-l-purple-500 relative">
                  <div class="absolute right-0 top-0 bottom-0 w-16 bg-gradient-to-l from-purple-900/20 to-transparent pointer-events-none"></div>
                  <div class="text-purple-500 border border-purple-900/50 p-2 bg-purple-900/20">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  </div>
                  <div>
                    <div class="text-[10px] font-headline uppercase tracking-widest text-purple-400 mb-1">Поток Душ</div>
                    <div class="text-sm font-bold text-foreground/80">
                      +<%= bonuses.xp_bonus %>% к опыту
                    </div>
                  </div>
                </div>
              <% end %>

              <div class="mt-8 border-t border-border/30 pt-4 px-2 text-center">
                <span class="text-[9px] font-headline uppercase tracking-widest text-primary/70">
                  <span class="mr-2 opacity-50">#</span>
                  <%= case progress do
                    p when p >= 100 -> "Монумент Абсолюта Завершён"
                    p when p >= 75 -> "Следующая печать: Эманация Мощи"
                    p when p >= 50 -> "Следующая печать: Великая Жертва"
                    p when p >= 25 -> "Следующая печать: Средний Алтарь"
                    p when p >= 5 -> "Следующая печать: Малый Алтарь"
                    _ -> "Следующая печать: Фундамент"
                  end %>
                </span>
              </div>
            </div>
          </section>
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-2 gap-8">
          <div>
            <!-- Residents -->
            <%= if length(residents) > 0 do %>
              <section class="bg-background/80 border border-border/80 p-6 backdrop-blur-md mb-8">
                <h2 class="font-headline text-[13px] text-blue-400 uppercase tracking-widest flex items-center justify-between mb-4 pb-2 border-b border-border/30">
                  <span class="flex items-center gap-2">
                     <span class="w-1.5 h-1.5 bg-blue-500"></span> Паства
                  </span>
                  <span class="text-[9px] text-blue-500/50"><%= length(residents) %> душ</span>
                </h2>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <%= for resident <- residents do %>
                    <div class="flex items-center p-2.5 bg-background border border-border/30 hover:border-blue-500/50 transition-colors">
                      <div class="w-6 h-6 bg-blue-900/30 border border-blue-500/30 flex items-center justify-center mr-3 text-blue-400 shrink-0">
                        <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                      </div>
                      <span class="text-[11px] font-headline uppercase tracking-wider text-foreground/80 truncate"><%= resident %></span>
                    </div>
                  <% end %>
                </div>
              </section>
            <% end %>

            <!-- Enemies -->
            <%= if length(enemies) > 0 do %>
              <section class="bg-background/80 border border-border/80 p-6 backdrop-blur-md">
                <h2 class="font-headline text-[13px] text-red-500 uppercase tracking-widest flex items-center justify-between mb-4 pb-2 border-b border-border/30">
                  <span class="flex items-center gap-2">
                     <span class="w-1.5 h-1.5 bg-red-600"></span> Еретики
                  </span>
                  <span class="text-[9px] text-red-500/50">Атаки: <%= temple[:enemy_encounters] || 0 %></span>
                </h2>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <%= for enemy <- enemies do %>
                    <div class="flex items-center p-2.5 bg-background border border-border/30 hover:border-red-500/50 transition-colors">
                      <div class="w-6 h-6 bg-red-900/30 border border-red-500/30 flex items-center justify-center mr-3 text-red-500 shrink-0 font-headline text-[10px]">
                        X
                      </div>
                      <span class="text-[11px] font-headline uppercase tracking-wider text-foreground/80 truncate"><%= enemy %></span>
                    </div>
                  <% end %>
                </div>
              </section>
            <% end %>
          </div>

          <!-- Events -->
          <%= if length(events) > 0 do %>
            <section class="bg-background/80 border border-border/80 p-6 backdrop-blur-md h-fit">
              <h2 class="font-headline text-[13px] text-foreground/60 uppercase tracking-widest mb-4 pb-2 border-b border-border/30 flex items-center gap-2">
                <span class="w-1.5 h-1.5 bg-foreground/40"></span>
                Хроника Монумента
              </h2>

              <div class="space-y-2 max-h-[400px] overflow-y-auto custom-scrollbar pr-2">
                <%= for event <- events do %>
                  <div class="p-3 bg-background/50 border border-border/20 flex gap-3 group hover:border-primary/20 transition-colors">
                    <div class="shrink-0 pt-0.5">
                      <%= case event[:type] do
                        :enemy_attack -> "<span class='text-red-500 text-[10px] font-headline'>[!!!]</span>"
                        :donation -> "<span class='text-primary text-[10px] font-headline'>[$$$]</span>"
                        :construction -> "<span class='text-purple-400 text-[10px] font-headline'>[+++]</span>"
                        _ -> "<span class='text-foreground/40 text-[10px] font-headline'>[INF]</span>"
                      end |> raw() %>
                    </div>
                    <div class="text-[11px] text-foreground/70 leading-relaxed font-body">
                      <%= event[:message] %>
                    </div>
                  </div>
                <% end %>
              </div>
            </section>
          <% end %>
        </div>
      </main>
    </div>
    """
  end
end