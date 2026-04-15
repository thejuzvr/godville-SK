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

        # Convert embedded struct to map for template rendering
        hero_state = %{hero_state | equipment: Map.from_struct(hero_state.equipment)}

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
    # Convert embedded struct to map for template rendering
    hero_state = %{hero_state | equipment: Map.from_struct(hero_state.equipment)}
    {:noreply, assign(socket, :hero_state, hero_state)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-background text-foreground font-body overflow-hidden relative">
      <div class="absolute inset-0 bg-[url('/images/login-bg2.jpg')] bg-cover bg-center opacity-10 pointer-events-none">
      </div>

      <div class="relative z-10 border-b-2 border-border/80 bg-background/90 backdrop-blur-sm">
        <.game_nav active_tab={:equipment} />
      </div>

      <main class="flex-1 overflow-y-auto p-4 lg:p-8 max-w-6xl mx-auto w-full relative z-10">
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
          <!-- Character Equipment View -->
          <section class="lg:col-span-5 bg-background/80 border border-border/80 p-8 backdrop-blur-md relative transform">
            <div class="absolute top-0 right-0 w-4 h-4 border-t-2 border-r-2 border-primary/50"></div>
            <div class="absolute bottom-0 left-0 w-4 h-4 border-b-2 border-l-2 border-primary/50">
            </div>

            <h2 class="font-headline text-primary text-xl mb-12 uppercase tracking-[0.2em] flex items-center justify-center gap-3 border-b border-border/30 pb-4">
              <span class="w-2 h-2 bg-primary transform rotate-45"></span>
              Снаряжение <span class="w-2 h-2 bg-primary transform rotate-45"></span>
            </h2>

            <div class="relative w-full aspect-[3/4] max-w-[320px] mx-auto bg-primary/5 flex flex-col items-center justify-center border-y border-primary/10">
              <!-- Silhouette placeholder -->
              <svg
                class="absolute inset-0 w-full h-full opacity-[0.03] pointer-events-none"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" />
              </svg>
              <!-- Slots Grid around silhouette -->
              <div class="grid grid-cols-3 gap-10 lg:gap-14 z-10 mt-6">
                <!-- Left Column -->
                <div class="flex flex-col gap-10">
                  <.equipment_slot
                    slot={:head}
                    icon="M12 2L2 7l10 5 10-5-10-5z"
                    hero_state={@hero_state}
                  />
                  <.equipment_slot
                    slot={:amulet}
                    icon="M12 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4z"
                    hero_state={@hero_state}
                  />
                  <.equipment_slot
                    slot={:arms}
                    icon="M2 13h5l3 8 4-16 4 8h4"
                    hero_state={@hero_state}
                  />
                </div>
                <!-- Center Column -->
                <div class="flex flex-col gap-14 pt-12">
                  <.equipment_slot slot={:torso} icon="M12 1v22M5 12h14" hero_state={@hero_state} />
                  <.equipment_slot slot={:legs} icon="M9 1v22M15 1v22" hero_state={@hero_state} />
                </div>
                <!-- Right Column -->
                <div class="flex flex-col gap-10">
                  <.equipment_slot
                    slot={:weapon}
                    icon="M14.5 9.5l5 5m0-5l-5 5m-5-5l5 5m0-5l-5 5"
                    hero_state={@hero_state}
                  />
                  <.equipment_slot
                    slot={:ring}
                    icon="M12 22a10 10 0 100-20 10 10 0 000 20z"
                    hero_state={@hero_state}
                  />
                  <.equipment_slot slot={:boots} icon="M4 16v4h4m8-4v4h4" hero_state={@hero_state} />
                </div>
              </div>
            </div>
          </section>
          <!-- Inventory Grid -->
          <section class="lg:col-span-7 bg-background/80 border border-border/80 p-8 backdrop-blur-md relative">
            <div class="absolute top-0 left-0 w-4 h-4 border-t-2 border-l-2 border-primary/50"></div>
            <div class="absolute bottom-0 right-0 w-4 h-4 border-b-2 border-r-2 border-primary/50">
            </div>

            <div class="flex items-end justify-between border-b border-border/30 pb-4 mb-8">
              <h2 class="font-headline text-primary text-xl uppercase tracking-[0.2em] flex items-center gap-3">
                <span class="w-2 h-2 bg-primary transform rotate-45"></span> Сумка
              </h2>
              <div class="flex flex-col items-end gap-1 text-[10px] uppercase font-headline tracking-widest text-foreground/50">
                <span>
                  Ячейки: <span class="text-primary/80"><%= length(@hero_state.inventory) %></span>
                  / <%= @hero_state.inventory_capacity %>
                </span>
                <span class={
                  if @hero_state.overload_penalty < 0,
                    do: "text-red-400 border-b border-red-400 border-dashed",
                    else: ""
                }>
                  Бремя: <%= round(@hero_state.inventory_weight * 10) / 10 %>/50 кг <%= if @hero_state.overload_penalty <
                                                                                             0,
                                                                                           do:
                                                                                             "(-2 удачи)",
                                                                                           else: "" %>
                </span>
              </div>
            </div>

            <div class="h-80 overflow-y-auto mb-4 pr-3 custom-scrollbar">
              <div class="grid grid-cols-4 md:grid-cols-5 xl:grid-cols-6 gap-3">
                <%= for item_name <- @hero_state.inventory do %>
                  <div
                    phx-click="select_item"
                    phx-value-name={item_name}
                    class="aspect-square bg-background/50 border border-border/40 hover:border-primary/80 hover:bg-primary/10 transition-all cursor-pointer flex items-center justify-center p-2 group relative"
                  >
                    <!-- Corner marks -->
                    <div class="absolute top-1 left-1 w-1 h-1 bg-primary/20 pointer-events-none group-hover:bg-primary/50 transition-colors">
                    </div>
                    <div class="absolute bottom-1 right-1 w-1 h-1 bg-primary/20 pointer-events-none group-hover:bg-primary/50 transition-colors">
                    </div>

                    <div class="w-full h-full flex items-center justify-center text-primary group-hover:scale-105 transition-transform">
                      <span class="text-[9px] text-center font-headline uppercase tracking-wider leading-tight">
                        <%= String.slice(item_name, 0, 10) %><%= if String.length(item_name) > 10,
                          do: "..." %>
                      </span>
                    </div>
                  </div>
                <% end %>

                <%= for _ <- length(@hero_state.inventory)..(@hero_state.inventory_capacity - 1) do %>
                  <div class="aspect-square bg-background/20 border border-border/10 border-dashed flex items-center justify-center">
                    <div class="w-1 h-1 bg-border/20 rotate-45 transform"></div>
                  </div>
                <% end %>
              </div>
            </div>
          </section>
        </div>
      </main>
      <!-- Item Detail Modal -->
      <div
        :if={@selected_item}
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/90 backdrop-blur-sm"
      >
        <div class="bg-background border border-primary/50 w-full max-w-md overflow-hidden shadow-[0_0_50px_rgba(var(--primary-rgb),0.1)] relative">
          <!-- Frame corners -->
          <div class="absolute top-0 left-0 w-4 h-4 border-t border-l border-primary"></div>
          <div class="absolute top-0 right-0 w-4 h-4 border-t border-r border-primary"></div>
          <div class="absolute bottom-0 left-0 w-4 h-4 border-b border-l border-primary"></div>
          <div class="absolute bottom-0 right-0 w-4 h-4 border-b border-r border-primary"></div>

          <div class="p-8">
            <div class="flex justify-between items-start mb-6 border-b border-border/30 pb-4">
              <div>
                <h3 class="font-headline text-primary text-2xl tracking-widest uppercase mb-1">
                  <%= @selected_item.name %>
                </h3>
                <span class={"text-[9px] uppercase tracking-[0.2em] px-2 py-0.5 #{rarity_class(@selected_item.rarity)}"}>
                  <%= @selected_item.rarity %>
                </span>
              </div>
              <button
                phx-click="close_modal"
                class="text-foreground/40 hover:text-red-400 transition-colors bg-background border border-border/50 p-1"
              >
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div class="space-y-6">
              <div class="bg-foreground/5 border-l-2 border-primary/30 p-4">
                <p class="text-foreground/80 text-sm leading-relaxed italic font-body">
                  "<%= Map.get(@selected_item, :description, "Ничем не примечательный предмет.") %>"
                </p>
              </div>

              <div class="grid grid-cols-2 gap-4 py-4 border-y border-border/30">
                <div
                  :if={Map.has_key?(@selected_item, :damage)}
                  class="flex flex-col bg-background border border-red-900/40 p-2 text-center"
                >
                  <span class="text-[9px] text-red-500/50 uppercase tracking-widest font-headline mb-1">
                    Урон
                  </span>
                  <span class="text-2xl font-headline text-red-500">
                    <%= @selected_item.damage %>
                  </span>
                </div>
                <div
                  :if={Map.has_key?(@selected_item, :armor)}
                  class="flex flex-col bg-background border border-blue-900/40 p-2 text-center"
                >
                  <span class="text-[9px] text-blue-500/50 uppercase tracking-widest font-headline mb-1">
                    Броня
                  </span>
                  <span class="text-2xl font-headline text-blue-500">
                    <%= @selected_item.armor %>
                  </span>
                </div>
                <div class="flex flex-col bg-background border border-border/40 p-2 text-center col-span-full">
                  <span class="text-[9px] text-foreground/40 uppercase tracking-widest font-headline mb-1">
                    Тип Предмета
                  </span>
                  <span class="text-sm text-foreground/80 font-headline uppercase tracking-widest">
                    <%= @selected_item.type %>
                  </span>
                </div>
              </div>

              <div class="flex gap-4 pt-2">
                <%= if @selected_item.type in [:weapon, :armor] do %>
                  <button
                    phx-click="equip"
                    phx-value-name={@selected_item.name}
                    phx-value-slot={get_ideal_slot(@selected_item)}
                    class="flex-1 py-3 bg-primary/10 border border-primary text-primary font-headline text-sm uppercase tracking-widest hover:bg-primary/20 hover:shadow-[0_0_15px_rgba(var(--primary-rgb),0.3)] transition-all"
                  >
                    Экипировать
                  </button>
                <% end %>
                <button
                  phx-click="close_modal"
                  class="flex-1 py-3 border border-border/50 text-foreground/60 font-headline text-sm uppercase tracking-widest hover:text-foreground hover:bg-foreground/5 transition-all w-full"
                >
                  Вернуть в сумку
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
    item_name = Map.get(assigns.hero_state.equipment, assigns.slot)
    assigns = assign(assigns, :item_name, item_name)

    ~H"""
    <div
      class={[
        "w-16 h-16 border-[1.5px] flex items-center justify-center relative transition-all group",
        @item_name &&
          "border-primary/80 bg-primary/10 shadow-[inset_0_0_15px_rgba(var(--primary-rgb),0.1)]",
        !@item_name && "border-border/40 bg-background/60 border-dashed"
      ]}
      title={@item_name || "Свободный слот"}
    >
      <!-- Corner Accents -->
      <div class="absolute top-0 left-0 w-1.5 h-1.5 border-t border-l border-primary/40 pointer-events-none">
      </div>
      <div class="absolute bottom-0 right-0 w-1.5 h-1.5 border-b border-r border-primary/40 pointer-events-none">
      </div>

      <%= if @item_name do %>
        <div class="text-primary animate-in fade-in duration-500 w-full h-full flex items-center justify-center relative">
          <svg
            class="w-8 h-8 opacity-20 absolute"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path d={@icon} />
          </svg>
          <span class="text-[9px] font-headline tracking-widest text-center relative z-10 px-1 truncate w-14 leading-tight uppercase">
            <%= @item_name %>
          </span>
        </div>
        <button
          phx-click="unequip"
          phx-value-slot={@slot}
          class="absolute -top-2 -right-2 bg-red-900 border border-red-500 text-white w-5 h-5 text-[10px] opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center hover:bg-red-700"
        >
          ×
        </button>
      <% else %>
        <svg
          class="w-6 h-6 text-foreground/20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1"
        >
          <path d={@icon} />
        </svg>
      <% end %>
      <div class="absolute -bottom-6 left-1/2 -translate-x-1/2 text-[9px] text-foreground/40 font-headline uppercase whitespace-nowrap tracking-widest bg-background/80 px-1 border-x border-border/50">
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
  # Default
  defp get_ideal_slot(%{type: :armor}), do: "torso"
  defp get_ideal_slot(_), do: "weapon"
end
