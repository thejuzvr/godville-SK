defmodule GodvilleSkWeb.MarketplaceLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game
  alias GodvilleSk.Marketplace
  import GodvilleSkWeb.NavComponents

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    case Game.get_hero_by_user_id(user.id) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/hero/new")}

      hero ->
        trades = Marketplace.search_trades(%{})
        my_trades = Marketplace.get_seller_trades(user.id)

        {:ok,
         socket
         |> assign(:hero, hero)
         |> assign(:trades, trades)
         |> assign(:my_trades, my_trades)
         |> assign(:current_user_id, user.id)
         |> assign(:show_list_form, false)
         |> assign(:list_type, :item)
         |> assign(:list_item_name, "")
         |> assign(:list_price, "")}
    end
  end

  # --- Выставление лота ---

  def handle_event("toggle_list_form", _params, socket) do
    {:noreply, assign(socket, :show_list_form, !socket.assigns.show_list_form)}
  end

  def handle_event("set_list_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :list_type, String.to_existing_atom(type))}
  end

  def handle_event("update_list_form", params, socket) do
    socket =
      socket
      |> assign(:list_item_name, Map.get(params, "item_name", socket.assigns.list_item_name))
      |> assign(:list_price, Map.get(params, "price", socket.assigns.list_price))

    {:noreply, socket}
  end

  def handle_event("submit_listing", %{"price" => price_str, "item_name" => item_name}, socket) do
    user = socket.assigns.current_user
    hero = socket.assigns.hero

    with {price, ""} <- Integer.parse(price_str),
         true <- price > 0 do
      result =
        case socket.assigns.list_type do
          :item ->
            if String.trim(item_name) == "" do
              {:error, :item_name_empty}
            else
              Marketplace.create_item_trade(user.id, String.trim(item_name), price)
            end

          :soul ->
            Marketplace.create_soul_trade(user.id, hero.id, price)
        end

      case result do
        {:ok, _trade} ->
          trades = Marketplace.search_trades(%{})
          my_trades = Marketplace.get_seller_trades(user.id)

          {:noreply,
           socket
           |> put_flash(:info, "Лот выставлен на рынок!")
           |> assign(:trades, trades)
           |> assign(:my_trades, my_trades)
           |> assign(:show_list_form, false)
           |> assign(:list_item_name, "")
           |> assign(:list_price, "")}

        {:error, :item_name_empty} ->
          {:noreply, put_flash(socket, :error, "Укажите название предмета.")}

        {:error, :character_in_combat} ->
          {:noreply, put_flash(socket, :error, "Герой в бою — продать душу не выйдет.")}

        {:error, :character_in_arena} ->
          {:noreply, put_flash(socket, :error, "Герой на арене — продать душу не выйдет.")}

        {:error, :not_owner} ->
          {:noreply, put_flash(socket, :error, "Это не ваш герой.")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Ошибка при создании лота.")}
      end
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Укажите корректную цену (целое число > 0).")}
    end
  end

  # --- Покупка ---

  def handle_event("buy_trade", %{"id" => trade_id}, socket) do
    user = socket.assigns.current_user

    case Marketplace.complete_trade(String.to_integer(trade_id), user.id) do
      {:ok, _} ->
        trades = Marketplace.search_trades(%{})
        my_trades = Marketplace.get_seller_trades(user.id)
        hero = Game.get_hero_by_user_id(user.id)

        {:noreply,
         socket
         |> put_flash(:info, "Сделка успешно совершена!")
         |> assign(:trades, trades)
         |> assign(:my_trades, my_trades)
         |> assign(:hero, hero || socket.assigns.hero)}

      {:error, reason} ->
        msg =
          case reason do
            :insufficient_gold -> "Недостаточно золота для совершения сделки."
            :cannot_buy_own -> "Нельзя купить собственный лот."
            :trade_not_active -> "Сделка уже не активна."
            _ -> "Ошибка при покупке."
          end

        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  # --- Отмена лота ---

  def handle_event("cancel_trade", %{"id" => trade_id}, socket) do
    user = socket.assigns.current_user

    case Marketplace.cancel_trade(String.to_integer(trade_id), user.id) do
      {:ok, _} ->
        trades = Marketplace.search_trades(%{})
        my_trades = Marketplace.get_seller_trades(user.id)

        {:noreply,
         socket
         |> put_flash(:info, "Лот снят с продажи.")
         |> assign(:trades, trades)
         |> assign(:my_trades, my_trades)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Не удалось снять лот.")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-background text-foreground font-body overflow-hidden relative selection:bg-yellow-900/50 selection:text-yellow-100">
      <div class="absolute inset-0 bg-[url('/images/login-bg2.jpg')] bg-cover bg-center opacity-5 pointer-events-none mix-blend-overlay"></div>

      <div class="relative z-10 border-b-2 border-yellow-900/50 bg-background/90 backdrop-blur-md">
        <.game_nav active_tab={:marketplace} />
      </div>

      <main class="flex-1 overflow-y-auto p-4 lg:p-8 max-w-7xl mx-auto w-full relative z-10 custom-scrollbar">
        <header class="mb-12 text-center relative py-12 border-y-[1px] border-yellow-900/30 bg-gradient-to-b from-yellow-900/10 to-transparent overflow-hidden">
          <div class="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-1 bg-yellow-600/50"></div>
          <div class="absolute inset-0 opacity-[0.05] pointer-events-none bg-[url('/images/noise.png')] mix-blend-overlay"></div>

          <h1 class="font-headline text-5xl text-yellow-500 uppercase tracking-[0.4em] mb-4 drop-shadow-[0_0_15px_rgba(202,138,4,0.5)]">
            Чёрный Рынок
          </h1>
          <p class="text-yellow-400/50 text-[11px] uppercase tracking-[0.2em] max-w-xl mx-auto leading-relaxed font-body border-l border-r border-yellow-900/30 px-4">
            Всё имеет цену, даже душа. Золото не пахнет кровью, пока оно лежит в вашем кошельке.
          </p>
        </header>

        <%# Toolbar: казна + кнопка выставить %>
        <div class="flex justify-between items-center mb-6 border-b border-border/30 pb-4">
          <h2 class="font-headline text-xl text-yellow-500 uppercase tracking-[0.2em] flex items-center gap-3">
            <span class="w-1.5 h-1.5 bg-yellow-500 transform rotate-45"></span>
            Доступные контракты
          </h2>
          <div class="flex items-center gap-6">
            <span class="text-[11px] uppercase font-headline tracking-widest text-foreground/50">
              Казна: <span class="text-yellow-500"><%= @hero.gold %> з.</span>
            </span>
            <button
              phx-click="toggle_list_form"
              id="toggle-list-form-btn"
              class="px-4 py-2 border border-yellow-700/60 bg-yellow-900/20 text-[10px] font-headline uppercase tracking-widest text-yellow-400 hover:bg-yellow-900/40 hover:border-yellow-500 transition-all"
            >
              <%= if @show_list_form, do: "✕ Отмена", else: "+ Выставить лот" %>
            </button>
          </div>
        </div>

        <%# Форма выставления лота %>
        <%= if @show_list_form do %>
          <div id="listing-form" class="mb-8 p-6 border border-yellow-800/50 bg-yellow-900/10 backdrop-blur-sm relative">
            <div class="absolute top-0 left-0 w-3 h-3 border-t-2 border-l-2 border-yellow-600/50"></div>
            <div class="absolute bottom-0 right-0 w-3 h-3 border-b-2 border-r-2 border-yellow-600/50"></div>

            <h3 class="font-headline text-lg text-yellow-400 uppercase tracking-[0.2em] mb-6">
              Новый контракт
            </h3>

            <%# Тип лота %>
            <div class="flex gap-3 mb-6">
              <button
                phx-click="set_list_type"
                phx-value-type="item"
                id="list-type-item-btn"
                class={"px-4 py-2 text-[10px] font-headline uppercase tracking-widest border transition-all " <>
                  if @list_type == :item,
                    do: "border-yellow-500 bg-yellow-900/40 text-yellow-300",
                    else: "border-border/30 bg-background/50 text-foreground/40 hover:border-yellow-700/50"}
              >
                Предмет
              </button>
              <button
                phx-click="set_list_type"
                phx-value-type="soul"
                id="list-type-soul-btn"
                class={"px-4 py-2 text-[10px] font-headline uppercase tracking-widest border transition-all " <>
                  if @list_type == :soul,
                    do: "border-yellow-500 bg-yellow-900/40 text-yellow-300",
                    else: "border-border/30 bg-background/50 text-foreground/40 hover:border-yellow-700/50"}
              >
                Душа Героя
              </button>
            </div>

            <form phx-submit="submit_listing" phx-change="update_list_form" id="listing-form-fields">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <%= if @list_type == :item do %>
                  <div>
                    <label class="block text-[9px] uppercase tracking-widest text-foreground/50 font-headline mb-2">
                      Название предмета
                    </label>
                    <input
                      type="text"
                      name="item_name"
                      id="list-item-name-input"
                      value={@list_item_name}
                      placeholder="напр. Железный меч"
                      class="w-full bg-background border border-border/50 focus:border-yellow-600/70 text-foreground text-sm px-3 py-2 outline-none font-body placeholder:text-foreground/20 transition-colors"
                    />
                  </div>
                <% else %>
                  <div class="p-3 border border-yellow-900/30 bg-yellow-900/10">
                    <p class="text-[10px] text-yellow-400/70 font-headline uppercase tracking-widest mb-1">Выставляемый герой</p>
                    <p class="text-sm text-foreground font-body"><%= @hero.name %> (Ур. <%= @hero.level %>)</p>
                    <input type="hidden" name="item_name" value="" />
                  </div>
                <% end %>

                <div>
                  <label class="block text-[9px] uppercase tracking-widest text-foreground/50 font-headline mb-2">
                    Цена (золото)
                  </label>
                  <input
                    type="number"
                    name="price"
                    id="list-price-input"
                    value={@list_price}
                    min="1"
                    placeholder="0"
                    class="w-full bg-background border border-border/50 focus:border-yellow-600/70 text-foreground text-sm px-3 py-2 outline-none font-body placeholder:text-foreground/20 transition-colors"
                  />
                </div>
              </div>

              <button
                type="submit"
                id="submit-listing-btn"
                class="w-full md:w-auto px-8 py-3 border border-yellow-700/60 bg-yellow-900/30 text-[11px] font-headline uppercase tracking-widest text-yellow-400 hover:bg-yellow-900/50 hover:border-yellow-500 transition-all"
              >
                Выставить на торги
              </button>
            </form>
          </div>
        <% end %>

        <%# Мои лоты %>
        <%= if not Enum.empty?(@my_trades |> Enum.filter(& &1.status == :active)) do %>
          <div class="mb-8">
            <h3 class="font-headline text-sm text-foreground/50 uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
              <span class="w-1 h-1 bg-yellow-600 transform rotate-45"></span>
              Мои активные лоты
            </h3>
            <div class="flex flex-wrap gap-3">
              <%= for trade <- @my_trades |> Enum.filter(& &1.status == :active) do %>
                <div class="flex items-center gap-3 px-4 py-2 border border-yellow-900/40 bg-yellow-900/10 text-[10px] font-headline uppercase tracking-wider">
                  <span class="text-foreground/70">
                    <%= if trade.type == :soul, do: "ДУША", else: trade.item_name || "ПРЕДМЕТ" %>
                  </span>
                  <span class="text-yellow-500"><%= trade.price %> з.</span>
                  <button
                    phx-click="cancel_trade"
                    phx-value-id={trade.id}
                    id={"cancel-trade-#{trade.id}"}
                    class="text-red-500/60 hover:text-red-400 transition-colors ml-1"
                  >
                    ✕
                  </button>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <%# Список лотов %>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= if Enum.empty?(@trades) do %>
            <div class="col-span-full py-16 text-center border-2 border-dashed border-border/30 bg-background/50">
              <p class="text-[12px] text-foreground/30 uppercase tracking-[0.2em] font-headline">Предложений нет. Рынок затих.</p>
              <p class="text-[10px] text-foreground/20 font-body mt-2">Станьте первым — выставьте свой лот.</p>
            </div>
          <% else %>
            <%= for trade <- @trades do %>
              <div class="group relative bg-background border border-border/50 hover:border-yellow-600/50 transition-colors flex flex-col justify-between overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-yellow-900/5 to-transparent pointer-events-none"></div>

                <div class="p-6 relative z-10 flex-1">
                  <div class="flex justify-between items-start mb-4">
                    <span class="text-[9px] font-headline text-yellow-600/70 tracking-widest border border-yellow-900/30 px-2 py-1 bg-yellow-900/10 uppercase">
                      <%= if trade.type == :soul, do: "ДУША", else: "ПРЕДМЕТ" %>
                    </span>
                    <span class="text-[10px] uppercase font-body text-foreground/40">Лот #<%= trade.id %></span>
                  </div>

                  <h3 class="font-headline text-xl text-foreground uppercase tracking-[0.1em] mb-2">
                    <%= if trade.type == :soul do %>
                      <%= trade.character && trade.character.name || "Герой" %>
                    <% else %>
                      <%= trade.item_name || "Неизвестный предмет" %>
                    <% end %>
                  </h3>

                  <div class="text-[10px] text-foreground/50 leading-relaxed font-body mb-6 border-l-2 border-border/30 pl-3">
                    <%= if trade.type == :soul do %>
                      <%= if trade.character do %>
                        <p>Уровень: <span class="text-foreground/80"><%= trade.character.level %></span></p>
                      <% else %>
                        <p>Данные героя недоступны.</p>
                      <% end %>
                    <% else %>
                      <p>Предмет выставлен на продажу.</p>
                    <% end %>
                  </div>
                </div>

                <div class="relative z-10 p-6 pt-0 mt-auto">
                  <div class="flex justify-between items-center mb-4">
                    <span class="text-[9px] uppercase tracking-widest text-foreground/40">Стоимость</span>
                    <span class="font-headline text-xl text-yellow-500 tracking-wider"><%= trade.price %> з.</span>
                  </div>

                  <%= if trade.seller_id != @current_user_id do %>
                    <button
                      phx-click="buy_trade"
                      phx-value-id={trade.id}
                      id={"buy-trade-#{trade.id}"}
                      class="w-full py-4 border border-yellow-900/50 bg-yellow-900/10 text-[10px] font-headline uppercase tracking-[0.2em] text-yellow-500 hover:bg-yellow-900/30 hover:border-yellow-500 transition-all group-hover:shadow-[0_0_15px_rgba(202,138,4,0.1)]"
                    >
                      Заключить сделку
                    </button>
                  <% else %>
                    <div class="w-full py-4 text-center text-[10px] font-headline uppercase tracking-widest text-foreground/20 border border-dashed border-border/20">
                      Ваш лот
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </main>
    </div>
    """
  end
end
