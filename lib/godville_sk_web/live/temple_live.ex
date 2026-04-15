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
    <div class="flex flex-col h-screen bg-background text-foreground font-body overflow-hidden">
      <.game_nav active_tab={:temple} />

      <main class="flex-1 overflow-y-auto p-6 max-w-5xl mx-auto w-full">
        <header class="mb-10 text-center relative py-8 overflow-hidden rounded-xl border border-primary/20 bg-gradient-to-b from-primary/10 to-transparent">
          <div class="absolute inset-0 opacity-5 pointer-events-none">
            <svg class="w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
              <path d="M0 100 L50 0 L100 100 Z" fill="currentColor" />
            </svg>
          </div>
          <h1 class="font-headline text-4xl text-primary uppercase tracking-[0.2em] mb-3">
            Храм Даэдра
          </h1>
          <p class="text-foreground/60 text-sm max-w-lg mx-auto leading-relaxed">
            Ваше величие измеряется камнями этого храма. Возведите монумент, достойный Принца, и последователи стекутся под вашу тень.
          </p>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
          <!-- Construction Progress -->
          <section class="lg:col-span-2 bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm">
            <h2 class="font-headline text-lg text-primary uppercase tracking-wider mb-6 flex items-center gap-2">
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
              Статус строительства
            </h2>

            <div class="space-y-8">
              <div>
                <div class="flex justify-between items-end mb-3">
                  <span class="text-xs text-foreground/50 font-headline uppercase">Завершено</span>
                  <span class="text-3xl font-headline text-primary"><%= progress %>%</span>
                </div>
                <div class="w-full h-4 bg-background/60 rounded-full border border-border/30 p-0.5 overflow-hidden shadow-inner">
                  <div
                    class="h-full bg-gradient-to-r from-primary/60 to-primary shadow-[0_0_15px_rgba(var(--primary-rgb),0.4)] transition-all duration-1000"
                    style={"width: #{progress}%"}
                  >
                  </div>
                </div>
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div class="p-4 bg-background/40 border border-border/20 rounded">
                  <span class="text-[10px] text-foreground/40 uppercase block mb-1">
                    Вложено септимов
                  </span>
                  <span class="text-sm font-headline"><%= total_invested %> / 5000</span>
                </div>
                <div class="p-4 bg-background/40 border border-border/20 rounded">
                  <span class="text-[10px] text-foreground/40 uppercase block mb-1">
                    Пожертвований
                  </span>
                  <span class="text-sm font-headline"><%= donations_count %></span>
                </div>
              </div>

              <div class="flex gap-2">
                <button
                  phx-click="set_donation"
                  phx-value-amount="50"
                  class={"px-3 py-2 text-xs font-headline uppercase border transition-all #{if @donation_amount == 50, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/60 hover:border-primary/40"}"}
                >
                  50
                </button>
                <button
                  phx-click="set_donation"
                  phx-value-amount="100"
                  class={"px-3 py-2 text-xs font-headline uppercase border transition-all #{if @donation_amount == 100, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/60 hover:border-primary/40"}"}
                >
                  100
                </button>
                <button
                  phx-click="set_donation"
                  phx-value-amount="500"
                  class={"px-3 py-2 text-xs font-headline uppercase border transition-all #{if @donation_amount == 500, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/60 hover:border-primary/40"}"}
                >
                  500
                </button>
                <button
                  phx-click="set_donation"
                  phx-value-amount="1000"
                  class={"px-3 py-2 text-xs font-headline uppercase border transition-all #{if @donation_amount == 1000, do: "border-primary bg-primary/20 text-primary", else: "border-border/40 text-foreground/60 hover:border-primary/40"}"}
                >
                  1000
                </button>
              </div>

              <button
                phx-click="donate"
                phx-value-amount={@donation_amount}
                class="w-full py-3 bg-primary/10 border border-primary/30 text-primary font-headline uppercase tracking-widest hover:bg-primary/20 transition-all disabled:opacity-50"
                disabled={@hero_state.gold < @donation_amount}
              >
                Пожертвовать <%= @donation_amount %> септимов (Золото: <%= @hero_state.gold %>)
              </button>
            </div>
          </section>
          <!-- Active Benefits -->
          <section class="bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm">
            <h2 class="font-headline text-lg text-primary uppercase tracking-wider mb-6 flex items-center gap-2">
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
              Влияние храма
            </h2>

            <div class="space-y-4">
              <%= if bonuses.gold_bonus > 0 do %>
                <div class="flex items-center gap-3 p-3 bg-emerald-500/5 border border-emerald-500/20 rounded group transition-all">
                  <div class="text-emerald-500">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <div>
                    <div class="text-xs font-bold text-emerald-400">Благословение</div>
                    <div class="text-[10px] text-foreground/40">
                      +<%= bonuses.gold_bonus %>% к золоту
                    </div>
                  </div>
                </div>
              <% else %>
                <p class="text-xs text-foreground/30 italic text-center py-4">
                  Храм еще не начал приносить пользу. Заложите первый камень.
                </p>
              <% end %>

              <%= if bonuses.luck_bonus > 0 do %>
                <div class="flex items-center gap-3 p-3 bg-amber-500/5 border border-amber-500/20 rounded group transition-all">
                  <div class="text-amber-500">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                    </svg>
                  </div>
                  <div>
                    <div class="text-xs font-bold text-amber-400">Удача</div>
                    <div class="text-[10px] text-foreground/40">
                      +<%= bonuses.luck_bonus %> к удаче
                    </div>
                  </div>
                </div>
              <% end %>

              <%= if bonuses.xp_bonus > 0 do %>
                <div class="flex items-center gap-3 p-3 bg-purple-500/5 border border-purple-500/20 rounded group transition-all">
                  <div class="text-purple-500">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  </div>
                  <div>
                    <div class="text-xs font-bold text-purple-400">Опыт</div>
                    <div class="text-[10px] text-foreground/40">+<%= bonuses.xp_bonus %>% к XP</div>
                  </div>
                </div>
              <% end %>

              <div class="border border-dashed border-border/20 p-4 rounded text-center">
                <span class="text-[10px] text-foreground/30 uppercase">
                  <%= case progress do
                    p when p >= 100 -> "Храм завершён!"
                    p when p >= 75 -> "Следующий бонус: полная мощность"
                    p when p >= 50 -> "Следующий бонус на 75%"
                    p when p >= 25 -> "Следующий бонус на 50%"
                    p when p >= 5 -> "Следующий бонус на 25%"
                    _ -> "Следующий эффект на 5%"
                  end %>
                </span>
              </div>
            </div>
          </section>
        </div>
        <!-- Residents -->
        <%= if length(residents) > 0 do %>
          <section class="bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm mb-8">
            <div class="flex items-center justify-between mb-6">
              <h2 class="font-headline text-lg text-blue-400 uppercase tracking-wider flex items-center gap-2">
                <svg
                  class="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
                Постояльцы храма
              </h2>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <%= for resident <- residents do %>
                <div class="flex items-center justify-between p-4 bg-blue-500/5 border border-blue-500/10 hover:border-blue-500/30 transition-all rounded">
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-full bg-blue-500/20 flex items-center justify-center">
                      <svg
                        class="w-4 h-4 text-blue-500"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                      </svg>
                    </div>
                    <span class="text-sm font-headline text-foreground/80"><%= resident %></span>
                  </div>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>
        <!-- Enemies -->
        <%= if length(enemies) > 0 do %>
          <section class="bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm mb-8">
            <div class="flex items-center justify-between mb-6">
              <h2 class="font-headline text-lg text-red-400 uppercase tracking-wider flex items-center gap-2">
                <svg
                  class="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                Враги Храма
              </h2>
              <span class="text-[10px] text-red-500/50 uppercase tracking-widest">
                Всего атак: <%= temple[:enemy_encounters] || 0 %>
              </span>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= for enemy <- enemies do %>
                <div class="flex items-center justify-between p-4 bg-red-500/5 border border-red-500/10 hover:border-red-500/30 transition-all rounded">
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-full bg-red-500/20 flex items-center justify-center font-headline text-red-500 text-xs">
                      !
                    </div>
                    <span class="text-sm font-headline text-foreground/80"><%= enemy %></span>
                  </div>
                  <span class="text-xs text-red-400/60 uppercase">Угроза</span>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>
        <!-- Events -->
        <%= if length(events) > 0 do %>
          <section class="bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm">
            <h2 class="font-headline text-lg text-foreground/60 uppercase tracking-wider mb-6 flex items-center gap-2">
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              Лента событий
            </h2>

            <div class="space-y-2 max-h-64 overflow-y-auto">
              <%= for event <- events do %>
                <div class="p-3 bg-background/20 border border-border/20 rounded text-sm">
                  <span class="text-[10px] text-foreground/40 uppercase mr-2">
                    <%= case event[:type] do
                      :enemy_attack -> "АТАКА"
                      :donation -> "ПОЖЕРТВОВАНИЕ"
                      :construction -> "СТРОИТЕЛЬСТВО"
                      _ -> "СОБЫТИЕ"
                    end %>
                  </span>
                  <span class="text-foreground/70"><%= event[:message] %></span>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>
      </main>
    </div>
    """
  end
end
