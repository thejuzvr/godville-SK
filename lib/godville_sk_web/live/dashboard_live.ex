defmodule GodvilleSkWeb.DashboardLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game

  @intervention_regen_interval 60_000

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen overflow-hidden bg-background">
      <!-- Top Nav -->
      <nav class="flex-shrink-0 bg-card border-b border-border flex items-center px-4 h-11 gap-4">
        <div class="flex items-center gap-2 mr-4">
          <svg class="w-5 h-5 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M12 2L2 7v5c0 5.25 4.25 10.15 10 11.25C17.75 22.15 22 17.25 22 12V7L12 2z" />
          </svg>
          <span class="font-headline text-primary text-xs tracking-widest">ElderScrollsIdle</span>
        </div>
        <div class="flex items-center gap-1 text-xs font-headline tracking-wide">
          <span class="px-3 py-1 text-foreground/70 hover:text-primary cursor-pointer">Основное</span>
          <span class="px-3 py-1 text-foreground/70 hover:text-primary cursor-pointer">Приключения</span>
          <span class="px-3 py-1 text-foreground/70 hover:text-primary cursor-pointer">Экономика</span>
          <span class="px-3 py-1 text-foreground/70 hover:text-primary cursor-pointer">Система</span>
        </div>
        <div class="ml-auto flex items-center gap-3 text-xs">
          <span class="text-foreground/50 font-body">Realm: <span class="text-primary">Global</span></span>
          <.link href={~p"/users/log_out"} method="delete" class="text-foreground/50 hover:text-primary transition-colors">
            <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9" />
            </svg>
          </.link>
        </div>
      </nav>

      <!-- Main 3-column layout -->
      <div class="flex flex-1 overflow-hidden">

        <!-- LEFT SIDEBAR: Hero info -->
        <aside class="w-64 flex-shrink-0 bg-card border-r border-border overflow-y-auto">
          <div class="p-3 space-y-3">
            <!-- Avatar + name -->
            <div class="flex items-start gap-3">
              <div class="w-12 h-12 rounded-full bg-primary/20 border-2 border-primary/40 flex items-center justify-center flex-shrink-0">
                <span class="font-headline text-primary text-lg">
                  {String.first(@hero.name) |> String.upcase()}
                </span>
              </div>
              <div class="min-w-0">
                <div class="font-headline text-primary text-sm leading-tight truncate">{@hero.name}</div>
                <div class="text-foreground/60 text-xs mt-0.5">Уровень {@hero_state.level} · {@hero.race}</div>
                <div class="flex items-center gap-1 mt-1">
                  <svg class="w-3 h-3 text-foreground/40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" />
                  </svg>
                  <span class="text-xs text-foreground/60">{@hero_state.location}</span>
                </div>
                <div class="text-xs text-foreground/50 mt-0.5">Нейтральное</div>
              </div>
            </div>

            <!-- Status badge -->
            <div class="text-center">
              <span class={"text-xs font-body px-2 py-0.5 rounded #{status_class(@hero_state.status)}"}>
                {status_text(@hero_state.status)}
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
                  <span>{@hero_state.hp} / {@hero_state.max_hp}</span>
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
                  <span>{@max_mana} / {@max_mana}</span>
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
                  <span>{@max_stamina} / {@max_stamina}</span>
                </div>
                <div class="w-full h-2 bg-background/60 rounded-full overflow-hidden">
                  <div class="h-full bg-green-500" style="width: 100%"></div>
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
                  <div class="text-sm font-headline text-primary">{@hero_state.gold}</div>
                </div>
              </div>
              <div class="flex items-center gap-1.5">
                <svg class="w-3.5 h-3.5 text-foreground/40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 2L2 7v5c0 5.25 4.25 10.15 10 11.25" />
                  <path d="M12 22s7-4 7-10V7l-7-5" stroke-dasharray="4 2" />
                </svg>
                <div>
                  <div class="text-xs text-foreground/50">Смертей</div>
                  <div class="text-sm font-headline text-foreground/70">0</div>
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
                <%= for slot <- ["Оружие", "Голова", "Торс", "Поножи", "Руки", "Ботинки", "Амулет", "Кольцо"] do %>
                  <div class="flex justify-between items-center text-xs py-0.5">
                    <span class="text-foreground/60">{slot}</span>
                    <span class="text-foreground/30 italic">Пусто</span>
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
            <%= for entry <- @hero_state.log do %>
              <div class="flex gap-2 text-foreground/80 leading-relaxed">
                <span class="text-primary/60 font-headline text-xs flex-shrink-0 mt-0.5 w-12">
                  {format_game_time(@game_time)}
                </span>
                <span>{entry}</span>
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
              <span class="text-xs text-foreground/50 font-body">{@hero_state.xp} / {@hero_state.level * 100}</span>
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
                  {@game_time.day_name}, {@game_time.day}-й день {@game_time.month}, 4Э {@game_time.year}
                </span>
                <span class="text-xs font-headline text-primary">{format_game_time(@game_time)}</span>
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
              <div class="flex justify-between items-center">
                <span class="text-xs text-foreground/60 font-body">{format_real_date(@real_time)}</span>
                <span class="text-xs font-headline text-foreground/70">{format_real_time(@real_time)}</span>
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
                  <span class="text-primary">{@game_time.time_of_day}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-foreground/50 flex items-center gap-1">
                    <span>🌿</span> Время года
                  </span>
                  <span class="text-foreground/80">{@game_time.season}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-foreground/50 flex items-center gap-1">
                    <span>🌤</span> Погода
                  </span>
                  <span class="text-foreground/80">{@game_time.weather}</span>
                </div>
              </div>
              <div class="mt-3 pt-2 border-t border-border/30">
                <span class="text-xs text-foreground/40">Активные эффекты: нет</span>
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
                  <span>{@intervention_power} / 100</span>
                </div>
                <div class="w-full h-2 bg-background/60 rounded-full overflow-hidden">
                  <div class="h-full bg-primary transition-all duration-500" style={"width: #{@intervention_power}%"}></div>
                </div>
                <div class="text-xs text-foreground/40 mt-1">Восполнение: ~1 ед./мин</div>
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
                  disabled={@intervention_power < 50}
                  class="w-full px-3 py-1.5 text-xs font-headline bg-primary/80 hover:bg-primary text-background disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                >
                  Отправить
                </button>
              </.form>

              <!-- Last sent whisper preview -->
              <div :if={@last_whisper != ""} class="mt-2 p-2 bg-primary/10 border border-primary/20 text-xs text-foreground/70 font-body">
                <span class="text-primary">Последнее:</span> {@last_whisper}
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

        if connected?(socket) do
          Phoenix.PubSub.subscribe(GodvilleSk.PubSub, "hero:#{hero.id}")
          :timer.send_interval(@intervention_regen_interval, self(), :regen_intervention)
          :timer.send_interval(30_000, self(), :tick_clock)
        end

        now = DateTime.utc_now()

        {:ok,
         socket
         |> assign(:hero, hero)
         |> assign(:hero_state, hero_state)
         |> assign(:game_time, calculate_game_time(hero.inserted_at, now))
         |> assign(:real_time, now)
         |> assign(:intervention_power, 100)
         |> assign(:whisper, "")
         |> assign(:last_whisper, "")
         |> assign(:max_mana, calc_max_mana(hero_state))
         |> assign(:max_stamina, calc_max_stamina(hero_state))
         |> assign(:whisper_form, to_form(%{}, as: "whisper"))}
    end
  end

  def handle_info({:hero_update, hero_state}, socket) do
    {:noreply,
     socket
     |> assign(:hero_state, hero_state)
     |> assign(:max_mana, calc_max_mana(hero_state))
     |> assign(:max_stamina, calc_max_stamina(hero_state))}
  end

  def handle_info(:regen_intervention, socket) do
    new_power = min(100, socket.assigns.intervention_power + 1)
    {:noreply, assign(socket, :intervention_power, new_power)}
  end

  def handle_info(:tick_clock, socket) do
    now = DateTime.utc_now()
    {:noreply,
     socket
     |> assign(:real_time, now)
     |> assign(:game_time, calculate_game_time(socket.assigns.hero.inserted_at, now))}
  end

  def handle_event("send_whisper", %{"whisper" => %{"text" => text}}, socket) when byte_size(text) > 0 do
    if socket.assigns.intervention_power >= 50 do
      GodvilleSk.Hero.send_whisper(socket.assigns.hero.name, text)
      {:noreply,
       socket
       |> assign(:intervention_power, socket.assigns.intervention_power - 50)
       |> assign(:last_whisper, String.slice(text, 0, 200))}
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
      log: ["Добро пожаловать в Винтерхолд, искатель знаний! Ваш путь к мудрости начинается здесь. Мара направляет ваше обучение."]
    }
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
  defp status_text(_), do: "Бездействует"

  defp status_class(:idle), do: "bg-foreground/10 text-foreground/60"
  defp status_class(:combat), do: "bg-red-500/20 text-red-400"
  defp status_class(:resting), do: "bg-blue-500/20 text-blue-400"
  defp status_class(:questing), do: "bg-primary/20 text-primary"
  defp status_class(:leveling_up), do: "bg-yellow-500/20 text-yellow-400"
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

  defp calculate_game_time(inserted_at, now) do
    seconds_elapsed = DateTime.diff(now, inserted_at)

    # 1 real second = 2 game minutes
    game_minutes_elapsed = seconds_elapsed * 2
    game_hour = rem(div(game_minutes_elapsed, 60), 24)
    game_minute = rem(game_minutes_elapsed, 60)
    total_game_days = div(game_minutes_elapsed, 60 * 24)

    # Start: day 8, month 4 (Rain's Hand), year 202, era 4
    start_day_of_year = (4 - 1) * 28 + (8 - 1)
    total_from_start = start_day_of_year + total_game_days

    year_offset = div(total_from_start, 365)
    day_of_year = rem(total_from_start, 365)
    month_num = min(12, div(day_of_year, 28) + 1)
    day_num = rem(day_of_year, 28) + 1

    months = ["Утренняя Звезда", "Восход Солнца", "Первый Зерен", "Рука Дождей",
              "Второй Зерен", "Середина Лета", "Высь Солнца", "Последний Зерен",
              "Домашний Огонь", "Морозный Листопад", "Закат Солнца", "Вечерняя Звезда"]
    days_of_week = ["Мондас", "Тирдас", "Мидас", "Турдас", "Фредас", "Лорредас", "Сандас"]

    month_name = Enum.at(months, month_num - 1) || "Утренняя Звезда"
    day_name = Enum.at(days_of_week, rem(total_game_days, 7))

    season = cond do
      month_num in [3, 4, 5] -> "Весна"
      month_num in [6, 7, 8] -> "Лето"
      month_num in [9, 10, 11] -> "Осень"
      true -> "Зима"
    end

    time_of_day = cond do
      game_hour in 5..11 -> "Утро"
      game_hour in 12..17 -> "День"
      game_hour in 18..21 -> "Вечер"
      true -> "Ночь"
    end

    weather_pool = ["Ясно", "Облачно", "Туман", "Снегопад", "Гроза"]
    weather = Enum.at(weather_pool, rem(total_game_days * 7 + 3, length(weather_pool)))

    %{
      day_name: day_name,
      day: day_num,
      month: month_name,
      year: 202 + year_offset,
      hour: game_hour,
      minute: game_minute,
      season: season,
      time_of_day: time_of_day,
      weather: weather
    }
  end
end
