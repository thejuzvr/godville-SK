defmodule GodvilleSkWeb.DashboardLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game
  alias GodvilleSk.WorldClock
  import GodvilleSkWeb.NavComponents

  def render(assigns) do
    case assigns.hero_state.status do
      :sovngarde -> sovngarde_view(assigns)
      _ -> standard_view(assigns)
    end
  end

  def standard_view(assigns) do
    ~H"""
    <div class="flex flex-col h-screen overflow-hidden bg-background">
      <!-- Top Nav -->
      <.game_nav active_tab={:dashboard} />

      <!-- Main 3-column layout -->
      <div class="flex flex-1 overflow-hidden">

        <!-- LEFT SIDEBAR: Hero info -->
        <aside class="w-64 flex-shrink-0 bg-card border-r border-border overflow-y-auto">
          <div class="p-3 space-y-3">
            <!-- Avatar + name -->
            <div class="flex items-start gap-3">
              <div class="w-12 h-12 rounded-full bg-primary/20 border-2 border-primary/40 flex items-center justify-center flex-shrink-0">
                <span class="font-headline text-primary text-lg">
                  <%= String.first(@hero.name) |> String.upcase() %>
                </span>
              </div>
              <div class="min-w-0">
                <div class="font-headline text-primary text-sm leading-tight truncate"><%= @hero.name %></div>
                <div class="text-foreground/60 text-xs mt-0.5">Уровень <%= @hero_state.level %> · <%= @hero.race %></div>
                <div class="flex items-center gap-1 mt-1">
                  <svg class="w-3 h-3 text-foreground/40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" />
                  </svg>
                  <span class="text-xs text-foreground/60"><%= @hero_state.location %></span>
                </div>
                <div class="text-xs text-foreground/50 mt-0.5">Нейтральное</div>
              </div>
            </div>

            <!-- Status badge -->
            <div class="text-center">
              <span class={"text-xs font-body px-2 py-0.5 rounded #{status_class(@hero_state.status)}"}>
                <%= status_text(@hero_state.status) %>
              </span>
            </div>

            <!-- HP / Mana / Stamina bars -->
            <div class="space-y-2">
              <!-- HP -->
              <div>
                <div class="flex justify-between text-xs text-foreground/60 mb-0.5">
                  <div class="flex items-center gap-1">
                    <svg class="w-3 h-3 text-red-400" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M12 21.593c-5.63-5.539-11-10.297-11-14.402 0-3.791 3.068-5.191 5.281-5.191 1.312 0 4.151.501 5.719 4.457 1.59-3.968 4.464-4.447 5.726-4.447 2.54 0 5.274 1.621 5.274 5.181 0 4.069-5.136 8.625-11 14.402z" />
                    </svg>
                    <span>Здоровье</span>
                  </div>
                  <span><%= @hero_state.hp %> / <%= @hero_state.max_hp %></span>
                </div>
                <div class="w-full h-2 bg-background/60 rounded-full overflow-hidden">
                  <div class="h-full bg-red-500 transition-all duration-500" style={"width: #{hp_pct(@hero_state.hp, @hero_state.max_hp)}%"}></div>
                </div>
              </div>
              <!-- Mana -->
              <div>
                <div class="flex justify-between text-xs text-foreground/60 mb-0.5">
                  <div class="flex items-center gap-1">
                    <svg class="w-3 h-3 text-blue-400" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" />
                    </svg>
                    <span>Магия</span>
                  </div>
                  <span><%= @max_mana %> / <%= @max_mana %></span>
                </div>
                <div class="w-full h-2 bg-background/60 rounded-full overflow-hidden">
                  <div class="h-full bg-blue-500" style="width: 100%"></div>
                </div>
              </div>
              <!-- Stamina -->
              <div>
                <div class="flex justify-between text-xs text-foreground/60 mb-0.5">
                  <div class="flex items-center gap-1">
                    <svg class="w-3 h-3 text-green-400" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M13 2.05v2.02c3.95.49 7 3.85 7 7.93 0 3.21-1.81 6-4.72 7.28L13 17v5h5l-1.22-1.22C19.91 19.07 22 15.76 22 12c0-5.18-3.95-9.45-9-9.95zM11 2.05C5.95 2.55 2 6.82 2 12c0 3.76 2.09 7.07 5.22 8.78L6 22h5v-5l-2.28 2.28C7.81 18 6 15.21 6 12c0-4.08 3.05-7.44 7-7.93V2.05z" />
                    </svg>
                    <span>Запас сил</span>
                  </div>
                  <span><%= round(@hero_state.stamina) %> / <%= @hero_state.stamina_max %></span>
                </div>
                <div class="w-full h-2 bg-background/60 rounded-full overflow-hidden">
                  <div class="h-full bg-green-500 transition-all duration-500" style={"width: #{hp_pct(@hero_state.stamina, @hero_state.stamina_max)}%"}></div>
                </div>
              </div>
            </div>

            <!-- Gold / Deaths -->
            <div class="grid grid-cols-2 gap-2 border-t border-border/50 pt-3">
              <div class="flex items-center gap-1.5">
                <svg class="w-3.5 h-3.5 text-yellow-500" viewBox="0 0 24 24" fill="currentColor">
                  <circle cx="12" cy="12" r="10" />
                </svg>
                <div>
                  <div class="text-xs text-foreground/50">Золото</div>
                  <div class="text-sm font-headline text-primary"><%= @hero_state.gold %></div>
                </div>
              </div>
              <div class="flex items-center gap-1.5">
                <svg class="w-3.5 h-3.5 text-foreground/40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 2L2 7v5c0 5.25 4.25 10.15 10 11.25" />
                  <path d="M12 22s7-4 7-10V7l-7-5" stroke-dasharray="4 2" />
                </svg>
                <div>
                  <div class="text-xs text-foreground/50">Смертей</div>
                  <div class="text-sm font-headline text-foreground/70"><%= (Map.get(@hero_state, :statistics) || %{})[:total_deaths] || 0 %></div>
                </div>
              </div>
            </div>

            <!-- Equipment -->
            <div class="border-t border-border/50 pt-3">
              <div class="flex items-center justify-between mb-2">
                <span class="text-xs font-headline text-foreground/70 tracking-wide">Снаряжение</span>
                <span class="text-xs text-foreground/50">Броня: 5</span>
              </div>
              <div class="space-y-1">
                <% slots = [
                  {:weapon, "Оружие"}, {:head, "Голова"}, {:torso, "Торс"}, 
                  {:legs, "Поножи"}, {:arms, "Руки"}, {:boots, "Ботинки"}, 
                  {:amulet, "Амулет"}, {:ring, "Кольцо"}
                ] %>
                <%= for {slot_id, slot_label} <- slots do %>
                  <div class="flex justify-between items-center text-xs py-0.5">
                    <span class="text-foreground/60"><%= slot_label %></span>
                    <%= if item = (Map.get(@hero_state, :equipment) || %{})[slot_id] do %>
                      <span class="text-primary truncate max-w-[100px]" title={item}><%= item %></span>
                    <% else %>
                      <span class="text-foreground/30 italic">Пусто</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Companion -->
            <div class="border-t border-border/50 pt-3">
              <div class="flex items-center gap-2 mb-2">
                <svg class="w-3 h-3 text-foreground/40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="9" cy="7" r="4" /><path d="M3 21v-2a4 4 0 014-4h4a4 4 0 014 4v2" />
                </svg>
                <span class="text-xs font-headline text-foreground/70 tracking-wide">Активный Компаньон</span>
              </div>
              <div class="text-xs text-foreground/30 italic text-center py-2">Нет компаньона</div>
            </div>
          </div>
        </aside>

        <!-- CENTER: Adventure Journal -->
        <main class="flex-1 flex flex-col overflow-hidden border-r border-border">

          <!-- ENEMY COMBAT ARENA -->
          <div :if={@hero_state.status in [:combat, :combat_initiative, :combat_round] && @hero_state.target} class="flex-shrink-0 bg-background border-b border-border p-4 relative overflow-hidden flex flex-col" style="height: 300px;">
             <!-- Subtle glow/vignette -->
             <div class="absolute inset-0 bg-red-900/10 pointer-events-none"></div>
             <!-- Top header VS -->
             <div class="flex justify-between items-center z-10 w-full mb-2">
               <!-- Hero -->
               <div class="w-5/12 flex flex-col gap-1 items-start">
                 <div class="font-headline text-lg text-primary truncate w-full"><%= @hero.name %></div>
                 <div class="flex w-full h-3 bg-background/50 rounded overflow-hidden shadow-inner border border-primary/20">
                   <div class="h-full bg-red-500 transition-all duration-500" style={"width: #{hp_pct(@hero_state.hp, @hero_state.max_hp)}%"}></div>
                 </div>
                 <span class="text-xs text-foreground/50"><%= max(0, @hero_state.hp) %> / <%= @hero_state.max_hp %> HP</span>
               </div>
               
               <!-- Center -->
               <div class="font-headline text-2xl text-red-500/50 tracking-widest px-2">
                 VS
               </div>
               
               <!-- Target -->
               <% target_max_hp = Map.get(@hero_state.target, :max_hp) || 100 %>
               <div class="w-5/12 flex flex-col gap-1 items-end text-right">
                 <div class="font-headline text-lg text-red-500 truncate w-full"><%= @hero_state.target.name %></div>
                 <div class="flex w-full h-3 bg-background/50 rounded overflow-hidden shadow-inner border border-red-500/20 transform rotate-180">
                   <div class="h-full bg-red-600 transition-all duration-500" style={"width: #{hp_pct(@hero_state.target.hp, target_max_hp)}%"}></div>
                 </div>
                 <span class="text-xs text-foreground/50"><%= max(0, @hero_state.target.hp) %> / <%= target_max_hp %> HP</span>
               </div>
             </div>
             
             <!-- 3D D20 Dice Container -->
             <div class="flex-1 flex items-center justify-center relative w-full h-full">
                <!-- hook will inject into this element -->
                <div id="d20-combat" phx-hook="DiceRollerHook" data-theme={@current_user.dice_theme} class="d20-container" phx-update="ignore"></div>
             </div>
          </div>

          <!-- Journal header -->
          <div class="flex-shrink-0 flex items-center justify-between px-4 py-2.5 border-b border-border bg-card/50">
            <div class="flex items-center gap-2">
              <svg class="w-4 h-4 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M4 19.5A2.5 2.5 0 016.5 17H20M4 19.5A2.5 2.5 0 014 17V4h16v13H6.5A2.5 2.5 0 004 19.5z" />
              </svg>
              <h2 class="font-headline text-sm tracking-wide text-foreground">Журнал приключений</h2>
            </div>
            <span class="text-xs text-foreground/40 font-body">Хроника путешествий, мыслей и деяний вашего героя.</span>
          </div>

          <!-- Log entries -->
          <div class="flex-1 overflow-y-auto p-4 space-y-1.5 font-body text-sm">
            <%= for entry <- normal_logs(assigns) do %>
              <div class="flex gap-2 text-foreground/80 leading-relaxed">
                <span class="text-primary/60 font-headline text-xs flex-shrink-0 mt-0.5 w-12">
                  <%= format_game_time(entry.game_time || @game_time) %>
                </span>
                <span><%= entry.message %></span>
              </div>
            <% end %>
          </div>

          <!-- XP bar at the bottom -->
          <div class="flex-shrink-0 border-t border-border px-4 py-2 bg-card/30">
            <div class="flex items-center gap-2">
              <span class="text-xs text-foreground/50 font-body">Опыт</span>
              <div class="flex-1 h-1.5 bg-background/60 rounded-full overflow-hidden">
                <div class="h-full bg-primary/60 transition-all" style={"width: #{xp_pct(@hero_state.xp, @hero_state.level)}%"}></div>
              </div>
              <span class="text-xs text-foreground/50 font-body"><%= @hero_state.xp %> / <%= @hero_state.level * 100 %></span>
            </div>
          </div>
        </main>

        <!-- RIGHT SIDEBAR: Time & Intervention -->
        <aside class="w-64 flex-shrink-0 overflow-y-auto bg-card">
          <div class="p-3 space-y-3">
            <!-- Game Time -->
            <div class="bg-background/40 border border-border/50 p-3">
              <div class="flex items-center gap-1.5 mb-2">
                <svg class="w-3.5 h-3.5 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" />
                </svg>
                <span class="text-xs font-headline text-foreground/80 tracking-wide">Игровое время</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-xs text-foreground/60 font-body">
                  <%= @game_time.day_name %>, <%= @game_time.day %>-й день <%= @game_time.month %>, 4Э <%= @game_time.year %>
                </span>
                <span class="text-xs font-headline text-primary"><%= format_game_time(@game_time) %></span>
              </div>
            </div>

            <!-- Real Time -->
            <div class="bg-background/40 border border-border/50 p-3">
              <div class="flex items-center gap-1.5 mb-2">
                <svg class="w-3.5 h-3.5 text-foreground/50" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" />
                </svg>
                <span class="text-xs font-headline text-foreground/80 tracking-wide">Реальное время</span>
              </div>
              <div
                id="local-clock"
                phx-hook="LocalClock"
                data-utc={DateTime.to_iso8601(@real_time)}
                class="flex justify-between items-center"
              >
                <span data-role="date" class="text-xs text-foreground/60 font-body"><%= format_real_date(@real_time) %></span>
                <span data-role="time" class="text-xs font-headline text-foreground/70"><%= format_real_time(@real_time) %></span>
              </div>
            </div>

            <!-- World Conditions -->
            <div class="bg-background/40 border border-border/50 p-3">
              <div class="flex items-center gap-1.5 mb-3">
                <svg class="w-3.5 h-3.5 text-primary/70" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
                </svg>
                <span class="text-xs font-headline text-foreground/80 tracking-wide">Мировые условия</span>
              </div>
              <div class="space-y-2 text-xs">
                <div class="flex justify-between">
                  <span class="text-foreground/50 flex items-center gap-1">
                    <span>☀️</span> Время суток
                  </span>
                  <span class="text-primary"><%= @game_time.time_of_day %></span>
                </div>
                <div class="flex justify-between">
                  <span class="text-foreground/50 flex items-center gap-1">
                    <span>🌿</span> Время года
                  </span>
                  <span class="text-foreground/80"><%= @game_time.season %></span>
                </div>
                <div class="flex justify-between">
                  <span class="text-foreground/50 flex items-center gap-1">
                    <span>🌤</span> Погода
                  </span>
                  <span class="text-foreground/80"><%= @game_time.weather %></span>
                </div>
              </div>
              <div class="mt-3 pt-2 border-t border-border/30">
                <span :if={@hero_state.luck_modifier < 0} class="text-[10px] px-1.5 py-0.5 rounded bg-red-500/10 text-red-500 border border-red-500/20">
                  Ослабленность (<%= @hero_state.luck_modifier %>)
                </span>
                <span :if={@hero_state.luck_modifier >= 0} class="text-xs text-foreground/40">Активные эффекты: нет</span>
              </div>
            </div>

            <!-- Intervention Panel -->
            <div class="bg-background/40 border border-border/50 p-3">
              <div class="flex items-center gap-1.5 mb-3">
                <svg class="w-3.5 h-3.5 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" />
                </svg>
                <span class="text-xs font-headline text-foreground/80 tracking-wide">Пульт Вмешательства</span>
              </div>
              <p class="text-xs text-foreground/50 font-body mb-3 leading-relaxed">
                Направляйте своего героя или просто наблюдайте. Каждое действие тратит 50 ед. силы.
              </p>

              <!-- Intervention power bar -->
              <div class="mb-3">
                <div class="flex justify-between text-xs text-foreground/60 mb-1">
                  <span>Сила Вмешательства</span>
                  <span><%= @hero_state.intervention_power %> / 100</span>
                </div>
                <div class="w-full h-2 bg-background/60 rounded-full overflow-hidden">
                  <div class="h-full bg-primary transition-all duration-500" style={"width: #{@hero_state.intervention_power}%"}></div>
                </div>
                <div class="text-xs text-foreground/40 mt-1">Восполнение: ~30 ед. / мин</div>
              </div>

              <!-- Whisper form -->
              <.form for={@whisper_form} phx-submit="send_whisper">
                <div class="mb-2">
                  <label class="text-xs text-foreground/60 mb-1 block">Божественный шёпот</label>
                  <textarea
                    id="whisper-textarea"
                    name="whisper[text]"
                    placeholder="Сообщение герою (до 200 символов)"
                    maxlength="200"
                    rows="2"
                    class="w-full px-2 py-1.5 text-xs bg-background/60 border border-border/50 text-foreground placeholder:text-foreground/30 focus:border-primary focus:outline-none resize-none font-body"
                  ></textarea>
                </div>
                <button
                  type="submit"
                  disabled={@hero_state.intervention_power < 50}
                  class="w-full px-3 py-1.5 text-xs font-headline bg-primary/80 hover:bg-primary text-background disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                >
                  Шептать
                </button>
              </.form>

              <div class="grid grid-cols-2 gap-2 mt-2">
                <button
                  type="button"
                  phx-click="bless"
                  disabled={@hero_state.intervention_power < 50 or @hero_state.status == :sovngarde}
                  class="px-2 py-1.5 text-xs font-headline bg-emerald-500/70 hover:bg-emerald-500 text-background disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                >
                  Благословить
                </button>
                <button
                  type="button"
                  phx-click="punish"
                  disabled={@hero_state.intervention_power < 50 or @hero_state.status == :sovngarde}
                  class="px-2 py-1.5 text-xs font-headline bg-red-500/70 hover:bg-red-500 text-background disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                >
                  Наказать
                </button>
              </div>

              <!-- Last sent whisper preview -->
              <div :if={@last_whisper != ""} class="mt-2 p-2 bg-primary/10 border border-primary/20 text-xs text-foreground/70 font-body">
                <span class="text-primary">Последнее:</span> <%= @last_whisper %>
              </div>
            </div>
          </div>
        </aside>

      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    case Game.get_hero_by_user_id(user.id) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/hero/new")}

      hero ->
        Game.ensure_hero_running(hero)
        hero_state = Game.get_hero_live_state(hero) || default_hero_state(hero)

        world = WorldClock.snapshot()

        if connected?(socket) do
          Phoenix.PubSub.subscribe(GodvilleSk.PubSub, "hero:#{hero.id}")
          Phoenix.PubSub.subscribe(GodvilleSk.PubSub, "world")
        end

        {:ok,
         socket
         |> assign(:hero, hero)
         |> assign(:hero_state, hero_state)
         |> assign(:game_time, world.game_time)
         |> assign(:real_time, world.real_time)
         |> assign(:whisper, "")
         |> assign(:last_whisper, "")
         |> assign(:max_mana, calc_max_mana(hero_state))
         |> assign(:max_stamina, calc_max_stamina(hero_state))
         |> assign(:whisper_form, to_form(%{}, as: "whisper"))}
    end
  end

  def handle_info({:hero_update, hero_state}, socket) do
    old_logs = socket.assigns.hero_state.log

    new_logs =
      if Enum.empty?(old_logs) do
        hero_state.log
      else
        old_latest = hd(old_logs)
        Enum.take_while(hero_state.log, fn l -> l != old_latest end)
      end

    socket =
      Enum.reduce(Enum.reverse(new_logs), socket, fn log, acc ->
        meta = log.metadata || %{}
        
        if meta[:type] == "combat_roll" do
          push_event(acc, "combat_roll", %{
            roll: meta[:roll] || 10,
            total: meta[:total] || 10,
            damage: meta[:damage] || 0,
            is_hit: meta[:is_hit] || false,
            actor: meta[:actor] || "hero"
          })
        else
          if meta[:type] == "initiative_roll" do
            push_event(acc, "initiative_roll", %{
              hero_roll: meta[:hero_roll],
              enemy_roll: meta[:enemy_roll],
              turn: meta[:turn]
            })
          else
            acc
          end
        end
      end)

    {:noreply,
     socket
     |> assign(:hero_state, hero_state)
     |> assign(:max_mana, calc_max_mana(hero_state))
     |> assign(:max_stamina, calc_max_stamina(hero_state))}
  end

  def handle_info({:world_update, world}, socket) do
    {:noreply,
     socket
     |> assign(:real_time, world.real_time)
     |> assign(:game_time, world.game_time)}
  end

  def handle_event("send_whisper", %{"whisper" => %{"text" => text}}, socket) when byte_size(text) > 0 do
    if socket.assigns.hero_state.intervention_power >= 50 do
      GodvilleSk.Hero.send_whisper(socket.assigns.hero.name, text)
      {:noreply, assign(socket, :last_whisper, String.slice(text, 0, 200))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("bless", _params, socket) do
    if socket.assigns.hero_state.intervention_power >= 50 do
      GodvilleSk.Hero.bless(socket.assigns.hero.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("punish", _params, socket) do
    if socket.assigns.hero_state.intervention_power >= 50 do
      GodvilleSk.Hero.punish(socket.assigns.hero.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("divine_intervention", _params, socket) do
    if socket.assigns.hero_state.status == :sovngarde and socket.assigns.hero_state.intervention_power >= 100 do
      GodvilleSk.Hero.divine_intervention(socket.assigns.hero.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("send_whisper", _params, socket) do
    {:noreply, socket}
  end

  # ---- Helpers ----

  defp default_hero_state(hero) do
    attrs = hero.attributes || %{}
    %GodvilleSk.Hero{
      id: hero.id,
      name: hero.name,
      race: hero.race,
      class: hero.class,
      user_id: hero.user_id,
      level: hero.level,
      gold: hero.gold,
      hp: hero.hp,
      max_hp: hero.max_hp,
      xp: hero.exp,
      strength: attrs["strength"] || 50,
      intelligence: attrs["intelligence"] || 50,
      willpower: attrs["willpower"] || 50,
      agility: attrs["agility"] || 50,
      speed: attrs["speed"] || 50,
      endurance: attrs["endurance"] || 50,
      personality: attrs["personality"] || 50,
      luck: attrs["luck"] || 50,
      location: "Винтерхолд",
      log: [
        %{
          id: nil,
          message:
            "Добро пожаловать в Винтерхолд, искатель знаний! Ваш путь к мудрости начинается здесь. Мара направляет ваше обучение.",
          inserted_at: DateTime.utc_now(),
          game_time: socket_world_game_time()
        }
      ]
    }
  end

  defp socket_world_game_time do
    # Safe fallback for default hero state used before subscriptions kick in.
    WorldClock.snapshot().game_time
  end

  defp calc_max_mana(hero_state) do
    (hero_state.intelligence + hero_state.willpower) * 2
  end

  defp calc_max_stamina(hero_state) do
    (hero_state.endurance + hero_state.speed) * 2
  end

  defp hp_pct(hp, max_hp) when max_hp > 0, do: round(hp / max_hp * 100)
  defp hp_pct(_, _), do: 0

  defp xp_pct(xp, level) when level > 0, do: min(100, round(xp / (level * 100) * 100))
  defp xp_pct(_, _), do: 0

  defp status_text(:idle), do: "Бездействует"
  defp status_text(:combat), do: "В бою"
  defp status_text(:resting), do: "Отдыхает"
  defp status_text(:questing), do: "Выполняет квест"
  defp status_text(:fleeing), do: "Бежит"
  defp status_text(:trading), do: "Торгует"
  defp status_text(:leveling_up), do: "↑ Уровень!"
  defp status_text(:sovngarde), do: "В Совнгарде"
  defp status_text(_), do: "Бездействует"

  defp status_class(:idle), do: "bg-foreground/10 text-foreground/60"
  defp status_class(:combat), do: "bg-red-500/20 text-red-400"
  defp status_class(:resting), do: "bg-blue-500/20 text-blue-400"
  defp status_class(:questing), do: "bg-primary/20 text-primary"
  defp status_class(:leveling_up), do: "bg-yellow-500/20 text-yellow-400"
  defp status_class(:sovngarde), do: "bg-primary/30 text-primary animate-pulse shadow-[0_0_10px_rgba(var(--color-primary),0.5)]"
  defp status_class(_), do: "bg-foreground/10 text-foreground/60"

  defp format_game_time(%{hour: h, minute: m}) do
    "#{String.pad_leading(to_string(h), 2, "0")}:#{String.pad_leading(to_string(m), 2, "0")}"
  end

  defp format_real_date(dt) do
    months = ~w(Января Февраля Марта Апреля Мая Июня Июля Августа Сентября Октября Ноября Декабря)
    month_name = Enum.at(months, dt.month - 1)
    "Среда, #{dt.day} #{month_name} #{dt.year} г."
  end

  defp format_real_time(dt) do
    h = String.pad_leading(to_string(dt.hour), 2, "0")
    m = String.pad_leading(to_string(dt.minute), 2, "0")
    s = String.pad_leading(to_string(dt.second), 2, "0")
    "#{h}:#{m}:#{s}"
  end

  def sovngarde_view(assigns) do
    ~H"""
    <div class="relative flex flex-col h-screen overflow-hidden bg-celestial text-white font-body">
      <!-- Background Text Effects (Whispers) -->
      <div class="absolute inset-0 pointer-events-none opacity-10 overflow-hidden">
        <div class="absolute top-[10%] left-[5%] text-2xl font-headline floating-celestial" style="animation-delay: 1s">Шор наблюдает...</div>
        <div class="absolute top-[40%] right-[10%] text-3xl font-headline floating-celestial" style="animation-delay: 2.5s">Валгалла ждет своих героев</div>
        <div class="absolute bottom-[20%] left-[15%] text-xl font-headline floating-celestial" style="animation-delay: 0.5s">Смерть — лишь начало пути</div>
      </div>

      <!-- Header / Nav -->
      <header class="flex-shrink-0 flex items-center justify-between px-8 py-4 glass-panel border-none z-20">
        <div class="flex items-center gap-4">
          <div class="w-10 h-10 rounded-full bg-blue-400/20 border border-blue-400/50 flex items-center justify-center animate-pulse">
             <span class="text-blue-300">✨</span>
          </div>
          <h1 class="font-headline text-xl tracking-[0.2em] uppercase glow-text-celestial">Совнгард</h1>
        </div>
        <.game_nav active_tab={:dashboard} theme="dark" />
      </header>

      <!-- Main Layout -->
      <main class="flex-1 flex gap-8 p-8 overflow-hidden z-10">
        
        <!-- LEFT: Aether Clock & Status -->
        <div class="w-1/3 flex flex-col items-center justify-center space-y-8">
           <div class="relative group">
              <!-- Outer Ring -->
              <div class="w-64 h-64 rounded-full border-4 border-blue-400/20 flex items-center justify-center relative overflow-hidden glass-panel">
                <div class="absolute inset-0 bg-blue-500/5 animate-pulse"></div>
                <!-- The Actual Timer Hook -->
                <div 
                  id="sovngarde-timer" 
                  phx-hook="SovngardeTimer" 
                  data-respawn-at={if @hero_state.respawn_at, do: DateTime.to_iso8601(@hero_state.respawn_at), else: ""}
                  class="aether-clock text-6xl font-headline glow-text-celestial"
                >
                  00:00
                </div>
              </div>
              <div class="mt-4 text-center">
                <div class="text-blue-300/60 uppercase tracking-widest text-xs mb-1">До возвращения в Тамриэль</div>
                <div class="text-sm font-headline opacity-80"><%= @hero_state.location %></div>
              </div>
           </div>

           <!-- Death Intervention Panel -->
           <div class="w-full max-w-sm p-6 glass-panel rounded-2xl space-y-4 floating-celestial">
              <h3 class="font-headline text-sm tracking-widest uppercase text-blue-300 border-b border-white/10 pb-2">Пульт Высшего Вмешательства</h3>
              <p class="text-xs opacity-50 leading-relaxed font-body">В этом измерении магия восстановления бессильна. Лишь воля богов может вернуть душу в бренное тело раньше срока.</p>
              
              <button 
                type="button"
                phx-click="divine_intervention"
                disabled={@hero_state.intervention_power < 100}
                class="w-full py-3 bg-blue-500/20 border border-blue-400/40 text-blue-300 font-headline uppercase text-xs tracking-widest hover:bg-blue-500 hover:text-white transition-all duration-500 disabled:opacity-30 flex flex-col items-center group overflow-hidden relative"
              >
                <span class="relative z-10">Вмешательство в смерть</span>
                <span :if={@hero_state.intervention_power < 100} class="text-[8px] opacity-40 group-hover:opacity-60">[ ЗАБЛОКИРОВАНО ]</span>
                <span :if={@hero_state.intervention_power >= 100} class="text-[8px] opacity-80 group-hover:opacity-100 animate-pulse text-blue-400">[ ГОТОВО ]</span>
                <div class="absolute inset-y-0 -left-full group-hover:left-full w-full bg-gradient-to-r from-transparent via-white/10 to-transparent transition-all duration-1000 skew-x-12"></div>
              </button>
              
              <div class="flex items-center gap-2 px-3 py-1 bg-white/5 rounded-full border border-white/10 w-fit mx-auto">
                 <div class="w-2 h-2 rounded-full bg-blue-400 animate-ping"></div>
                 <span class="text-[10px] uppercase tracking-tighter opacity-70">Связь с душой: Стабильна</span>
              </div>
           </div>
        </div>

        <!-- RIGHT: Whispers from Valor (Journal) -->
        <div class="flex-1 flex flex-col glass-panel rounded-3xl overflow-hidden shadow-2xl">
           <div class="p-6 border-b border-white/10 flex justify-between items-end">
              <div>
                <h2 class="font-headline text-2xl tracking-wide glow-text-celestial">Шёпот Залов Доблести</h2>
                <span class="text-xs opacity-40 uppercase tracking-widest">Посмертный журнал героя</span>
              </div>
              <div class="text-right">
                <div class="text-sm font-headline text-blue-300"><%= @hero_state.hp %> / <%= @hero_state.max_hp %> HP</div>
                <div class="text-[10px] opacity-30">МЕНТАЛЬНОЕ ВОССТАНОВЛЕНИЕ</div>
              </div>
           </div>
           
               <div class="flex-1 overflow-y-auto p-8 space-y-6">
               <%= for entry <- sovngarde_logs(assigns) do %>
                 <div class="flex gap-6 group">
                    <div class="flex-shrink-0 w-1 pt-1">
                       <div class="h-full w-full bg-gradient-to-b from-blue-400/50 to-transparent rounded-full opacity-0 group-hover:opacity-100 transition-opacity"></div>
                    </div>
                    <div class="space-y-1">
                       <div class="text-xs text-blue-300/40 font-headline"><%= format_game_time(entry.game_time || @game_time) %></div>
                       <div class="text-lg font-light leading-relaxed text-blue-50/80 group-hover:text-white transition-colors"><%= entry.message %></div>
                    </div>
                 </div>
               <% end %>
            </div>

           <!-- Bottom Decor -->
           <div class="p-4 bg-white/5 border-t border-white/5 flex justify-center gap-12 text-[10px] uppercase tracking-[0.3em] opacity-30">
              <span>СИЛА: <%= @hero_state.intervention_power %></span>
              <span>•</span>
              <span>РЕЗОНАНС: ВЫСОКИЙ</span>
              <span>•</span>
              <span>ПОКОЙ: 100%</span>
           </div>
        </div>
      </main>
    </div>
    """
  end

  defp filter_logs_by_context(logs, context) do
    Enum.filter(logs, fn entry ->
      (entry.metadata || %{})[:context] == context
    end)
  end

  defp normal_logs(assigns) do
    filter_logs_by_context(assigns.hero_state.log, :normal)
  end

  defp sovngarde_logs(assigns) do
    filter_logs_by_context(assigns.hero_state.log, :sovngarde)
  end
end
