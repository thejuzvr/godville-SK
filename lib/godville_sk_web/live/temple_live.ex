defmodule GodvilleSkWeb.TempleLive do
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
      <.game_nav active_tab={:temple} />
      
      <main class="flex-1 overflow-y-auto p-6 max-w-5xl mx-auto w-full">
        <header class="mb-10 text-center relative py-8 overflow-hidden rounded-xl border border-primary/20 bg-gradient-to-b from-primary/10 to-transparent">
          <div class="absolute inset-0 opacity-5 pointer-events-none">
             <svg class="w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
                <path d="M0 100 L50 0 L100 100 Z" fill="currentColor" />
             </svg>
          </div>
          <h1 class="font-headline text-4xl text-primary uppercase tracking-[0.2em] mb-3">Храм Даэдра</h1>
          <p class="text-foreground/60 text-sm max-w-lg mx-auto leading-relaxed">
            Ваше величие измеряется камнями этого храма. Возведите монумент, достойный Принца, и последователи стекутся под вашу тень.
          </p>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
          
          <!-- Construction Progress -->
          <section class="lg:col-span-2 bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm">
            <h2 class="font-headline text-lg text-primary uppercase tracking-wider mb-6 flex items-center gap-2">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" /></svg>
              Статус строительства
            </h2>
            
            <div class="space-y-8">
              <div>
                <div class="flex justify-between items-end mb-3">
                  <span class="text-xs text-foreground/50 font-headline uppercase">Завершено</span>
                  <span class="text-3xl font-headline text-primary"><%= (Map.get(@hero_state, :temple) || %{})[:construction_progress] || 0 %>%</span>
                </div>
                <div class="w-full h-4 bg-background/60 rounded-full border border-border/30 p-0.5 overflow-hidden shadow-inner">
                  <div 
                    class="h-full bg-gradient-to-r from-primary/60 to-primary shadow-[0_0_15px_rgba(var(--primary-rgb),0.4)] transition-all duration-1000" 
                    style={"width: #{(Map.get(@hero_state, :temple) || %{})[:construction_progress] || 0}%"}
                  ></div>
                </div>
              </div>
              
              <div class="grid grid-cols-2 gap-4">
                <div class="p-4 bg-background/40 border border-border/20 rounded">
                  <span class="text-[10px] text-foreground/40 uppercase block mb-1">Материалы</span>
                  <span class="text-sm">Камень и эбонит</span>
                </div>
                <div class="p-4 bg-background/40 border border-border/20 rounded">
                  <span class="text-[10px] text-foreground/40 uppercase block mb-1">Рабочие</span>
                  <span class="text-sm">Отрекшиеся</span>
                </div>
              </div>
              
              <button class="w-full py-3 bg-primary/10 border border-primary/30 text-primary font-headline uppercase tracking-widest hover:bg-primary/20 transition-all disabled:opacity-50" disabled>
                Начать новый этап (Требуется 5000 септимов)
              </button>
            </div>
          </section>

          <!-- Active Benefits -->
          <section class="bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm">
            <h2 class="font-headline text-lg text-primary uppercase tracking-wider mb-6 flex items-center gap-2">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
              Влияние храма
            </h2>
            
            <div class="space-y-4">
              <%= if ((Map.get(@hero_state, :temple) || %{})[:construction_progress] || 0) > 0 do %>
                <div class="flex items-center gap-3 p-3 bg-emerald-500/5 border border-emerald-500/20 rounded group transition-all">
                  <div class="text-emerald-500"><svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path d="M5 13l4 4L19 7" /></svg></div>
                  <div>
                    <div class="text-xs font-bold text-emerald-400">Благословение фундамента</div>
                    <div class="text-[10px] text-foreground/40">+5% к получаемому золоту</div>
                  </div>
                </div>
              <% else %>
                <p class="text-xs text-foreground/30 italic text-center py-8">Храм еще не начал приносить пользу. Заложите первый камень.</p>
              <% end %>
              
              <div class="border border-dashed border-border/20 p-4 rounded text-center">
                 <span class="text-[10px] text-foreground/30 uppercase">Следующий эффект на 25%</span>
              </div>
            </div>
          </section>
        </div>

        <!-- Enemies of the Temple -->
        <section class="bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm">
           <div class="flex items-center justify-between mb-6">
              <h2 class="font-headline text-lg text-red-400 uppercase tracking-wider flex items-center gap-2">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
                Враги Храма
              </h2>
              <span class="text-[10px] text-red-500/50 uppercase tracking-widest">Усиление охраны: Низкое</span>
           </div>
           
           <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= for enemy <- (Map.get(@hero_state, :temple) || %{})[:enemies] || [] do %>
                <div class="flex items-center justify-between p-4 bg-red-500/5 border border-red-500/10 hover:border-red-500/30 transition-all rounded">
                   <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-full bg-red-500/20 flex items-center justify-center font-headline text-red-500 text-xs">!</div>
                      <span class="text-sm font-headline text-foreground/80"><%= enemy %></span>
                   </div>
                   <span class="text-xs text-red-400/60 uppercase">Угроза</span>
                </div>
              <% end %>
           </div>
        </section>
        
      </main>
    </div>
    """
  end
end
