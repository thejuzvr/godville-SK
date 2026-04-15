defmodule GodvilleSkWeb.ArenaLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game
  alias GodvilleSk.Arenas
  import GodvilleSkWeb.NavComponents

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    case Game.get_hero_by_user_id(user.id) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/hero/new")}

      hero ->
        active_arena_id = Arenas.get_active_arena_for_hero(hero.id)
        
        if connected?(socket) do
          Phoenix.PubSub.subscribe(GodvilleSk.PubSub, "hero:#{hero.id}")
          if active_arena_id do
            Phoenix.PubSub.subscribe(GodvilleSk.PubSub, "arena:#{active_arena_id}")
          end
        end

        arena_state = if active_arena_id, do: GodvilleSk.Arena.Server.get_arena(active_arena_id), else: nil
        
        status = if arena_state, do: "fighting", else: "idle"
        # Check queue
        queue_entry = GodvilleSk.Arena.Matchmaking.get_queue_entry(hero.id)
        status = if queue_entry && status == "idle", do: "queued", else: status

        state = %{
          status: status,
          active_arena_id: active_arena_id,
          arena_data: arena_state,
          history: Arenas.get_arena_battles(hero.id)
        }

        {:ok,
         socket
         |> assign(:hero, hero)
         |> assign(:state, state)}
    end
  end

  def handle_event("join_queue", %{"type" => type}, socket) do
    hero = socket.assigns.hero
    type_atom = String.to_existing_atom(type)

    case Arenas.join_arena(hero.id, type_atom) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Вы вступили в очередь на арену!")
         |> assign(:state, Map.put(socket.assigns.state, :status, "queued"))}

      {:error, reason} ->
        msg = case reason do
          :hero_dead -> "Герой мёртв."
          :hero_in_combat -> "Герой уже в бою."
          :already_in_arena -> "Вы уже записаны на арену."
          _ -> "Не удалось вступить на арену."
        end
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  def handle_event("leave_queue", _params, socket) do
    hero = socket.assigns.hero
    Arenas.leave_arena(hero.id)
    {:noreply,
      socket
      |> put_flash(:info, "Вы покинули очередь.")
      |> assign(:state, Map.put(socket.assigns.state, :status, "idle"))}
  end

  # --- Arena PubSub Events ---

  def handle_info({:arena_start, arena_id}, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(GodvilleSk.PubSub, "arena:#{arena_id}")
    end
    
    arena_data = GodvilleSk.Arena.Server.get_arena(arena_id)

    state =
      socket.assigns.state
      |> Map.put(:status, "fighting")
      |> Map.put(:active_arena_id, arena_id)
      |> Map.put(:arena_data, arena_data)

    {:noreply,
     socket
     |> assign(:state, state)
     |> put_flash(:info, "⚔️ Противник найден! Бой начался!")}
  end

  def handle_info({:arena_update, arena_data}, socket) do
    state = Map.put(socket.assigns.state, :arena_data, arena_data)
    {:noreply, assign(socket, :state, state)}
  end

  def handle_info({:arena_victory, reward}, socket) do
    gold = reward[:gold] || 0
    xp = reward[:xp] || 0

    state =
      socket.assigns.state
      |> Map.put(:status, "idle")
      |> Map.put(:last_result, :victory)
      |> Map.put(:active_arena_id, nil)
      |> Map.put(:arena_data, nil)

    history = Arenas.get_arena_battles(socket.assigns.hero.id)

    {:noreply,
     socket
     |> assign(:state, Map.put(state, :history, history))
     |> put_flash(:info, "🏆 Победа! +#{gold} з. +#{xp} XP")}
  end

  def handle_info({:arena_defeat, reward}, socket) do
    gold = reward[:gold] || 0

    state =
      socket.assigns.state
      |> Map.put(:status, "idle")
      |> Map.put(:last_result, :defeat)
      |> Map.put(:active_arena_id, nil)
      |> Map.put(:arena_data, nil)

    history = Arenas.get_arena_battles(socket.assigns.hero.id)

    {:noreply,
     socket
     |> assign(:state, Map.put(state, :history, history))
     |> put_flash(:info, "💀 Поражение. Утешительные: +#{gold} з.")}
  end

  def handle_info({:arena_result, %{winner: winner}}, socket) do
    hero = socket.assigns.hero
    state = socket.assigns.state
    team = if hero.id in (state[:team1] || []), do: :team1, else: :team2

    result = if winner == team, do: :victory, else: :defeat

    {:noreply, assign(socket, :state, Map.put(state, :last_result, result))}
  end

  def handle_info({:arena_attack, %{damage: damage}}, socket) do
    # Псевдо-бросок кубика. Передаём урон как результат, чтобы кость красиво крутилась!
    # Поскольку D20 - это 1-20, мы нормализуем урон (или просто крутим случайно, если урон выше 20).
    result = if damage > 0, do: rem(damage, 20) + 1, else: 1
    {:noreply, push_event(socket, "combat_roll", %{result: result})}
  end

  # Catch-all
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-background text-foreground font-body overflow-hidden relative selection:bg-red-900/50 selection:text-red-100">
      <div class="absolute inset-0 bg-[url('/images/login-bg2.jpg')] bg-cover bg-center opacity-5 pointer-events-none mix-blend-overlay"></div>
      
      <div class="relative z-10 border-b-2 border-red-900/50 bg-background/90 backdrop-blur-md">
        <.game_nav active_tab={:arena} />
      </div>

      <main class="flex-1 overflow-y-auto p-4 lg:p-8 max-w-7xl mx-auto w-full relative z-10 custom-scrollbar">
        <header class="mb-12 text-center relative py-12 border-y-[1px] border-red-900/30 bg-gradient-to-b from-red-900/10 to-transparent overflow-hidden">
          <div class="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-1 bg-red-600/50"></div>
          <div class="absolute inset-0 opacity-[0.05] pointer-events-none bg-[url('/images/noise.png')] mix-blend-overlay"></div>
          
          <h1 class="font-headline text-5xl text-red-500 uppercase tracking-[0.4em] mb-4 drop-shadow-[0_0_15px_rgba(220,38,38,0.5)]">
            Арена Крови
          </h1>
          <p class="text-red-400/50 text-[11px] uppercase tracking-[0.2em] max-w-xl mx-auto leading-relaxed font-body border-l border-r border-red-900/30 px-4">
            Здесь кончается милосердие. Оставьте слабость за порогом, ибо пески жаждут только звона стали и предсмертных хрипов. Выбирайте свою смерть разумно.
          </p>
        </header>

        <%= if @state.status == "fighting" && @state.arena_data do %>
          <!-- АКТИВНЫЙ БОЙ НА АРЕНЕ -->
          <div class="border-2 border-red-900/50 bg-background/90 backdrop-blur-md p-6 relative overflow-hidden shadow-[0_0_30px_rgba(150,0,0,0.15)] flex flex-col min-h-[600px] mb-8">
            <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-red-900/0 via-red-600/80 to-red-900/0"></div>
            <div class="absolute inset-0 bg-[url('/images/noise.png')] mix-blend-overlay opacity-10 pointer-events-none"></div>

            <div class="flex justify-between items-center mb-8 pb-4 border-b border-red-900/30">
              <div class="font-headline text-red-500 tracking-[0.2em] uppercase text-xl">
                БИТВА: <%= case @state.arena_data.type do
                  :duel -> "ДУЭЛЬ НА СМЕРТЬ"
                  :team_3v3 -> "МАЛАЯ РЕЗНЯ (3 НА 3)"
                  :team_5v5 -> "КРОВАВАЯ БАНЯ (5 НА 5)"
                  _ -> "СРАЖЕНИЕ"
                end %>
              </div>
              <div class="text-[10px] text-red-400/50 font-headline uppercase tracking-widest px-3 py-1 border border-red-900/50 bg-red-900/20">
                РАУНД <%= @state.arena_data.round %>
              </div>
            </div>

            <!-- Команды -->
            <div class="flex gap-8 justify-between mb-8 relative">
              <div class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 flex flex-col items-center justify-center z-0 w-32 h-32">
                <div class="font-headline text-3xl text-red-900/30 tracking-[0.5em] mb-2 drop-shadow-[0_0_10px_rgba(200,0,0,0.2)]">VS</div>
                <div id="d20-arena" phx-hook="DiceRollerHook" data-theme={@current_user.dice_theme} class="d20-container transform scale-75" phx-update="ignore"></div>
              </div>
              <!-- Команда 1 -->
              <div class="w-[45%] flex flex-col gap-3 relative z-10">
                <div class="text-[10px] font-headline uppercase tracking-widest text-red-400 mb-2 border-b border-red-900/30 pb-2">Команда Альфа</div>
                <%= for hero_id <- @state.arena_data.team1 do %>
                  <% active_hero = GodvilleSk.Game.get_hero_live_state(%GodvilleSk.Game.Hero{id: hero_id}) %>
                  <%= if active_hero do %>
                    <div class={"p-3 border #{if active_hero.hp <= 0, do: "border-red-900/20 bg-background/50 opacity-40 grayscale", else: "border-red-900/50 bg-background"} flex flex-col gap-2 relative overflow-hidden"}>
                      <div class={"absolute left-0 top-0 bottom-0 w-1 #{if hero_id == @hero.id, do: "bg-red-500", else: "bg-red-900/50"}"}></div>
                      <div class="flex justify-between items-start pl-2">
                        <span class={"font-headline uppercase tracking-widest #{if hero_id == @hero.id, do: "text-red-400", else: "text-foreground/80"}"}><%= active_hero.name %></span>
                        <span class="text-[9px] text-foreground/40 font-mono"><%= max(0, active_hero.hp) %> / <%= active_hero.max_hp %></span>
                      </div>
                      <div class="w-full h-1.5 bg-background border border-red-900/30 pl-2">
                        <div class="h-full bg-red-600 transition-all duration-300" style={"width: #{min(100, (active_hero.hp / max(1, active_hero.max_hp)) * 100)}%"}></div>
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>

              <!-- Команда 2 -->
              <div class="w-[45%] flex flex-col gap-3 relative z-10 text-right">
                <div class="text-[10px] font-headline uppercase tracking-widest text-red-400 mb-2 border-b border-red-900/30 pb-2 w-full flex justify-end">Команда Омега</div>
                <%= for hero_id <- @state.arena_data.team2 do %>
                  <% active_hero = GodvilleSk.Game.get_hero_live_state(%GodvilleSk.Game.Hero{id: hero_id}) %>
                  <%= if active_hero do %>
                    <div class={"p-3 border #{if active_hero.hp <= 0, do: "border-red-900/20 bg-background/50 opacity-40 grayscale", else: "border-red-900/50 bg-background"} flex flex-col gap-2 relative overflow-hidden"}>
                      <div class={"absolute right-0 top-0 bottom-0 w-1 #{if hero_id == @hero.id, do: "bg-red-500", else: "bg-red-900/50"}"}></div>
                      <div class="flex flex-row-reverse justify-between items-start pr-2">
                        <span class={"font-headline uppercase tracking-widest #{if hero_id == @hero.id, do: "text-red-400", else: "text-foreground/80"}"}><%= active_hero.name %></span>
                        <span class="text-[9px] text-foreground/40 font-mono"><%= max(0, active_hero.hp) %> / <%= active_hero.max_hp %></span>
                      </div>
                      <div class="w-full h-1.5 bg-background border border-red-900/30 pr-2 flex justify-end">
                        <div class="h-full bg-red-700 transition-all duration-300" style={"width: #{min(100, (active_hero.hp / max(1, active_hero.max_hp)) * 100)}%"}></div>
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>
            </div>

            <!-- Журнал боя -->
            <div class="flex-1 border border-border/30 bg-background/80 flex flex-col overflow-hidden relative">
              <div class="absolute top-0 left-0 w-full h-8 bg-gradient-to-b from-background to-transparent z-10 pointer-events-none"></div>
              <div class="absolute bottom-0 left-0 w-full h-8 bg-gradient-to-t from-background to-transparent z-10 pointer-events-none"></div>
              
              <div class="p-4 bg-border/20 border-b border-border/30 text-[9px] uppercase tracking-widest font-headline text-foreground/50">
                Хроника Сражения
              </div>
              <div class="p-6 flex-1 overflow-y-auto space-y-3 font-body text-sm text-foreground/80 custom-scrollbar flex flex-col-reverse" id="arena-battle-log" phx-update="replace">
                <%= for entry <- @state.arena_data.log do %>
                  <div class={"pb-3 border-b border-border/10 #{if String.contains?(entry.msg, "Раунд"), do: "text-red-500 font-headline uppercase tracking-widest mt-4 border-none text-xs", else: ""}"}>
                    <span class="text-[10px] text-foreground/30 font-mono mr-3"><%= Calendar.strftime(entry.time, "%H:%M:%S") %></span>
                    <%= entry.msg %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% else %>
          <!-- Режимы и Очередь -->
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">

          
          <!-- Queue Status Panel -->
          <div class="lg:col-span-1 flex flex-col gap-8">
            <section class="bg-background/80 border border-red-900/50 p-6 backdrop-blur-md relative transform">
              <div class="absolute top-0 left-0 w-3 h-3 border-t-2 border-l-2 border-red-600/50"></div>
              <div class="absolute bottom-0 right-0 w-3 h-3 border-b-2 border-r-2 border-red-600/50"></div>
              
              <h2 class="font-headline text-lg text-red-400 uppercase tracking-[0.2em] mb-6 flex items-center gap-3">
                <span class="w-2 h-2 bg-red-600 transform rotate-45"></span>
                Статус
              </h2>

              <%= if @state.status == "queued" do %>
                <div class="p-6 border border-red-900/50 bg-red-900/10 text-center animate-pulse relative overflow-hidden">
                  <div class="absolute inset-0 bg-[url('/images/noise.png')] mix-blend-overlay opacity-20"></div>
                  <div class="text-[10px] text-red-400/70 font-headline uppercase tracking-widest mb-2 relative z-10">В очереди</div>
                  <div class="text-xl text-red-500 font-headline tracking-widest relative z-10">ОЖИДАНИЕ СОПЕРНИКОВ...</div>
                </div>
                <button phx-click="leave_queue" class="mt-4 w-full py-3 text-[10px] font-headline uppercase tracking-widest border border-red-500/50 text-red-400 hover:bg-red-900/30 transition-colors">
                  Покинуть Колизей
                </button>
              <% else %>
                <div class="p-6 border border-border/30 bg-background/50 text-center text-[10px] uppercase tracking-widest text-foreground/40 font-headline">
                  Вне очереди
                </div>
              <% end %>
            </section>

            <!-- Combat History -->
            <section class="bg-background/80 border border-border/30 p-6 backdrop-blur-md flex-1">
              <h2 class="font-headline text-sm text-foreground/60 uppercase tracking-[0.2em] mb-6 border-b border-border/30 pb-2">
                Записи Арены
              </h2>
              <div class="space-y-3">
                <%= if Enum.empty?(@state.history) do %>
                  <p class="text-[10px] text-foreground/30 uppercase tracking-widest font-headline text-center italic border border-dashed border-border/30 p-4">Нет записей о сражениях.</p>
                <% else %>
                  <%= for _battle <- @state.history do %>
                    <div class="p-3 border border-border/30 bg-background/50 text-[10px] text-foreground/70 flex justify-between font-headline uppercase tracking-wide">
                      <span class="text-red-400">ДУЭЛЬ</span>
                      <span>ЗАВЕРШЕНО</span>
                    </div>
                  <% end %>
                <% end %>
              </div>
            </section>
          </div>

          <!-- Arena Modes -->
          <div class="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Duel Mode -->
            <div class="group relative bg-background border border-border/50 hover:border-red-600/50 transition-colors p-8 flex flex-col justify-between h-80 overflow-hidden">
              <div class="absolute inset-0 bg-gradient-to-br from-red-900/5 to-transparent pointer-events-none min-h-[300px]"></div>
              
              <div class="relative z-10">
                <div class="flex justify-between items-start mb-6">
                  <h3 class="font-headline text-2xl text-foreground uppercase tracking-[0.2em] group-hover:text-red-400 transition-colors">Дуэль</h3>
                  <span class="text-[10px] font-headline text-red-500/50 tracking-widest border border-red-900/30 px-2 py-1 bg-red-900/10">1 VS 1</span>
                </div>
                <p class="text-xs text-foreground/60 leading-relaxed font-body mb-6 w-[85%]">
                  Один на один. Честный бой по правилам чести. Победитель забирает славу, проигравший уносит лишь шрамы.
                </p>
                
                <ul class="space-y-2 text-[10px] uppercase font-headline tracking-widest text-foreground/40 hidden md:block">
                  <li class="flex items-center gap-2"><span class="w-1 h-1 bg-red-500"></span> Без союзников</li>
                  <li class="flex items-center gap-2"><span class="w-1 h-1 bg-red-500"></span> Высокий риск</li>
                  <li class="flex items-center gap-2"><span class="w-1 h-1 bg-red-500"></span> Мгновенный поиск</li>
                </ul>
              </div>

              <button phx-click="join_queue" phx-value-type="duel" disabled={@state.status == "queued"} class="relative z-10 w-full py-4 border border-red-900/50 bg-red-900/10 text-[11px] font-headline uppercase tracking-[0.2em] text-red-400 hover:bg-red-900/30 hover:border-red-500 transition-all disabled:opacity-30">
                Вызов брошен
              </button>
            </div>

            <!-- Team 3v3 Mode -->
            <div class="group relative bg-background border border-border/50 hover:border-red-600/50 transition-colors p-8 flex flex-col justify-between h-80 overflow-hidden">
              <div class="absolute inset-0 bg-gradient-to-br from-red-900/5 to-transparent pointer-events-none min-h-[300px]"></div>
              
              <div class="relative z-10">
                <div class="flex justify-between items-start mb-6">
                  <h3 class="font-headline text-2xl text-foreground uppercase tracking-[0.2em] group-hover:text-red-400 transition-colors">Отряд</h3>
                  <span class="text-[10px] font-headline text-red-500/50 tracking-widest border border-red-900/30 px-2 py-1 bg-red-900/10">3 VS 3</span>
                </div>
                <p class="text-xs text-foreground/60 leading-relaxed font-body mb-6 w-[85%]">
                  Сформируйте боевой отряд с двумя союзниками. Тактика и синергия решат исход битвы.
                </p>
                
                <ul class="space-y-2 text-[10px] uppercase font-headline tracking-widest text-foreground/40 hidden md:block">
                  <li class="flex items-center gap-2"><span class="w-1 h-1 bg-red-500"></span> Командный бой</li>
                  <li class="flex items-center gap-2"><span class="w-1 h-1 bg-red-500"></span> Средний риск</li>
                  <li class="flex items-center gap-2"><span class="w-1 h-1 bg-red-500"></span> Дележ добычи</li>
                </ul>
              </div>

              <button phx-click="join_queue" phx-value-type="team_3v3" disabled={@state.status == "queued"} class="relative z-10 w-full py-4 border border-red-900/50 bg-red-900/10 text-[11px] font-headline uppercase tracking-[0.2em] text-red-400 hover:bg-red-900/30 hover:border-red-500 transition-all disabled:opacity-30">
                Вступить в отряд
              </button>
            </div>

            <!-- Team 5v5 Mode -->
            <div class="group relative bg-background border border-border/50 hover:border-red-600/50 transition-colors p-8 flex flex-col justify-between h-80 md:col-span-2 overflow-hidden">
              <div class="absolute inset-0 bg-gradient-to-br from-red-900/10 to-transparent pointer-events-none min-h-[300px]"></div>
              <div class="absolute right-0 bottom-0 w-64 h-64 bg-red-900/5 rounded-full blur-3xl pointer-events-none"></div>
              
              <div class="relative z-10 flex flex-col md:flex-row justify-between w-full h-full">
                <div class="md:max-w-[60%]">
                  <div class="flex items-start mb-4 gap-4">
                    <h3 class="font-headline text-3xl text-foreground uppercase tracking-[0.3em] group-hover:text-red-400 transition-colors">Резня</h3>
                    <span class="text-[10px] font-headline text-red-500/60 tracking-widest border border-red-900/50 px-2 py-1 bg-red-900/20 shadow-[0_0_10px_rgba(200,0,0,0.1)]">5 VS 5</span>
                  </div>
                  <p class="text-sm text-foreground/70 leading-relaxed font-body mb-6">
                    Крупномасштабное столкновение. Полный хаос. Бой до последней капли крови. Только истинные полководцы смогут вывести свою команду из этой бойни живыми.
                  </p>
                  <div class="flex gap-4">
                    <div class="text-center p-3 border border-border/30 bg-background/50">
                      <div class="text-[9px] uppercase font-headline text-foreground/40 mb-1">Бонус Славы</div>
                      <div class="text-lg font-headline text-red-400">+50%</div>
                    </div>
                    <div class="text-center p-3 border border-border/30 bg-background/50">
                      <div class="text-[9px] uppercase font-headline text-foreground/40 mb-1">Бонус Золота</div>
                      <div class="text-lg font-headline text-yellow-500">+100%</div>
                    </div>
                  </div>
                </div>
                
                <div class="flex items-end mt-6 md:mt-0 md:w-1/3">
                  <button phx-click="join_queue" phx-value-type="team_5v5" disabled={@state.status == "queued"} class="w-full py-6 border-2 border-red-900/50 bg-red-900/20 text-[12px] font-headline uppercase tracking-[0.2em] text-red-400 hover:bg-red-900/40 hover:border-red-500 transition-all shadow-[0_0_15px_rgba(150,0,0,0.1)] disabled:opacity-30">
                    Участвовать в бойне
                  </button>
                </div>
              </div>
            </div>
            </div>
          </div>
        <% end %>
      </main>
    </div>
    """
  end
end
