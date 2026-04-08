defmodule GodvilleSkWeb.DashboardLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game

  def mount(_params, _session, socket) do
    if socket.assigns.current_user do
      case Game.get_hero_by_user_id(socket.assigns.current_user.id) do
        nil ->
          {:ok, redirect(socket, to: "/hero/new")}
        hero ->
          if connected?(socket) do
            Phoenix.PubSub.subscribe(GodvilleSk.PubSub, "hero:#{hero.id}")
          end

          # Ensure GenServer is running
          case :global.whereis_name({:hero, hero.name}) do
            :undefined ->
              GodvilleSk.Hero.start_link(id: hero.id, name: hero.name)
            _pid ->
              :ok
          end

          logs = Game.list_hero_logs(hero.id, 10)

          {:ok, assign(socket, hero: hero, logs: logs, page_title: "Dashboard")}
      end
    else
      {:ok, redirect(socket, to: "/users/log_in")}
    end
  end

  def handle_info({:hero_update, state}, socket) do
    hero = socket.assigns.hero
    updated_hero = Map.merge(hero, %{
      hp: state.hp,
      max_hp: state.max_hp,
      gold: state.gold,
      level: state.level,
      exp: state.exp,
      status: to_string(state.status),
      attributes: %{
        "strength" => state.strength,
        "intelligence" => state.intelligence,
        "willpower" => state.willpower,
        "agility" => state.agility,
        "speed" => state.speed,
        "endurance" => state.endurance,
        "personality" => state.personality,
        "luck" => state.luck
      }
    })

    latest_msg = List.first(state.log)

    logs = socket.assigns.logs
    new_logs = if latest_msg do
      new_log = %GodvilleSk.Game.HeroLog{message: latest_msg, inserted_at: NaiveDateTime.utc_now()}
      [new_log | logs] |> Enum.take(10)
    else
      logs
    end

    {:noreply, assign(socket, hero: updated_hero, logs: new_logs)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row gap-6 p-4 max-w-7xl mx-auto h-[calc(100vh-6rem)]">
      <!-- Left Column: Character Stats -->
      <div class="w-full md:w-1/3 flex flex-col gap-4">
        <div class="bg-card text-card-foreground rounded-lg border shadow-sm p-6">
          <h2 class="text-2xl font-bold mb-4 flex justify-between items-center">
            <%= @hero.name %>
            <span class="text-sm font-normal text-muted-foreground">Lvl <%= @hero.level %></span>
          </h2>
          <div class="space-y-4">
            <div class="flex justify-between items-center pb-2 border-b">
              <span class="text-muted-foreground">Race</span>
              <span class="font-medium"><%= @hero.race %></span>
            </div>
            <div class="flex justify-between items-center pb-2 border-b">
              <span class="text-muted-foreground">Class</span>
              <span class="font-medium"><%= @hero.class %></span>
            </div>
            <div class="flex justify-between items-center pb-2 border-b">
              <span class="text-muted-foreground">Status</span>
              <span class="font-medium capitalize text-brand"><%= @hero.status %></span>
            </div>

            <div class="space-y-2 mt-4">
              <div class="flex justify-between text-sm">
                <span>HP</span>
                <span><%= @hero.hp %> / <%= @hero.max_hp %></span>
              </div>
              <div class="h-2 w-full bg-secondary rounded-full overflow-hidden">
                <div class="h-full bg-destructive transition-all duration-500" style={"width: #{max(0, min((@hero.hp / max(@hero.max_hp, 1)) * 100, 100))}%"}></div>
              </div>
            </div>

            <div class="space-y-2">
              <div class="flex justify-between text-sm">
                <span>EXP</span>
                <span><%= @hero.exp %> / <%= @hero.level * 100 %></span>
              </div>
              <div class="h-2 w-full bg-secondary rounded-full overflow-hidden">
                <div class="h-full bg-primary transition-all duration-500" style={"width: #{max(0, min((@hero.exp / max(@hero.level * 100, 1)) * 100, 100))}%"}></div>
              </div>
            </div>

            <div class="flex items-center gap-2 mt-4 pt-4 border-t">
              <div class="w-6 h-6 rounded-full bg-yellow-500 flex items-center justify-center text-xs font-bold text-yellow-900">G</div>
              <span class="font-bold text-lg"><%= @hero.gold %></span>
            </div>
          </div>
        </div>

        <div class="bg-card text-card-foreground rounded-lg border shadow-sm p-6 flex-grow">
          <h3 class="text-xl font-bold mb-4">Attributes</h3>
          <div class="grid grid-cols-2 gap-4 text-sm">
            <%= for {attr, label} <- [{"strength", "STR"}, {"agility", "AGI"}, {"endurance", "END"}, {"intelligence", "INT"}, {"willpower", "WIL"}, {"personality", "PER"}, {"speed", "SPD"}, {"luck", "LCK"}] do %>
              <div class="flex justify-between items-center p-2 rounded bg-secondary/50">
                <span class="text-muted-foreground"><%= label %></span>
                <span class="font-mono font-bold"><%= @hero.attributes[attr] || 50 %></span>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Right Column: Adventure Log -->
      <div class="w-full md:w-2/3 flex flex-col bg-card text-card-foreground rounded-lg border shadow-sm overflow-hidden">
        <div class="p-4 border-b bg-muted/20">
          <h2 class="text-xl font-bold flex items-center gap-2">

            Adventure Log
          </h2>
        </div>
        <div class="p-6 overflow-y-auto flex-grow flex flex-col-reverse gap-3 font-mono text-sm">
          <%= for log <- Enum.reverse(@logs) do %>
            <div class="p-3 rounded bg-secondary/30 border border-border/50 animate-in fade-in slide-in-from-bottom-2" id={"log-#{System.unique_integer()}"}>
              <div class="text-xs text-muted-foreground mb-1"><%= if Map.has_key?(log, :inserted_at) and log.inserted_at != nil, do: Calendar.strftime(log.inserted_at, "%H:%M:%S"), else: "Just now" %></div>
              <div><%= log.message %></div>
            </div>
          <% end %>
          <%= if Enum.empty?(@logs) do %>
            <div class="text-center text-muted-foreground italic p-4">Waiting for adventures to begin...</div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
