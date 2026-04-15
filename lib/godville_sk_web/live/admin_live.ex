defmodule GodvilleSkWeb.AdminLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game
  alias GodvilleSk.GameContent
  alias GodvilleSk.Hero
  alias GodvilleSk.TickProfile

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    tick_config = Application.get_env(:godville_sk, :tick_interval)
    current_env = Mix.env()
    current_tick = Keyword.get(tick_config, current_env, 2000)
    tick_dev = Keyword.get(tick_config, :dev, 2000)
    tick_prod = Keyword.get(tick_config, :prod, 10000)

    # Authorization Check
    if user.email != "admin@admin.ru" do
      {:ok,
       push_navigate(socket, to: "/dashboard")
       |> put_flash(:error, "Доступ запрещен. Только для Имперской Канцелярии.")}
    else
      hero = Game.get_hero_by_user_id(user.id)

      if hero do
        if connected?(socket) do
          Phoenix.PubSub.subscribe(GodvilleSk.PubSub, "hero:#{hero.id}")
        end

        hero_state = Game.get_hero_live_state(hero)
        tick_profile = Hero.get_tick_profile(hero.name)

        {:ok,
         socket
         |> assign(hero: hero)
         |> assign(hero_state: hero_state)
         |> assign(debug_item: "")
         |> assign(debug_location: "")
         |> assign(db_locations: GameContent.list_locations_admin())
         |> assign(log: ["Система инициализирована... Ожидание команд."])
         |> assign(tick_interval: current_tick)
         |> assign(tick_env: current_env)
         |> assign(tick_dev: tick_dev)
         |> assign(tick_prod: tick_prod)
         |> assign(tick_profile: tick_profile)
         |> assign(tick_profiles: TickProfile.profiles())}
      else
        {:ok, push_navigate(socket, to: "/hero/new")}
      end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#0a0a0a] text-[#00ff41] font-mono p-4 md:p-8 selection:bg-[#00ff41] selection:text-[#0a0a0a]">
      <!-- CRT Overlay -->
      <div class="fixed inset-0 pointer-events-none z-50 opacity-[0.03] bg-[linear-gradient(rgba(18,16,16,0)_50%,rgba(0,0,0,0.25)_50%),linear-gradient(90deg,rgba(255,0,0,0.06),rgba(0,255,0,0.02),rgba(0,0,255,0.06))] bg-[length:100%_2px,3px_100%]">
      </div>

      <div class="max-w-6xl mx-auto space-y-6 relative z-10">
        <!-- HEADER -->
        <header class="border-b-2 border-[#00ff41]/30 pb-4 flex justify-between items-end">
          <div>
            <h1 class="text-3xl font-black tracking-tighter uppercase italic">
              Imperial_Overseer_v1.0
            </h1>
            <p class="text-xs opacity-50">AUTHORIZED ACCESS ONLY // SECTOR: TAMRIEL-GLOBAL</p>
          </div>
          <div class="text-right">
            <div class="text-sm">STATUS: <span class="animate-pulse">ONLINE</span></div>
            <div class="text-[10px] opacity-40 uppercase"><%= @hero.name %>_UID_<%= @hero.id %></div>
          </div>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- LEFT: STATE MONITOR -->
          <div class="lg:col-span-1 space-y-6">
            <section class="border border-[#00ff41]/20 bg-[#0f0f0f] p-4 shadow-[0_0_20px_rgba(0,255,65,0.05)]">
              <h2 class="text-xs font-bold mb-4 border-b border-[#00ff41]/20 pb-1 uppercase tracking-widest">
                State_Monitor
              </h2>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="opacity-50">STATUS:</span>
                  <span class="font-bold underline"><%= @hero_state.status %></span>
                </div>
                <div class="flex justify-between">
                  <span class="opacity-50">LOCATION:</span>
                  <span><%= @hero_state.location %></span>
                </div>
                <div class="flex justify-between">
                  <span class="opacity-50">LEVEL:</span>
                  <span><%= @hero_state.level %></span>
                </div>
                <div class="flex justify-between">
                  <span class="opacity-50">XP:</span>
                  <span><%= @hero_state.xp %> / <%= @hero_state.level * 100 %></span>
                </div>
                <div class="border-t border-[#00ff41]/10 my-2"></div>
                <!-- Dynamic Progress Bars -->
                <div class="space-y-3 pt-2">
                  <.debug_bar
                    label="HEALTH"
                    val={@hero_state.hp}
                    max={@hero_state.max_hp}
                    color="bg-red-500"
                  />
                  <.debug_bar
                    label="STAMINA"
                    val={@hero_state.stamina}
                    max={@hero_state.stamina_max}
                    color="bg-green-500"
                  />
                  <.debug_bar
                    label="POWER"
                    val={@hero_state.intervention_power}
                    max={100}
                    color="bg-blue-500"
                  />
                  <.debug_bar label="GOLD" val={@hero_state.gold} max={10000} color="bg-yellow-500" />
                </div>
              </div>
            </section>

            <section class="border border-[#00ff41]/20 bg-[#0f0f0f] p-4">
              <h2 class="text-xs font-bold mb-4 border-b border-[#00ff41]/20 pb-1 uppercase tracking-widest">
                Active_Target
              </h2>
              <%= if @hero_state.target do %>
                <div class="text-sm space-y-1">
                  <div>
                    NAME: <span class="text-red-500 font-bold"><%= @hero_state.target.name %></span>
                  </div>
                  <div>HP: <%= @hero_state.target.hp || "N/A" %></div>
                  <button
                    phx-click="kill_target"
                    class="mt-2 w-full py-1 text-xs bg-red-900/30 border border-red-500/50 hover:bg-red-500 hover:text-black transition-all uppercase font-bold"
                  >
                    Insta_Kill
                  </button>
                </div>
              <% else %>
                <div class="text-xs opacity-30 italic">No_Target_Detected</div>
              <% end %>
            </section>
          </div>
          <!-- MIDDLE: COMMAND CENTER -->
          <div class="lg:col-span-2 space-y-6">
            <section class="border border-[#00ff41]/20 bg-[#0f0f0f] p-4">
              <h2 class="text-xs font-bold mb-6 border-b border-[#00ff41]/20 pb-1 uppercase tracking-widest">
                Inject_Parameters
              </h2>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <!-- Status Set -->
                <div class="space-y-4">
                  <div>
                    <label class="text-[10px] block mb-1 opacity-50 uppercase">
                      FORCED_STATUS_OVERRIDE
                    </label>
                    <div class="grid grid-cols-2 gap-2 text-[10px]">
                      <%= for status <- [:idle, :combat, :sovngarde, :resting, :trading, :questing] do %>
                        <button
                          phx-click="set_status"
                          phx-value-status={status}
                          class={"py-1 border border-[#00ff41]/40 hover:bg-[#00ff41] hover:text-black transition-all uppercase #{if @hero_state.status == status, do: "bg-[#00ff41] text-black"}"}
                        >
                          <%= status %>
                        </button>
                      <% end %>
                    </div>
                  </div>

                  <div class="pt-4">
                    <button
                      phx-click="force_tick"
                      class="w-full py-3 bg-[#00ff41]/10 border-2 border-[#00ff41] text-[#00ff41] hover:bg-[#00ff41] hover:text-black transition-all font-black uppercase text-lg flex items-center justify-center gap-2 group"
                    >
                      <span class="group-hover:animate-spin">⚙️</span> PULSE_ENGINE_(FORCE_TICK)
                    </button>
                  </div>
                </div>
                <!-- Numerical Inputs -->
                <div class="space-y-4">
                  <div class="space-y-3">
                    <.debug_input label="ADD_GOLD" type="number" event="add_gold" />
                    <.debug_input label="SET_HP" type="number" event="set_hp" />
                    <.debug_input label="SET_LEVEL" type="number" event="set_level" />
                    <.debug_input label="SET_POWER" type="number" event="set_power" />
                  </div>
                </div>
              </div>
            </section>
            <!-- GameTick Settings -->
            <section class="border border-[#00ff41]/20 bg-[#0f0f0f] p-4">
              <h2 class="text-xs font-bold mb-4 border-b border-[#00ff41]/20 pb-1 uppercase tracking-widest">
                GameTick_Settings
              </h2>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="space-y-2">
                  <div class="text-[10px] opacity-50 uppercase">CURRENT_ENV</div>
                  <div class="font-bold text-sm"><%= @tick_env %></div>
                </div>
                <div class="space-y-2">
                  <div class="text-[10px] opacity-50 uppercase">INTERVAL_MS</div>
                  <form phx-submit="set_tick_interval" class="flex gap-1">
                    <input
                      type="number"
                      name="value"
                      value={@tick_interval}
                      min="100"
                      max="60000"
                      step="100"
                      class="w-full bg-black border border-[#00ff41]/30 p-1 text-xs focus:outline-none focus:border-[#00ff41]"
                    />
                    <button
                      type="submit"
                      class="bg-[#00ff41]/10 border border-[#00ff41]/50 px-2 hover:bg-[#00ff41] hover:text-black transition-all text-xs uppercase"
                    >
                      Set
                    </button>
                  </form>
                </div>
              </div>
              <div class="mt-4 pt-3 border-t border-[#00ff41]/10">
                <div class="text-[10px] opacity-50 uppercase mb-2">TICK_PROFILE</div>
                <div class="flex gap-2">
                  <%= for profile <- @tick_profiles do %>
                    <button
                      phx-click="set_tick_profile"
                      phx-value-profile={profile}
                      class={"px-3 py-1.5 text-xs font-bold uppercase border transition-all #{if @tick_profile == profile, do: "bg-[#00ff41] text-black border-[#00ff41]", else: "bg-black border-[#00ff41]/30 hover:border-[#00ff41] hover:text-[#00ff41]"}"}
                    >
                      <%= profile %>
                    </button>
                  <% end %>
                </div>
              </div>
              <div class="mt-3 text-[10px] opacity-40">
                <span class="text-yellow-500">NOTE:</span>
                Профиль применяется без перезапуска. Prod: <%= @tick_prod %>ms, Dev: <%= @tick_dev %>ms
              </div>
            </section>
            <!-- Inventory Manager -->
            <section class="border border-[#00ff41]/20 bg-[#0f0f0f] p-4">
              <h2 class="text-xs font-bold mb-4 border-b border-[#00ff41]/20 pb-1 uppercase tracking-widest">
                Payload_Manifest (Inventory)
              </h2>
              <div class="flex gap-2 mb-4">
                <input
                  type="text"
                  phx-keyup="update_item_name"
                  value={@debug_item}
                  placeholder="ITEM_ID_OR_NAME..."
                  class="flex-1 bg-black border border-[#00ff41]/30 p-1 text-sm focus:outline-none focus:border-[#00ff41]"
                />
                <button
                  phx-click="add_item"
                  class="px-4 py-1 bg-[#00ff41]/20 border border-[#00ff41] text-xs font-bold uppercase hover:bg-[#00ff41] hover:text-black"
                >
                  Inject
                </button>
              </div>
              <div class="flex flex-wrap gap-2">
                <%= for item <- @hero_state.inventory do %>
                  <div class="group relative px-2 py-0.5 bg-black border border-[#00ff41]/20 text-[10px] flex items-center gap-2">
                    <span><%= item %></span>
                    <button
                      phx-click="remove_item"
                      phx-value-item={item}
                      class="text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      ×
                    </button>
                  </div>
                <% end %>
              </div>
            </section>
            <!-- Game Content: Locations -->
            <section class="border border-[#00ff41]/20 bg-[#0f0f0f] p-4">
              <h2 class="text-xs font-bold mb-4 border-b border-[#00ff41]/20 pb-1 uppercase tracking-widest">
                World_Content (DB Locations)
              </h2>
              <div class="flex gap-2 mb-3">
                <input
                  type="text"
                  phx-keyup="update_location_name"
                  value={@debug_location}
                  placeholder="NEW_LOCATION_NAME..."
                  class="flex-1 bg-black border border-[#00ff41]/30 p-1 text-sm focus:outline-none focus:border-[#00ff41]"
                />
                <button
                  phx-click="add_location"
                  class="px-4 py-1 bg-[#00ff41]/20 border border-[#00ff41] text-xs font-bold uppercase hover:bg-[#00ff41] hover:text-black"
                >
                  Add
                </button>
              </div>
              <div class="text-[10px] opacity-60 mb-2">
                DB_ENTRIES: <%= length(@db_locations) %> (при наличии используются вместо static fallback)
              </div>
              <div class="max-h-32 overflow-y-auto space-y-1">
                <%= for location <- @db_locations do %>
                  <div class="group flex items-center justify-between px-2 py-1 bg-black border border-[#00ff41]/20 text-[11px]">
                    <span><%= location.payload["name"] %></span>
                    <button
                      phx-click="delete_location"
                      phx-value-id={location.id}
                      class="text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      DELETE
                    </button>
                  </div>
                <% end %>
              </div>
            </section>
            <!-- Command Log -->
            <section class="border border-[#00ff41]/20 bg-[#0f0f0f] p-4 h-48 flex flex-col">
              <h2 class="text-xs font-bold mb-2 border-b border-[#00ff41]/20 pb-1 uppercase tracking-widest">
                Session_Logs
              </h2>
              <div id="admin-log" class="flex-1 overflow-y-auto text-[10px] opacity-70 space-y-1">
                <%= for msg <- Enum.reverse(@log) do %>
                  <div class="flex gap-2">
                    <span class="opacity-30">
                      [<%= NaiveDateTime.utc_now() |> to_string() |> String.slice(11..18) %>]
                    </span>
                    <span class={if String.contains?(msg, "ERROR"), do: "text-red-500", else: ""}>
                      > <%= msg %>
                    </span>
                  </div>
                <% end %>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def debug_bar(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between text-[10px] mb-1">
        <span><%= @label %></span>
        <span><%= @val %> / <%= @max %></span>
      </div>
      <div class="w-full h-1.5 bg-black border border-[#00ff41]/10">
        <div
          class={"h-full #{@color} shadow-[0_0_5px_rgba(var(--tw-shadow-color),0.5)]"}
          style={"width: #{min(100, (@val/@max)*100)}%"}
        >
        </div>
      </div>
    </div>
    """
  end

  def debug_input(assigns) do
    ~H"""
    <div>
      <label class="text-[10px] block mb-1 opacity-50 uppercase"><%= @label %></label>
      <form phx-submit={@event} class="flex gap-1">
        <input
          type={@type}
          name="value"
          class="w-full bg-black border border-[#00ff41]/30 p-1 text-xs focus:outline-none focus:border-[#00ff41]"
        />
        <button
          type="submit"
          class="bg-[#00ff41]/10 border border-[#00ff41]/50 px-2 hover:bg-[#00ff41] hover:text-black transition-all"
        >
          OK
        </button>
      </form>
    </div>
    """
  end

  # --- HANDLERS ---

  def handle_info({:hero_update, state}, socket) do
    {:noreply, assign(socket, hero_state: state)}
  end

  def handle_info({:hero_updated, state}, socket) do
    {:noreply, assign(socket, hero_state: state)}
  end

  def handle_event("force_tick", _, socket) do
    Hero.debug_force_tick(socket.assigns.hero.name)
    {:noreply, add_log(socket, "TRIGGER: Immediate game tick forced.")}
  end

  def handle_event("set_status", %{"status" => status}, socket) do
    status_atom = String.to_existing_atom(status)

    updates =
      if status_atom == :sovngarde do
        %{
          status: :sovngarde,
          respawn_at: DateTime.add(DateTime.utc_now(), 15, :minute),
          location: "Совнгард",
          hp: 0
        }
      else
        %{status: status_atom, respawn_at: nil}
      end

    Hero.debug_update(socket.assigns.hero.name, updates)
    {:noreply, add_log(socket, "OVERRIDE: Status set to #{status_atom}.")}
  end

  def handle_event("add_gold", %{"value" => val}, socket) do
    amount = String.to_integer(val)
    new_gold = socket.assigns.hero_state.gold + amount
    Hero.debug_update(socket.assigns.hero.name, %{gold: max(0, new_gold)})
    {:noreply, add_log(socket, "MODIFY: Gold adjusted by #{amount}. Total: #{new_gold}.")}
  end

  def handle_event("set_hp", %{"value" => val}, socket) do
    hp = String.to_integer(val)
    Hero.debug_update(socket.assigns.hero.name, %{hp: hp})
    {:noreply, add_log(socket, "MODIFY: HP set to #{hp}.")}
  end

  def handle_event("set_level", %{"value" => val}, socket) do
    lvl = String.to_integer(val)
    Hero.debug_update(socket.assigns.hero.name, %{level: lvl})
    {:noreply, add_log(socket, "MODIFY: Level set to #{lvl}.")}
  end

  def handle_event("set_power", %{"value" => val}, socket) do
    power = String.to_integer(val)
    Hero.debug_update(socket.assigns.hero.name, %{intervention_power: power})
    {:noreply, add_log(socket, "MODIFY: Intervention Power set to #{power}.")}
  end

  def handle_event("update_item_name", %{"value" => val}, socket) do
    {:noreply, assign(socket, debug_item: val)}
  end

  def handle_event("add_item", _, socket) do
    item = socket.assigns.debug_item

    if item != "" do
      Hero.debug_add_inventory(socket.assigns.hero.name, item)

      {:noreply,
       socket |> assign(debug_item: "") |> add_log("INJECT: Item #{item} added to manifest.")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_item", %{"item" => item}, socket) do
    Hero.debug_remove_inventory(socket.assigns.hero.name, item)
    {:noreply, add_log(socket, "EJECT: Item #{item} removed from manifest.")}
  end

  def handle_event("update_location_name", %{"value" => val}, socket) do
    {:noreply, assign(socket, debug_location: val)}
  end

  def handle_event("add_location", _, socket) do
    case GameContent.create_location(socket.assigns.debug_location) do
      {:ok, _entry} ->
        {:noreply,
         socket
         |> assign(debug_location: "")
         |> refresh_locations()
         |> add_log("WORLD: New DB location added.")}

      {:error, _changeset} ->
        {:noreply,
         add_log(socket, "ERROR: Failed to add location (check duplicate/empty value).")}
    end
  end

  def handle_event("delete_location", %{"id" => id}, socket) do
    with {int_id, ""} <- Integer.parse(id),
         {:ok, _entry} <- GameContent.delete_location(int_id) do
      {:noreply, socket |> refresh_locations() |> add_log("WORLD: DB location removed.")}
    else
      _ -> {:noreply, add_log(socket, "ERROR: Failed to delete DB location.")}
    end
  end

  def handle_event("kill_target", _, socket) do
    if socket.assigns.hero_state.target do
      Hero.debug_update(socket.assigns.hero.name, %{
        target: Map.put(socket.assigns.hero_state.target, :hp, 0)
      })

      {:noreply, add_log(socket, "EXEC: Target neutralized (HP=0).")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("set_tick_interval", %{"value" => val}, socket) do
    interval = String.to_integer(val)
    env = socket.assigns.tick_env

    tick_config = Application.get_env(:godville_sk, :tick_interval)
    new_config = Keyword.put(tick_config, env, interval)
    Application.put_env(:godville_sk, :tick_interval, new_config)

    {:noreply,
     socket
     |> assign(tick_interval: interval)
     |> add_log("CONFIG: Tick interval set to #{interval}ms (#{env} env).")}
  end

  def handle_event("set_tick_profile", %{"profile" => profile}, socket) do
    profile_atom = String.to_existing_atom(profile)
    Hero.set_tick_profile(socket.assigns.hero.name, profile_atom)

    {:noreply,
     socket
     |> assign(tick_profile: profile_atom)
     |> add_log("PROFILE: Tick profile set to #{profile}.")}
  end

  defp add_log(socket, msg) do
    assign(socket, log: [msg | Enum.take(socket.assigns.log, 19)])
  end

  defp refresh_locations(socket) do
    assign(socket, db_locations: GameContent.list_locations_admin())
  end
end
