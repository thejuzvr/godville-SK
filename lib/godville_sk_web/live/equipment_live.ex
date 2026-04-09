defmodule GodvilleSkWeb.EquipmentLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game
  alias GodvilleSk.GameData
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
         |> assign(:hero_state, hero_state)
         |> assign(:selected_item, nil)}
    end
  end

  def handle_event("select_item", %{"name" => name}, socket) do
    item = GameData.get_item_by_name(name)
    {:noreply, assign(socket, :selected_item, item)}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, :selected_item, nil)}
  end

  def handle_event("equip", %{"name" => name, "slot" => slot}, socket) do
    GodvilleSk.Hero.equip(socket.assigns.hero.name, name, String.to_atom(slot))
    {:noreply, assign(socket, :selected_item, nil)}
  end

  def handle_event("unequip", %{"slot" => slot}, socket) do
    GodvilleSk.Hero.unequip(socket.assigns.hero.name, String.to_atom(slot))
    {:noreply, assign(socket, :selected_item, nil)}
  end

  def handle_info({:hero_update, hero_state}, socket) do
    {:noreply, assign(socket, :hero_state, hero_state)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-background text-foreground font-body overflow-hidden">
      <.game_nav active_tab={:equipment} />
      
      <main class="flex-1 overflow-y-auto p-6 max-w-5xl mx-auto w-full">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          
          <!-- Character Equipment View -->
          <section class="bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm">
            <h2 class="font-headline text-primary text-xl mb-6 uppercase tracking-wider flex items-center gap-2">
              <svg class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M12 2L2 7v5c0 5.25 4.25 10.15 10 11.25C17.75 22.15 22 17.25 22 12V7L12 2z" />
              </svg>
              Снаряжение
            </h2>
            
            <div class="relative w-full aspect-[3/4] max-w-[320px] mx-auto bg-gradient-to-b from-primary/5 to-transparent rounded-full flex flex-col items-center justify-center border border-primary/10">
              <!-- Silhouette placeholder -->
              <svg class="absolute inset-0 w-full h-full opacity-5 pointer-events-none" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" />
              </svg>
              
              <!-- Slots Grid around silhouette -->
              <div class="grid grid-cols-3 gap-12 z-10">
                <div class="flex flex-col gap-6">
                  <.equipment_slot slot={:head} icon="M12 2L2 7l10 5 10-5-10-5z" hero_state={@hero_state} />
                  <.equipment_slot slot={:amulet} icon="M12 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4z" hero_state={@hero_state} />
                  <.equipment_slot slot={:arms} icon="M2 13h5l3 8 4-16 4 8h4" hero_state={@hero_state} />
                </div>
                
                <div class="flex flex-col gap-12 pt-8">
                  <.equipment_slot slot={:torso} icon="M12 1v22M5 12h14" hero_state={@hero_state} />
                  <.equipment_slot slot={:legs} icon="M9 1v22M15 1v22" hero_state={@hero_state} />
                </div>
                
                <div class="flex flex-col gap-6">
                  <.equipment_slot slot={:weapon} icon="M14.5 9.5l5 5m0-5l-5 5m-5-5l5 5m0-5l-5 5" hero_state={@hero_state} />
                  <.equipment_slot slot={:ring} icon="M12 22a10 10 0 100-20 10 10 0 000 20z" hero_state={@hero_state} />
                  <.equipment_slot slot={:boots} icon="M4 16v4h4m8-4v4h4" hero_state={@hero_state} />
                </div>
              </div>
            </div>
          </section>

          <!-- Inventory Grid -->
          <section class="bg-card/30 border border-border/50 p-6 rounded-lg backdrop-blur-sm">
            <div class="flex items-center justify-between mb-6">
              <h2 class="font-headline text-primary text-xl uppercase tracking-wider flex items-center gap-2">
                <svg class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 8V20C21 21.1 20.1 22 19 22H5C3.9 22 3 21.1 3 20V8M1 3H23M10 12H14" />
                </svg>
                Инвентарь
              </h2>
              <span class="text-xs text-foreground/50"><%= length(@hero_state.inventory) %> / <%= @hero_state.inventory_capacity %></span>
            </div>
            
            <div class="grid grid-cols-5 gap-3">
              <%= for item_name <- @hero_state.inventory do %>
                <div 
                  phx-click="select_item" 
                  phx-value-name={item_name}
                  class="aspect-square bg-background/50 border border-border/40 hover:border-primary/60 hover:bg-primary/5 transition-all cursor-pointer flex items-center justify-center p-2 rounded shadow-inner group relative"
                >
                  <div class="w-full h-full bg-primary/10 rounded-sm flex items-center justify-center text-primary group-hover:scale-110 transition-transform">
                    <span class="text-[10px] text-center leading-tight"><%= String.slice(item_name, 0, 8) %>...</span>
                  </div>
                </div>
              <% end %>
              
              <%= for _ <- length(@hero_state.inventory)..(@hero_state.inventory_capacity - 1) do %>
                <div class="aspect-square bg-background/20 border border-border/10 rounded flex items-center justify-center">
                  <div class="w-1 h-1 bg-foreground/5 rounded-full"></div>
                </div>
              <% end %>
            </div>
          </section>
        </div>
      </main>

      <!-- Item Detail Modal -->
      <div :if={@selected_item} class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-md">
        <div class="bg-card border border-primary/30 w-full max-w-sm overflow-hidden rounded-lg shadow-2xl animate-in fade-in zoom-in duration-200">
          <div class="p-1 bg-gradient-to-r from-primary/40 via-primary/20 to-primary/40 h-1"></div>
          <div class="p-6">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h3 class="font-headline text-primary text-2xl truncate"><%= @selected_item.name %></h3>
                <span class={"text-[10px] uppercase tracking-widest px-1.5 py-0.5 rounded #{rarity_class(@selected_item.rarity)}"}>
                  <%= @selected_item.rarity %>
                </span>
              </div>
              <button phx-click="close_modal" class="text-foreground/40 hover:text-primary transition-colors">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
              </button>
            </div>
            
            <div class="space-y-4">
              <p class="text-foreground/70 text-sm leading-relaxed italic font-body">
                "<%= Map.get(@selected_item, :description, "Ничем не примечательный предмет.") %>"
              </p>
              
              <div class="grid grid-cols-2 gap-4 py-3 border-y border-border/30">
                <div :if={Map.has_key?(@selected_item, :damage)} class="flex flex-col">
                  <span class="text-[10px] text-foreground/40 uppercase">Урон</span>
                  <span class="text-xl font-headline text-red-400"><%= @selected_item.damage %></span>
                </div>
                <div :if={Map.has_key?(@selected_item, :armor)} class="flex flex-col">
                  <span class="text-[10px] text-foreground/40 uppercase">Броня</span>
                  <span class="text-xl font-headline text-blue-400"><%= @selected_item.armor %></span>
                </div>
                <div class="flex flex-col">
                  <span class="text-[10px] text-foreground/40 uppercase">Тип</span>
                  <span class="text-sm text-foreground/80"><%= @selected_item.type %></span>
                </div>
              </div>
              
              <div class="flex gap-3 pt-2">
                <%= if @selected_item.type in [:weapon, :armor] do %>
                  <button 
                    phx-click="equip" 
                    phx-value-name={@selected_item.name} 
                    phx-value-slot={get_ideal_slot(@selected_item)}
                    class="flex-1 py-2 bg-primary text-background font-headline text-sm hover:brightness-110 active:scale-95 transition-all"
                  >
                    Экипировать
                  </button>
                <% end %>
                <button phx-click="close_modal" class="flex-1 py-2 border border-border/50 text-foreground/70 hover:bg-foreground/5 font-headline text-sm transition-all">
                  Закрыть
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def equipment_slot(assigns) do
    item_name = (Map.get(assigns.hero_state, :equipment) || %{})[assigns.slot]
    assigns = assign(assigns, :item_name, item_name)
    ~H"""
    <div 
      class={[
        "w-14 h-14 rounded border flex items-center justify-center relative transition-all group",
        @item_name && "border-primary/60 bg-primary/10 shadow-[0_0_10px_rgba(var(--primary-rgb),0.2)]",
        !@item_name && "border-border/20 bg-background/40"
      ]}
      title={@item_name || "Свободный слот"}
    >
      <%= if @item_name do %>
        <div class="text-primary animate-in fade-in duration-500">
           <svg class="w-8 h-8 opacity-40 absolute" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1"><path d={@icon} /></svg>
           <span class="text-[8px] font-bold text-center relative z-10 px-1 truncate w-12"><%= @item_name %></span>
        </div>
        <button 
          phx-click="unequip" 
          phx-value-slot={@slot}
          class="absolute -top-1 -right-1 bg-red-500 text-white w-4 h-4 rounded-full text-[8px] opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
        >
          ×
        </button>
      <% else %>
        <svg class="w-6 h-6 text-foreground/10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d={@icon} />
        </svg>
      <% end %>
      <div class="absolute -bottom-5 left-1/2 -translate-x-1/2 text-[10px] text-foreground/30 font-headline uppercase whitespace-nowrap">
        <%= slot_name(@slot) %>
      </div>
    </div>
    """
  end

  defp rarity_class(:rare), do: "bg-purple-500/20 text-purple-400 border border-purple-500/30"
  defp rarity_class(:uncommon), do: "bg-blue-500/20 text-blue-400 border border-blue-500/30"
  defp rarity_class(_), do: "bg-foreground/10 text-foreground/50 border border-border/20"

  defp slot_name(:weapon), do: "Оружие"
  defp slot_name(:head), do: "Голова"
  defp slot_name(:torso), do: "Торс"
  defp slot_name(:legs), do: "Поножи"
  defp slot_name(:arms), do: "Руки"
  defp slot_name(:boots), do: "Ботинки"
  defp slot_name(:ring), do: "Кольцо"
  defp slot_name(:amulet), do: "Амулет"

  defp get_ideal_slot(%{type: :weapon}), do: "weapon"
  defp get_ideal_slot(%{type: :armor, slot: slot}), do: to_string(slot)
  defp get_ideal_slot(%{type: :armor}), do: "torso" # Default
  defp get_ideal_slot(_), do: "weapon"
end
