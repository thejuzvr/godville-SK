defmodule GodvilleSkWeb.AnalyticsLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game
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
        {:ok, 
         socket
         |> assign(:hero, hero)
         |> assign(:hero_state, hero_state)}
    end
  end

  def handle_info({:hero_update, hero_state}, socket) do
    {:noreply, assign(socket, :hero_state, hero_state)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-background text-foreground font-body overflow-hidden">
      <.game_nav active_tab={:analytics} />
      
      <main class="flex-1 overflow-y-auto p-6 max-w-4xl mx-auto w-full">
        <header class="mb-8">
          <h1 class="font-headline text-3xl text-primary uppercase tracking-widest mb-2">Аналитика приключений</h1>
          <p class="text-foreground/50 text-sm italic">"Даже богам интересно, сколько дорог истоптал их смертный подопечный."</p>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          <.stat_card 
            label="Кражи" 
            value={Map.get(Map.get(@hero_state, :statistics) || %{}, :total_steals, 0)} 
            icon="M13 10V3L4 14h7v7l9-11h-7z" 
            color="text-yellow-500"
            description="Успешных посягательств на чужую собственность."
          />
          <.stat_card 
            label="Победы" 
            value={Map.get(Map.get(@hero_state, :statistics) || %{}, :total_wins, 0)} 
            icon="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" 
            color="text-emerald-500"
            description="Число поверженных врагов в честном (и не очень) бою."
          />
          <.stat_card 
            label="Квесты" 
            value={Map.get(Map.get(@hero_state, :statistics) || %{}, :total_quests, 0)} 
            icon="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" 
            color="text-blue-500"
            description="Выполненных поручений от обитателей Тамриэля."
          />
        </div>

        <section class="relative">
          <div class="flex items-center justify-between mb-6 border-b border-border/50 pb-2">
            <h2 class="font-headline text-xl text-foreground/80 uppercase tracking-wider">Достижения</h2>
            <span class="text-xs text-foreground/30 px-2 py-0.5 border border-border/40 rounded">Скоро</span>
          </div>
          
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 opacity-40 grayscale pointer-events-none">
            <%= for i <- 1..8 do %>
              <div class="aspect-square bg-card/20 border border-dashed border-border/40 flex flex-col items-center justify-center p-4 rounded-lg">
                <div class="w-10 h-10 border border-border/20 rounded-full mb-2 flex items-center justify-center">
                   <span class="text-xs font-headline">?</span>
                </div>
                <div class="h-2 w-12 bg-foreground/10 rounded mb-1"></div>
                <div class="h-1.5 w-8 bg-foreground/5 rounded"></div>
              </div>
            <% end %>
          </div>
          
          <div class="absolute inset-0 flex items-center justify-center z-10">
             <div class="bg-background/80 px-6 py-4 border border-primary/20 backdrop-blur-sm rounded shadow-xl transform -rotate-2">
                <p class="font-headline text-primary text-sm tracking-widest uppercase">Система достижений в разработке</p>
             </div>
          </div>
        </section>
        
        <footer class="mt-20 pt-8 border-t border-border/20 flex justify-between text-[10px] text-foreground/30 uppercase tracking-widest">
          <span>Last sync: <%= DateTime.utc_now() |> DateTime.to_iso8601() %></span>
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
        <svg class="w-24 h-24" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path d={@icon} /></svg>
      </div>
      <div class="flex items-center gap-3 mb-4">
        <div class={"p-2 rounded-md bg-background/50 border border-border/30 #{@color}"}>
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path d={@icon} /></svg>
        </div>
        <span class="text-xs font-headline text-foreground/50 uppercase tracking-wider"><%= @label %></span>
      </div>
      <div class="text-4xl font-headline text-foreground mb-2"><%= @value %></div>
      <p class="text-[10px] text-foreground/40 leading-relaxed"><%= @description %></p>
    </div>
    """
  end
end
