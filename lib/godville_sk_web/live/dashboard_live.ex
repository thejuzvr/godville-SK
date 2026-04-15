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
    <div class="flex flex-col h-screen overflow-hidden bg-background relative font-body">
      <!-- Arcane texture background -->
      <div class="absolute inset-0 bg-[url('/images/login-bg2.jpg')] bg-cover bg-center opacity-10 pointer-events-none"></div>
      
      <!-- Top Nav -->
      <div class="relative z-10 border-b-2 border-border/80 bg-background/90 backdrop-blur-sm">
        <.game_nav active_tab={:dashboard} />
      </div>

      <!-- Queue Banner -->
      <div :if={@queue_entry != nil} class="relative z-20 w-full bg-red-900/20 border-b border-red-500/50 backdrop-blur-md px-4 py-2 flex items-center justify-center gap-4 text-[10px] font-headline uppercase tracking-widest text-red-100 shadow-[0_4px_20px_rgba(150,0,0,0.2)]">
        <div class="w-2 h-2 bg-red-500 rounded-full animate-ping"></div>
        <span>Идёт поиск противника на арене (<%= case elem(@queue_entry, 0) do
          :duel -> "Дуэль 1x1"
          :team_3v3 -> "3x3"
          :team_5v5 -> "5x5"
          _ -> "Дуэль"
        end %>)</span>
        <span class="text-white bg-black/50 px-2 py-1 border border-red-500/30 rounded-sm font-mono tracking-normal" id="arena-stopwatch" phx-hook="ArenaQueueStopwatch" data-joined-at={DateTime.to_iso8601(elem(@queue_entry, 1))}>
          00:00
        </span>
      </div>

      <!-- Main layout -->
      <div class="flex flex-1 overflow-hidden relative z-10 p-2 lg:p-4 gap-2 lg:gap-4">
        
        <!-- LEFT SIDEBAR -->
        <aside class="w-64 flex-shrink-0 bg-background/80 backdrop-blur-md border-[3px] border-double border-border/40 overflow-y-auto relative hidden md:block">
          <div class="absolute top-0 w-full h-1 bg-gradient-to-r from-transparent via-primary/50 to-transparent"></div>
          
          <div class="p-4 space-y-6">
            <!-- Hero Header -->
            <div class="text-center border-b border-border/30 pb-4">
              <div class="w-16 h-16 mx-auto mb-3 bg-background border border-primary/40 flex items-center justify-center flex-shrink-0 shadow-[0_0_15px_rgba(200,150,50,0.1)] relative transform rotate-45">
                <div class="absolute inset-1 border border-primary/20"></div>
                <span class="font-headline text-primary text-2xl tracking-widest transform -rotate-45">
                  <%= String.first(@hero.name) |> String.upcase() %>
                </span>
              </div>
              <div class="font-headline text-primary text-xl leading-tight uppercase tracking-widest truncate">
                <%= @hero.name %>
              </div>
              <div class="text-foreground/50 text-[10px] uppercase mt-1 tracking-widest">
                Уровень <%= @hero_state.level %> · <%= @hero.race %>
              </div>
              <div class="text-xs text-primary/70 font-headline uppercase tracking-widest mt-2 border-t border-border/30 pt-2 mx-4">
                <%= @hero_state.location %>
              </div>
            </div>

            <!-- Status badge -->
            <div class="text-center">
              <div class={"text-[10px] uppercase font-headline tracking-widest px-2 py-1 border border-border/50 #{status_class(@hero_state.status)}"}>
                <%= status_text(@hero_state.status) %>
              </div>
              <%= if @hero_state.status == :questing && @hero_state.target do %>
                <div class="mt-4 px-2">
                  <div class="text-[10px] text-foreground/70 font-headline uppercase tracking-widest truncate mb-1">
                    <%= @hero_state.target.name %>
                  </div>
                  <div class="w-full h-1 bg-background border border-border/50">
                    <div
                      class="h-full bg-primary/80 transition-all duration-300"
                      style={"width: #{quest_progress_pct(@hero_state.quest_progress, @hero_state.target.steps)}%"}
                    >
                    </div>
                  </div>
                  <div class="text-[10px] uppercase tracking-widest text-foreground/40 mt-1">
                    Этап <%= @hero_state.quest_progress %> / <%= @hero_state.target.steps %>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Vitality Bars -->
            <div class="space-y-4 px-2">
              <div>
                <div class="flex justify-between text-[10px] font-headline uppercase tracking-widest text-foreground/50 mb-1">
                  <span class="text-red-400">Жизнь</span>
                  <span><%= @hero_state.hp %> / <%= @hero_state.max_hp %></span>
                </div>
                <div class="w-full h-1.5 bg-background border border-border/30">
                  <div class="h-full bg-red-600 transition-all duration-500 shadow-[0_0_8px_rgba(220,38,38,0.4)]" style={"width: #{hp_pct(@hero_state.hp, @hero_state.max_hp)}%"}></div>
                </div>
              </div>
              
              <div>
                <div class="flex justify-between text-[10px] font-headline uppercase tracking-widest text-foreground/50 mb-1">
                  <span class="text-blue-400">Магия</span>
                  <span><%= @max_mana %> / <%= @max_mana %></span>
                </div>
                <div class="w-full h-1.5 bg-background border border-border/30">
                  <div class="h-full bg-blue-500/80 shadow-[0_0_8px_rgba(59,130,246,0.4)]" style="width: 100%"></div>
                </div>
              </div>
              
              <div>
                <div class="flex justify-between text-[10px] font-headline uppercase tracking-widest text-foreground/50 mb-1">
                  <span class="text-green-400">Сил</span>
                  <span><%= round(@hero_state.stamina) %> / <%= @hero_state.stamina_max %></span>
                </div>
                <div class="w-full h-1.5 bg-background border border-border/30">
                  <div class="h-full bg-green-500/80 transition-all duration-500 shadow-[0_0_8px_rgba(34,197,94,0.4)]" style={"width: #{hp_pct(@hero_state.stamina, @hero_state.stamina_max)}%"}></div>
                </div>
              </div>
            </div>

            <!-- Anatomy Summary -->
            <div class="px-2 pb-4">
              <div class="text-[10px] font-headline uppercase tracking-widest text-primary/70 mb-2 border-b border-border/30 pb-1 text-center">
                Состояние тела
              </div>
              <div class="grid grid-cols-2 gap-2 text-[8px] uppercase tracking-widest">
                <% body_parts = Map.get(@hero_state, :body_parts) || GodvilleSk.Hero.BodyParts.default() %>
                <%= for part <- [:head, :left_arm, :right_arm, :left_leg, :right_leg] do %>
                  <% label = case part do
                    :head -> "Голова"
                    :left_arm -> "Л. Рука"
                    :right_arm -> "П. Рука"
                    :left_leg -> "Л. Нога"
                    :right_leg -> "П. Нога"
                  end %>
                  <% status = GodvilleSk.Hero.BodyParts.functional?(body_parts, part) |> case do
                    true -> if Map.get(body_parts, part, :healthy) == :injured, do: "Ранена", else: "Цела"
                    false -> "Утрачена"
                  end %>
                  <% status_color = GodvilleSk.Hero.BodyParts.functional?(body_parts, part) |> case do
                    true -> if Map.get(body_parts, part, :healthy) == :injured, do: "text-yellow-500", else: "text-green-500"
                    false -> "text-red-600 font-bold"
                  end %>
                  <div class={"flex justify-between border-b border-border/20 py-1 #{if part == :head do "col-span-2" else "" end}"}>
                    <span class="text-foreground/50"><%= label %></span>
                    <span class={status_color}><%= status %></span>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Wealth & Stats -->
            <div class="grid grid-cols-2 gap-px bg-border/30 border border-border/50 overflow-hidden mx-2">
              <div class="bg-background/80 p-2 text-center">
                <div class="text-[9px] uppercase tracking-widest text-foreground/50 mb-1">Золото</div>
                <div class="text-sm font-headline text-yellow-500"><%= @hero_state.gold %></div>
              </div>
              <div class="bg-background/80 p-2 text-center">
                <div class="text-[9px] uppercase tracking-widest text-foreground/50 mb-1">Смертей</div>
                <div class="text-sm font-headline text-red-400/80"><%= (Map.get(@hero_state, :statistics) || %{})[:total_deaths] || 0 %></div>
              </div>
            </div>

            <!-- Equipment Summary -->
            <div class="border-t border-border/30 pt-4 px-2">
              <div class="text-[10px] font-headline uppercase tracking-widest text-primary/70 mb-3 text-center">
                Арсенал (<%= calc_attack_class(@hero_state) %>/<%= @hero_state.ac %>)
              </div>
              <div class="space-y-1">
                <% slots = [{:weapon, "Орж"}, {:head, "Глв"}, {:torso, "Трс"}, {:legs, "Пнж"}, {:arms, "Рук"}, {:boots, "Стп"}, {:amulet, "Амл"}, {:ring, "Клц"}] %>
                <%= for {slot_id, slot_label} <- slots do %>
                  <div class="flex items-center text-[10px] border-b border-border/10 py-1">
                    <span class="w-8 uppercase tracking-widest text-foreground/40"><%= slot_label %></span>
                    <%= if item = (Map.get(@hero_state, :equipment) || %{})[slot_id] do %>
                      <span class="text-primary/90 truncate flex-1 font-headline tracking-wide" title={item}><%= item %></span>
                    <% else %>
                      <span class="text-foreground/20 italic flex-1">—</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
            
            <!-- Companion -->
            <div class="border-t border-border/30 pt-4 px-2 text-center">
              <div class="text-[10px] font-headline uppercase tracking-widest text-foreground/50 mb-2">
                Спутник
              </div>
              <div class="text-[10px] text-foreground/30 uppercase tracking-widest">—</div>
            </div>
          </div>
        </aside>

        <!-- CENTER TOME: Adventure Journal and Combat -->
        <main class="flex-1 flex flex-col bg-background/90 backdrop-blur-md border border-border/50 relative overflow-hidden">
          <!-- Decorative inner borders -->
          <div class="absolute inset-2 border-[1px] border-primary/10 pointer-events-none"></div>

          <!-- ENEMY COMBAT ARENA -->
          <div
            :if={@hero_state.status in [:combat, :combat_initiative, :combat_round] && @hero_state.target}
            class="flex-shrink-0 bg-background border-b-2 border-red-900/30 p-6 relative overflow-hidden shadow-[inset_0_-20px_50px_rgba(150,0,0,0.05)] w-full flex flex-col"
            style="height: 320px;"
          >
            <!-- Heavy geometric decorative lines -->
            <div class="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-red-900/0 via-red-600/50 to-red-900/0"></div>
            
            <!-- Top header VS -->
            <div class="flex justify-between items-center z-10 w-full mb-4">
              <!-- Hero -->
              <div class="w-5/12 flex flex-col items-start gap-1">
                <div class="font-headline text-xl text-primary tracking-widest uppercase truncate w-full">
                  <%= @hero.name %>
                </div>
                <div class="w-full h-1.5 bg-background border border-border/50">
                  <div class="h-full bg-red-600 transition-all duration-500 shadow-[0_0_10px_rgba(220,38,38,0.5)]" style={"width: #{hp_pct(@hero_state.hp, @hero_state.max_hp)}%"}></div>
                </div>
                <span class="text-[10px] font-headline tracking-widest text-foreground/50 uppercase mix-blend-screen">
                  <%= max(0, @hero_state.hp) %> / <%= @hero_state.max_hp %> ОЗ
                </span>
              </div>
              
              <!-- Center -->
              <div class="font-headline text-3xl text-red-600/30 tracking-[0.5em] px-2 flex-shrink-0">
                ПРОТИВ
              </div>
              
              <!-- Target -->
              <% target_max_hp = Map.get(@hero_state.target, :max_hp) || 100 %>
              <div class="w-5/12 flex flex-col items-end text-right gap-1">
                <div class="font-headline text-xl text-red-500 tracking-widest uppercase truncate w-full">
                  <%= @hero_state.target.name %>
                </div>
                <div class="w-full h-1.5 bg-background border border-red-900/50 transform rotate-180">
                  <div class="h-full bg-red-700 transition-all duration-500 shadow-[0_0_10px_rgba(185,28,28,0.5)]" style={"width: #{hp_pct(@hero_state.target.hp, target_max_hp)}%"}></div>
                </div>
                <span class="text-[10px] font-headline tracking-widest text-foreground/50 uppercase mix-blend-screen">
                  <%= max(0, @hero_state.target.hp) %> / <%= target_max_hp %> ОЗ
                </span>
              </div>
            </div>
            
            <!-- 3D D20 Dice Container -->
            <div class="flex-1 flex items-center justify-center relative w-full h-full">
              <div id="d20-combat" phx-hook="DiceRollerHook" data-theme={@current_user.dice_theme} class="d20-container" phx-update="ignore"></div>
            </div>
          </div>

          <!-- Quest Progress Panel Active Overlay -->
          <%= if @hero_state.status == :questing && @hero_state.target && !is_combat_status(@hero_state.status) do %>
            <div class="flex-shrink-0 bg-primary/5 border-b border-primary/20 p-4">
              <div class="flex items-center justify-between mb-3">
                <div class="flex items-center gap-3 border border-primary/20 bg-background/50 px-3 py-1">
                  <span class="w-2 h-2 bg-primary transform rotate-45"></span>
                  <span class="text-[10px] font-headline text-primary uppercase tracking-widest">
                    <%= case @hero_state.target.type do
                      :bounty -> "Охота"
                      :delivery -> "Доставка"
                      :gathering -> "Сбор"
                      :dungeon -> "Подземелье"
                      _ -> "Задание"
                    end %>
                  </span>
                </div>
                <span class="text-[10px] text-foreground/40 font-headline uppercase tracking-widest border-b border-foreground/20">
                  Этап <%= @hero_state.quest_progress %> / <%= @hero_state.target.steps %>
                </span>
              </div>
              <div class="font-headline text-lg text-foreground/90 uppercase tracking-widest mb-3 border-l-2 border-primary/50 pl-3">
                <%= @hero_state.target.name %>
              </div>
              <div class="w-full h-1 bg-background border border-border/50 overflow-hidden relative">
                <div class="absolute inset-0 bg-[url('/images/noise.png')] opacity-10 mix-blend-overlay"></div>
                <div class="h-full bg-primary/70 shadow-[0_0_10px_rgba(200,150,50,0.5)] transition-all duration-500" style={"width: #{quest_progress_pct(@hero_state.quest_progress, @hero_state.target.steps)}%"}></div>
              </div>
            </div>
          <% end %>

          <!-- Journal Header -->
          <div class="flex-shrink-0 flex items-center justify-between px-6 py-4 border-b border-border/50 bg-background z-10">
            <h2 class="font-headline text-sm uppercase tracking-[0.2em] text-primary/80">Хроники Героя</h2>
            <div class="flex gap-0 border border-border/50 bg-background">
              <button phx-click="switch_journal_tab" phx-value-tab="journal" class={"text-[10px] font-headline uppercase tracking-widest px-4 py-2 transition-all #{if @journal_tab == :journal, do: "bg-primary/10 text-primary", else: "text-foreground/40 hover:bg-white/5"}"}>
                Летопись
              </button>
              <button phx-click="switch_journal_tab" phx-value-tab="battle_keeper" class={"text-[10px] font-headline uppercase tracking-widest px-4 py-2 border-l border-border/50 transition-all #{if @journal_tab == :battle_keeper, do: "bg-red-500/10 text-red-400", else: "text-foreground/40 hover:bg-white/5"}"}>
                Архив Битв
              </button>
            </div>
          </div>

          <!-- Log entries -->
          <div class="flex-1 overflow-y-auto px-6 py-4 space-y-3 font-body text-sm relative z-10">
            <%= if @journal_tab == :battle_keeper do %>
              <%= if length(battle_logs(assigns)) > 0 do %>
                <%= for entry <- battle_logs(assigns) do %>
                  <div class="flex gap-4 p-2 border-l border-red-900/30 bg-red-900/5 hover:bg-red-900/10 transition-colors">
                    <span class="text-red-400/60 font-headline text-[10px] tracking-widest uppercase flex-shrink-0 w-16">
                      <%= format_game_time(entry.game_time || @game_time) %>
                    </span>
                    <span class="text-foreground/80 leading-relaxed text-sm"><%= entry.message %></span>
                  </div>
                <% end %>
              <% else %>
                <div class="flex items-center justify-center h-full text-foreground/30 font-headline uppercase tracking-widest text-[10px] text-center border-2 border-dashed border-border/20 p-8">
                  В архиве нет записей о битвах.<br/>Ожидание крови.
                </div>
              <% end %>
            <% else %>
              <%= for entry <- normal_logs(assigns) do %>
                <div class="flex gap-4 group">
                  <span class="text-primary/50 font-headline text-[10px] tracking-widest uppercase flex-shrink-0 w-16 border-b border-transparent group-hover:border-primary/20 transition-all">
                    <%= format_game_time(entry.game_time || @game_time) %>
                  </span>
                  <span class="text-foreground/90 leading-relaxed text-sm group-hover:text-foreground transition-colors"><%= entry.message %></span>
                </div>
              <% end %>
            <% end %>
          </div>

          <!-- XP Bar Footer -->
          <div class="flex-shrink-0 border-t border-border/40 p-4 bg-background/90 z-10">
            <div class="flex items-center gap-4">
              <span class="text-[10px] text-foreground/40 font-headline uppercase tracking-widest">Опыт</span>
              <div class="flex-1 h-1 bg-background border border-border/30 relative overflow-hidden">
                <div class="absolute h-full left-0 bg-primary/50" style={"width: #{xp_pct(@hero_state.xp, @hero_state.level)}%"}></div>
              </div>
              <span class="text-[10px] text-foreground/40 font-headline tracking-widest">
                <%= @hero_state.xp %> / <%= @hero_state.level * 100 %>
              </span>
            </div>
          </div>
        </main>

        <!-- RIGHT SIDEBAR: World & Mechanics -->
        <aside class="w-64 flex-shrink-0 overflow-y-auto bg-background/80 backdrop-blur-md border-[3px] border-double border-border/40 hidden xl:block relative">
          <div class="p-4 space-y-6">
            
            <!-- Astrals (Time & Date) -->
            <div class="bg-background border border-border/50 relative p-3">
              <div class="absolute top-0 right-0 w-2 h-2 border-t border-r border-primary/50"></div>
              <div class="text-[10px] font-headline uppercase tracking-widest text-primary/70 mb-3 border-b border-border/30 pb-1">Астральные Часы</div>
              
              <div class="mb-3">
                <div class="text-[9px] uppercase tracking-widest text-foreground/40 mb-1">Время Нирна</div>
                <div class="flex flex-col">
                  <span class="font-headline text-primary text-sm tracking-widest uppercase">
                    <%= format_game_time(@game_time) %>
                  </span>
                  <span class="text-[10px] text-foreground/60 tracking-wider">
                    <%= @game_time.day_name %>, <%= @game_time.day %>-й день <%= @game_time.month %><br/>4Э <%= @game_time.year %>
                  </span>
                </div>
              </div>
              
              <div class="pt-2 border-t border-border/30">
                <div class="text-[9px] uppercase tracking-widest text-foreground/40 mb-1">Связь (Реальность)</div>
                <div id="local-clock" phx-hook="LocalClock" data-utc={DateTime.to_iso8601(@real_time)} class="flex flex-col">
                  <span data-role="time" class="font-headline text-foreground/70 text-xs tracking-widest">
                    <%= format_real_time(@real_time) %>
                  </span>
                  <span data-role="date" class="text-[9px] text-foreground/50 tracking-wider">
                    <%= format_real_date(@real_time) %>
                  </span>
                </div>
              </div>
            </div>

            <!-- Conditions -->
            <div class="bg-background border border-border/50 relative p-3">
              <div class="text-[10px] font-headline uppercase tracking-widest text-primary/70 mb-3 border-b border-border/30 pb-1">Условия Среды</div>
              <div class="space-y-2 text-[10px] uppercase tracking-widest">
                <div class="flex justify-between">
                  <span class="text-foreground/40">Цикл</span>
                  <span class="text-primary"><%= @game_time.time_of_day %></span>
                </div>
                <div class="flex justify-between">
                  <span class="text-foreground/40">Сезон</span>
                  <span class="text-foreground/80"><%= @game_time.season %></span>
                </div>
                <div class="flex justify-between">
                  <span class="text-foreground/40">Небо</span>
                  <span class="text-foreground/80"><%= @game_time.weather %></span>
                </div>
              </div>
              
              <div class="mt-4 pt-2 border-t border-border/30 text-center">
                <span :if={@hero_state.luck_modifier < 0} class="text-[10px] px-2 py-1 bg-red-900/20 text-red-400 border border-red-900/50 uppercase tracking-widest">
                  Проклятие (<%= @hero_state.luck_modifier %>)
                </span>
                <span :if={@hero_state.luck_modifier >= 0} class="text-[9px] uppercase tracking-widest text-foreground/30">
                  Ауры спокойны
                </span>
              </div>
            </div>

            <!-- Intervention Override -->
            <div class="bg-background border border-border/50 relative p-3 shadow-[0_0_15px_rgba(200,150,50,0.05)]">
              <div class="absolute top-0 right-0 w-2 h-2 bg-primary/50"></div>
              <div class="absolute bottom-0 left-0 w-2 h-2 bg-primary/50"></div>
              
              <div class="text-[10px] font-headline uppercase tracking-widest text-primary mb-2 border-b border-border/30 pb-1">
                Глас Создателя
              </div>
              
              <div class="mb-4 bg-background/50 border border-border/30 p-2">
                <div class="flex justify-between text-[9px] uppercase tracking-widest text-foreground/60 mb-1">
                  <span>Высшая Сила</span>
                  <span class="text-primary"><%= @hero_state.intervention_power %> / 100</span>
                </div>
                <div class="w-full h-1 bg-background border border-border/50">
                  <div class="h-full bg-primary/80 transition-all duration-500 shadow-[0_0_5px_rgba(200,150,50,0.5)]" style={"width: #{@hero_state.intervention_power}%"}></div>
                </div>
              </div>

              <.form for={@whisper_form} phx-submit="send_whisper">
                <div class="mb-3">
                  <textarea
                    id="whisper-textarea"
                    name="whisper[text]"
                    placeholder="ВНЕДРИТЬ МЫСЛЬ..."
                    maxlength="200"
                    rows="2"
                    class="w-full px-2 py-2 text-[10px] uppercase tracking-wider bg-background border border-border/50 text-foreground placeholder:text-foreground/30 focus:border-primary focus:outline-none resize-none font-headline"
                  ></textarea>
                </div>
                <button type="submit" disabled={@hero_state.intervention_power < 5} class="w-full text-center py-2 text-[10px] font-headline tracking-[0.2em] uppercase border border-primary/50 bg-primary/10 hover:bg-primary/20 text-primary disabled:opacity-30 transition-all cursor-pointer">
                  ПОСЛАТЬ ШЁПОТ [5]
                </button>
              </.form>

              <div class="grid grid-cols-2 gap-1 mt-1">
                <button type="button" phx-click="bless" disabled={@hero_state.intervention_power < 20 or @hero_state.status == :sovngarde} class="text-[9px] font-headline tracking-widest border border-amber-900/50 bg-amber-900/20 text-amber-500 hover:bg-amber-900/40 p-1 disabled:opacity-30">
                  БЛАГО [20]
                </button>
                <button type="button" phx-click="heal" disabled={@hero_state.intervention_power < 10 or @hero_state.status == :sovngarde} class="text-[9px] font-headline tracking-widest border border-emerald-900/50 bg-emerald-900/20 text-emerald-500 hover:bg-emerald-900/40 p-1 disabled:opacity-30">
                  ИСЦЕЛИТЬ [10]
                </button>
                <button type="button" phx-click="punish" disabled={@hero_state.intervention_power < 12 or @hero_state.status == :sovngarde} class="text-[9px] font-headline tracking-widest border border-red-900/50 bg-red-900/20 text-red-500 hover:bg-red-900/40 p-1 disabled:opacity-30">
                  КАРАТЬ [12]
                </button>
                <button type="button" phx-click="lightning" disabled={@hero_state.intervention_power < 5 or @hero_state.status == :sovngarde} class="text-[9px] font-headline tracking-widest border border-yellow-500/50 bg-yellow-500/20 text-yellow-500 hover:bg-yellow-500/40 p-1 disabled:opacity-30">
                  МОЛНИЯ [5]
                </button>
                <button type="button" phx-click="fear" disabled={@hero_state.intervention_power < 8 or @hero_state.status == :sovngarde} class="text-[9px] font-headline tracking-widest border border-purple-900/50 bg-purple-900/20 text-purple-500 hover:bg-purple-900/40 p-1 disabled:opacity-30">
                  СТРАХ [8]
                </button>
                <button type="button" phx-click="send_loot" disabled={@hero_state.intervention_power < 15 or @hero_state.status == :sovngarde} class="text-[9px] font-headline tracking-widest border border-blue-900/50 bg-blue-900/20 text-blue-500 hover:bg-blue-900/40 p-1 disabled:opacity-30">
                  ПОДАРОК [15]
                </button>
              </div>

              <div :if={@last_whisper != ""} class="mt-3 pt-3 border-t border-border/30 text-[9px] text-foreground/50 font-body italic">
                <span class="text-primary uppercase tracking-widest font-headline block mb-1">Эхо:</span>
                <%= @last_whisper %>
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

        # Convert embedded structs to maps for template rendering
        hero_state = %{
          hero_state
          | equipment: Map.from_struct(hero_state.equipment),
            statistics: Map.from_struct(hero_state.statistics),
            temple: Map.from_struct(hero_state.temple)
        }

        world = WorldClock.snapshot()

        # Check if hero is already queued (e.g. after page reload)
        queue_entry = GodvilleSk.Arena.Matchmaking.get_queue_entry(hero.id)

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
         |> assign(:whisper_form, to_form(%{}, as: "whisper"))
         |> assign(:journal_tab, :journal)
         |> assign(:queue_entry, queue_entry)}
    end
  end

  def handle_info({:hero_update, hero_state}, socket) do
    old_logs = socket.assigns.hero_state.log

    # Convert embedded structs to maps for template rendering
    hero_state = %{
      hero_state
      | equipment: Map.from_struct(hero_state.equipment),
        statistics: Map.from_struct(hero_state.statistics),
        temple: Map.from_struct(hero_state.temple)
    }

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

  # --- Arena PubSub Events ---

  def handle_info({:match_found, _arena_id}, socket) do
    # AUTO-REDIRECT: match found, go to arena page immediately
    {:noreply,
     socket
     |> assign(:queue_entry, nil)
     |> push_navigate(to: ~p"/arena")}
  end

  def handle_info({:arena_start, _arena_id}, socket) do
    # Already redirected by :match_found; this is a no-op
    {:noreply, socket}
  end

  def handle_info({:queue_joined, _hero_id, queue_type, joined_at}, socket) do
    {:noreply, assign(socket, :queue_entry, {queue_type, joined_at})}
  end

  def handle_info({:queue_left, _hero_id}, socket) do
    {:noreply, assign(socket, :queue_entry, nil)}
  end

  def handle_info({:arena_victory, reward}, socket) do
    gold = reward[:gold] || 0
    xp = reward[:xp] || 0
    {:noreply, put_flash(socket, :info, "🏆 Победа на арене! +#{gold} з. +#{xp} XP")}
  end

  def handle_info({:arena_defeat, reward}, socket) do
    gold = reward[:gold] || 0
    {:noreply, put_flash(socket, :info, "💀 Поражение на арене. Утешительные: +#{gold} з.")}
  end

  def handle_info({:arena_result, _result}, socket) do
    {:noreply, socket}
  end

  def handle_info({:arena_attack, _info}, socket) do
    {:noreply, socket}
  end

  def handle_info({:soul_sold, _info}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/hero/new")}
  end

  # Catch-all: absorb any unhandled PubSub messages gracefully
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  def handle_event("send_whisper", %{"whisper" => %{"text" => text}}, socket)
      when byte_size(text) > 0 do
    if socket.assigns.hero_state.intervention_power >= 5 do
      GodvilleSk.Hero.send_whisper(socket.assigns.hero.name, text)
      {:noreply, assign(socket, :last_whisper, String.slice(text, 0, 200))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("bless", _params, socket) do
    if socket.assigns.hero_state.intervention_power >= 20 do
      GodvilleSk.Hero.bless(socket.assigns.hero.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("punish", _params, socket) do
    if socket.assigns.hero_state.intervention_power >= 12 do
      GodvilleSk.Hero.punish(socket.assigns.hero.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("heal", _params, socket) do
    if socket.assigns.hero_state.intervention_power >= 10 do
      GodvilleSk.Hero.heal(socket.assigns.hero.name, 25)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("lightning", _params, socket) do
    if socket.assigns.hero_state.intervention_power >= 5 do
      GodvilleSk.Hero.lightning(socket.assigns.hero.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("fear", _params, socket) do
    if socket.assigns.hero_state.intervention_power >= 8 do
      GodvilleSk.Hero.fear(socket.assigns.hero.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("send_loot", _params, socket) do
    if socket.assigns.hero_state.intervention_power >= 15 do
      GodvilleSk.Hero.send_loot(socket.assigns.hero.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("divine_intervention", _params, socket) do
    if socket.assigns.hero_state.status == :sovngarde and
         socket.assigns.hero_state.intervention_power >= 100 do
      GodvilleSk.Hero.divine_intervention(socket.assigns.hero.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("send_whisper", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("switch_journal_tab", %{"tab" => tab}, socket) do
    journal_tab = String.to_existing_atom(tab)
    {:noreply, assign(socket, :journal_tab, journal_tab)}
  rescue
    _ -> {:noreply, socket}
  end

  # ---- Helpers ----

  defp default_hero_state(hero) do
    attrs = hero.attributes || %{}

    hero_state = %GodvilleSk.Hero{
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
      equipment: GodvilleSk.Game.HeroEquipment.default(),
      statistics: GodvilleSk.Game.HeroStatistics.default(),
      temple: GodvilleSk.Game.HeroTemple.default(),
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

    # Convert embedded structs to maps for template rendering
    %{
      hero_state
      | equipment: Map.from_struct(hero_state.equipment),
        statistics: Map.from_struct(hero_state.statistics),
        temple: Map.from_struct(hero_state.temple)
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

  defp calc_attack_class(hero_state) do
    base = 10
    level_bonus = hero_state.level
    str_mod = div((hero_state.strength || 50) - 50, 10)

    weapon_damage = get_weapon_damage(hero_state.equipment.weapon)

    base + level_bonus + str_mod + weapon_damage
  end

  defp get_weapon_damage(nil), do: 0

  defp get_weapon_damage(weapon_name) do
    all_items = GodvilleSk.Game.Items.get_weapons() ++ GodvilleSk.GameData.items()

    case Enum.find(all_items, fn item -> item.name == weapon_name end) do
      nil -> 0
      item -> item.value || 0
    end
  end

  defp hp_pct(hp, max_hp) when max_hp > 0, do: round(hp / max_hp * 100)
  defp hp_pct(_, _), do: 0

  defp xp_pct(xp, level) when level > 0, do: min(100, round(xp / (level * 100) * 100))
  defp xp_pct(_, _), do: 0

  defp quest_progress_pct(progress, total) when total > 0,
    do: min(100, round(progress / total * 100))

  defp quest_progress_pct(_, _), do: 0

  defp is_combat_status(:combat), do: true
  defp is_combat_status(:combat_initiative), do: true
  defp is_combat_status(:combat_round), do: true
  defp is_combat_status(_), do: false

  defp status_text(:idle), do: "Бездействует"
  defp status_text(:combat), do: "В бою"
  defp status_text(:combat_initiative), do: "Вступает в бой"
  defp status_text(:combat_round), do: "В бою"
  defp status_text(:resting), do: "Отдыхает"
  defp status_text(:questing), do: "Выполняет квест"
  defp status_text(:fleeing), do: "Бежит"
  defp status_text(:trading), do: "Торгует"
  defp status_text(:leveling_up), do: "↑ Уровень!"
  defp status_text(:sovngarde), do: "В Совнгарде"
  defp status_text(_), do: "Бездействует"

  defp status_class(:idle), do: "bg-foreground/10 text-foreground/60"
  defp status_class(:combat), do: "bg-red-500/20 text-red-400"
  defp status_class(:combat_initiative), do: "bg-red-500/20 text-red-400"
  defp status_class(:combat_round), do: "bg-red-500/20 text-red-400"
  defp status_class(:resting), do: "bg-blue-500/20 text-blue-400"
  defp status_class(:questing), do: "bg-primary/20 text-primary"
  defp status_class(:leveling_up), do: "bg-yellow-500/20 text-yellow-400"

  defp status_class(:sovngarde),
    do:
      "bg-primary/30 text-primary animate-pulse shadow-[0_0_10px_rgba(var(--color-primary),0.5)]"

  defp status_class(_), do: "bg-foreground/10 text-foreground/60"

  defp format_game_time(%{hour: h, minute: m}) do
    "#{String.pad_leading(to_string(h), 2, "0")}:#{String.pad_leading(to_string(m), 2, "0")}"
  end

  defp format_game_time(%{"hour" => h, "minute" => m}) do
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
        <div
          class="absolute top-[10%] left-[5%] text-2xl font-headline floating-celestial"
          style="animation-delay: 1s"
        >
          Шор наблюдает...
        </div>
        <div
          class="absolute top-[40%] right-[10%] text-3xl font-headline floating-celestial"
          style="animation-delay: 2.5s"
        >
          Валгалла ждет своих героев
        </div>
        <div
          class="absolute bottom-[20%] left-[15%] text-xl font-headline floating-celestial"
          style="animation-delay: 0.5s"
        >
          Смерть — лишь начало пути
        </div>
      </div>
      <!-- Header / Nav -->
      <header class="flex-shrink-0 flex items-center justify-between px-8 py-4 glass-panel border-none z-20">
        <div class="flex items-center gap-4">
          <div class="w-10 h-10 rounded-full bg-blue-400/20 border border-blue-400/50 flex items-center justify-center animate-pulse">
            <span class="text-blue-300">✨</span>
          </div>
          <h1 class="font-headline text-xl tracking-[0.2em] uppercase glow-text-celestial">
            Совнгард
          </h1>
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
                data-respawn-at={
                  if @hero_state.respawn_at, do: DateTime.to_iso8601(@hero_state.respawn_at), else: ""
                }
                class="aether-clock text-6xl font-headline glow-text-celestial"
              >
                00:00
              </div>
            </div>
            <div class="mt-4 text-center">
              <div class="text-blue-300/60 uppercase tracking-widest text-xs mb-1">
                До возвращения в Тамриэль
              </div>
              <div class="text-sm font-headline opacity-80"><%= @hero_state.location %></div>
            </div>
          </div>
          <!-- Death Intervention Panel -->
          <div class="w-full max-w-sm p-6 glass-panel rounded-2xl space-y-4 floating-celestial">
            <h3 class="font-headline text-sm tracking-widest uppercase text-blue-300 border-b border-white/10 pb-2">
              Пульт Высшего Вмешательства
            </h3>
            <p class="text-xs opacity-50 leading-relaxed font-body">
              В этом измерении магия восстановления бессильна. Лишь воля богов может вернуть душу в бренное тело раньше срока.
            </p>

            <button
              type="button"
              phx-click="divine_intervention"
              disabled={@hero_state.intervention_power < 100}
              class="w-full py-3 bg-blue-500/20 border border-blue-400/40 text-blue-300 font-headline uppercase text-xs tracking-widest hover:bg-blue-500 hover:text-white transition-all duration-500 disabled:opacity-30 flex flex-col items-center group overflow-hidden relative"
            >
              <span class="relative z-10">Вмешательство в смерть</span>
              <span
                :if={@hero_state.intervention_power < 100}
                class="text-[8px] opacity-40 group-hover:opacity-60"
              >
                [ ЗАБЛОКИРОВАНО ]
              </span>
              <span
                :if={@hero_state.intervention_power >= 100}
                class="text-[8px] opacity-80 group-hover:opacity-100 animate-pulse text-blue-400"
              >
                [ ГОТОВО ]
              </span>
              <div class="absolute inset-y-0 -left-full group-hover:left-full w-full bg-gradient-to-r from-transparent via-white/10 to-transparent transition-all duration-1000 skew-x-12">
              </div>
            </button>

            <div class="flex items-center gap-2 px-3 py-1 bg-white/5 rounded-full border border-white/10 w-fit mx-auto">
              <div class="w-2 h-2 rounded-full bg-blue-400 animate-ping"></div>
              <span class="text-[10px] uppercase tracking-tighter opacity-70">
                Связь с душой: Стабильна
              </span>
            </div>
          </div>
        </div>
        <!-- RIGHT: Whispers from Valor (Journal) -->
        <div class="flex-1 flex flex-col glass-panel rounded-3xl overflow-hidden shadow-2xl">
          <div class="p-6 border-b border-white/10 flex justify-between items-end">
            <div>
              <h2 class="font-headline text-2xl tracking-wide glow-text-celestial">
                Шёпот Залов Доблести
              </h2>
              <span class="text-xs opacity-40 uppercase tracking-widest">
                Посмертный журнал героя
              </span>
            </div>
            <div class="text-right">
              <div class="text-sm font-headline text-blue-300">
                <%= @hero_state.hp %> / <%= @hero_state.max_hp %> HP
              </div>
              <div class="text-[10px] opacity-30">МЕНТАЛЬНОЕ ВОССТАНОВЛЕНИЕ</div>
            </div>
          </div>

          <div class="flex-1 overflow-y-auto p-8 space-y-6">
            <%= for entry <- sovngarde_logs(assigns) do %>
              <div class="flex gap-6 group">
                <div class="flex-shrink-0 w-1 pt-1">
                  <div class="h-full w-full bg-gradient-to-b from-blue-400/50 to-transparent rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                  </div>
                </div>
                <div class="space-y-1">
                  <div class="text-xs text-blue-300/40 font-headline">
                    <%= format_game_time(entry.game_time || @game_time) %>
                  </div>
                  <div class="text-lg font-light leading-relaxed text-blue-50/80 group-hover:text-white transition-colors">
                    <%= entry.message %>
                  </div>
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
    assigns.hero_state.log
    |> filter_logs_by_context(:normal)
    |> Enum.filter(fn entry ->
      metadata = entry.metadata || %{}
      metadata[:type] not in ["quest_event", "combat_roll", "initiative_roll"]
    end)
  end

  defp sovngarde_logs(assigns) do
    filter_logs_by_context(assigns.hero_state.log, :sovngarde)
  end

  defp battle_logs(assigns) do
    assigns.hero_state.battle_log || []
  end
end
