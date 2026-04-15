defmodule GodvilleSkWeb.UserSettingsLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Accounts
  import GodvilleSkWeb.NavComponents

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen overflow-hidden bg-background relative font-body">
      <!-- Arcane texture background -->
      <div class="absolute inset-0 bg-[url('/images/login-bg2.jpg')] bg-cover bg-center opacity-[0.08] pointer-events-none"></div>

      <!-- Top Nav -->
      <div class="relative z-10 border-b-2 border-border/80 bg-background/90 backdrop-blur-sm">
        <.game_nav active_tab={:profile} />
      </div>

      <div class="flex-1 overflow-y-auto p-4 md:p-8 relative z-10 custom-scrollbar">
        <div class="max-w-4xl mx-auto space-y-12">
          <!-- Page Header -->
          <div class="relative pb-6 border-b border-border/40 text-center">
            <h1 class="text-3xl font-headline text-primary tracking-[0.3em] uppercase drop-shadow-[0_0_10px_rgba(200,150,50,0.3)]">
              Настройки Профиля
            </h1>
            <p class="text-foreground/40 font-headline uppercase tracking-widest text-[9px] mt-2">
              Имперский реестр: управление вашей сущностью и божественными атрибутами.
            </p>
            <div class="absolute bottom-0 left-1/2 -translate-x-1/2 w-32 h-[1px] bg-primary/40"></div>
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <!-- LEFT COLUMN: Theme & Social -->
            <div class="space-y-8">
              <!-- DICE THEME CARD -->
              <div class="bg-background/80 border-[2px] border-double border-border/60 p-8 relative overflow-hidden group">
                <div class="absolute top-0 right-0 w-3 h-3 border-t-2 border-r-2 border-primary/50"></div>
                <div class="absolute bottom-0 left-0 w-3 h-3 border-b-2 border-l-2 border-primary/50"></div>

                <div class="absolute top-0 right-0 p-4 opacity-[0.03] group-hover:opacity-10 transition-opacity">
                  <svg class="w-32 h-32 text-primary" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19,5V19H5V5H19M19,3H5A2,2 0 0,0 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5A2,2 0 0,0 19,3M12,10.5A1.5,1.5 0 1,1 10.5,12A1.5,1.5 0 0,1 12,10.5M7,7A1.5,1.5 0 1,1 5.5,8.5A1.5,1.5 0 0,1 7,7M17,17A1.5,1.5 0 1,1 15.5,18.5A1.5,1.5 0 0,1 17,17M17,7A1.5,1.5 0 1,1 15.5,8.5A1.5,1.5 0 0,1 17,7M7,17A1.5,1.5 0 1,1 5.5,18.5A1.5,1.5 0 0,1 7,17Z" />
                  </svg>
                </div>
                
                <h2 class="font-headline text-primary mb-8 px-2 flex items-center gap-3 uppercase tracking-widest border-b border-border/30 pb-3">
                  <span class="w-1.5 h-1.5 bg-primary transform rotate-45"></span>
                  Оформление
                </h2>

                <.form for={@theme_form} phx-submit="update_theme" class="space-y-6 relative z-10">
                  <div class="space-y-2">
                    <label class="text-[9px] font-headline text-foreground/50 uppercase tracking-[0.2em] px-2 block">
                      Тема костей D20
                    </label>
                    <select
                      name="user[dice_theme]"
                      class="w-full bg-background border border-border/60 text-foreground/80 px-4 py-3 text-sm focus:border-primary focus:ring-1 focus:ring-primary/50 outline-none transition-all cursor-pointer font-headline uppercase tracking-wider"
                    >
                      <%= for {label, value} <- [{"Эхо Золота (По умолчанию)", "default"}, {"Кровь Даэдра (Красный)", "crimson"}, {"Слезы Обливиона (Обсидиан)", "obsidian"}, {"Древний Свиток (Бюрюза)", "paper"}] do %>
                        <option value={value} selected={value == @theme_form[:dice_theme].value}>
                          <%= label %>
                        </option>
                      <% end %>
                    </select>
                  </div>
                  <button
                    type="submit"
                    class="w-full py-3 bg-primary/10 border border-primary/50 hover:bg-primary/20 text-primary font-headline text-[10px] uppercase tracking-[0.2em] transition-all shadow-[inset_0_0_10px_rgba(200,150,50,0.1)] hover:shadow-[0_0_15px_rgba(200,150,50,0.2)]"
                  >
                    Запечатлеть Тему
                  </button>
                </.form>
              </div>

              <!-- ACCOUNT INFO PREVIEW -->
              <div class="bg-background/80 border border-border/50 p-6 backdrop-blur-sm relative">
                <div class="absolute top-0 left-0 w-2 h-2 border-t border-l border-primary/50"></div>
                <div class="absolute bottom-0 right-0 w-2 h-2 border-b border-r border-primary/50"></div>
                
                <h2 class="font-headline text-foreground/50 text-[10px] mb-4 uppercase tracking-[0.2em] border-b border-border/20 pb-2">
                  Статус Души
                </h2>
                <div class="grid grid-cols-2 gap-4">
                  <div class="p-3 bg-border/20 border border-border/30 text-center">
                    <span class="text-[9px] text-foreground/40 font-headline uppercase tracking-widest block mb-1">Истинное Имя (ID)</span>
                    <span class="text-sm font-headline text-primary tracking-widest">#<%= @current_user.id %></span>
                  </div>
                  <div class="p-3 bg-border/20 border border-border/30 text-center">
                    <span class="text-[9px] text-foreground/40 font-headline uppercase tracking-widest block mb-1">Запись Создана</span>
                    <span class="text-sm font-headline text-foreground/70 tracking-widest">
                      <%= Calendar.strftime(@current_user.inserted_at, "%d.%m.%Y") %>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <!-- RIGHT COLUMN: Security & Email -->
            <div class="space-y-8">
              <!-- EMAIL SETTINGS -->
              <div class="bg-background/80 border border-border/50 p-8 relative">
                <div class="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-primary/30 via-transparent to-transparent"></div>
                
                <h2 class="font-headline text-primary mb-6 px-2 flex items-center gap-3 uppercase tracking-widest border-b border-border/30 pb-3">
                  <span class="w-1.5 h-1.5 bg-primary transform rotate-45"></span>
                  Учетные данные
                </h2>

                <.form for={@email_form} phx-submit="update_email" class="space-y-6">
                  <div class="space-y-2">
                    <label class="text-[9px] font-headline text-foreground/50 uppercase tracking-[0.2em] px-2 block">
                      Связующий Email (Почта)
                    </label>
                    <input
                      type="email"
                      name="user[email]"
                      value={@email_form[:email].value}
                      class="w-full bg-background border border-border/60 text-foreground px-4 py-3 text-sm focus:border-primary focus:ring-1 focus:ring-primary/50 outline-none transition-all font-body font-bold"
                    />
                    <%= if error = List.first(@email_form[:email].errors) do %>
                      <div class="text-[9px] text-red-500 font-headline uppercase tracking-widest bg-red-900/10 border border-red-900/30 p-2 mt-2">
                        Ошибка: <%= translate_error(error) %>
                      </div>
                    <% end %>
                  </div>

                  <div class="space-y-2">
                    <label class="text-[9px] font-headline text-foreground/50 uppercase tracking-[0.2em] px-2 block">
                      Ключ Подтверждения (Текущий Пароль)
                    </label>
                    <input
                      type="password"
                      name="current_password"
                      id="current_password_for_email"
                      class="w-full bg-background border border-border/60 text-foreground px-4 py-3 text-sm focus:border-primary focus:ring-1 focus:ring-primary/50 outline-none transition-all font-body tracking-[0.5em]"
                    />
                  </div>

                  <button
                    type="submit"
                    class="w-full py-3 bg-background border border-border/50 hover:border-primary/50 hover:bg-primary/5 text-foreground/80 font-headline text-[10px] tracking-[0.2em] uppercase transition-all"
                  >
                    Изменить Связь (Email)
                  </button>
                </.form>
              </div>

              <!-- PASSWORD SETTINGS -->
              <div class="bg-background/80 border border-border/50 p-8 relative">
                <div class="absolute bottom-0 right-0 w-full h-[1px] bg-gradient-to-l from-primary/30 via-transparent to-transparent"></div>
                
                <h2 class="font-headline text-primary mb-6 px-2 flex items-center gap-3 uppercase tracking-widest border-b border-border/30 pb-3">
                  <span class="w-1.5 h-1.5 bg-primary transform rotate-45"></span>
                  Защита (Пароль)
                </h2>

                <.form
                  for={@password_form}
                  action={~p"/users/log_in?_action=password_updated"}
                  method="post"
                  phx-submit="update_password"
                  phx-trigger-action={@trigger_submit}
                  class="space-y-6"
                >
                  <input name={@password_form[:email].name} type="hidden" value={@current_email} />

                  <div class="space-y-2">
                    <label class="text-[9px] font-headline text-foreground/50 uppercase tracking-[0.2em] px-2 block">
                      Новый Ключ (Пароль)
                    </label>
                    <input
                      type="password"
                      name="user[password]"
                      class="w-full bg-background border border-border/60 text-foreground px-4 py-3 text-sm focus:border-primary focus:ring-1 focus:ring-primary/50 outline-none transition-all font-body tracking-[0.5em]"
                    />
                    <%= if error = List.first(@password_form[:password].errors) do %>
                      <div class="text-[9px] text-red-500 font-headline uppercase tracking-widest bg-red-900/10 border border-red-900/30 p-2 mt-2">
                        Ошибка: <%= translate_error(error) %>
                      </div>
                    <% end %>
                  </div>

                  <div class="space-y-2">
                    <label class="text-[9px] font-headline text-foreground/50 uppercase tracking-[0.2em] px-2 block">
                      Повторите Ключ
                    </label>
                    <input
                      type="password"
                      name="user[password_confirmation]"
                      class="w-full bg-background border border-border/60 text-foreground px-4 py-3 text-sm focus:border-primary focus:ring-1 focus:ring-primary/50 outline-none transition-all font-body tracking-[0.5em]"
                    />
                  </div>

                  <div class="space-y-2">
                    <label class="text-[9px] font-headline text-foreground/50 uppercase tracking-[0.2em] px-2 block">
                      Старый Ключ (Текущий Пароль)
                    </label>
                    <input
                      type="password"
                      name="current_password"
                      id="current_password_for_password"
                      class="w-full bg-background border border-border/60 text-foreground px-4 py-3 text-sm focus:border-primary focus:ring-1 focus:ring-primary/50 outline-none transition-all font-body tracking-[0.5em]"
                    />
                  </div>

                  <button
                    type="submit"
                    class="w-full py-3 bg-red-900/10 border border-red-900/50 hover:bg-red-900/30 text-red-500 font-headline text-[10px] tracking-[0.2em] uppercase transition-all"
                  >
                    Перековать Ключ Защиты
                  </button>
                </.form>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    theme_changeset = Accounts.change_user_dice_theme(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:theme_form, to_form(theme_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("validate_theme", %{"user" => user_params}, socket) do
    theme_form =
      socket.assigns.current_user
      |> Accounts.change_user_dice_theme(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, theme_form: theme_form)}
  end

  def handle_event("update_theme", %{"user" => user_params}, socket) do
    case Accounts.update_user_dice_theme(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        socket = assign(socket, current_user: user)
        {:noreply, put_flash(socket, :info, "Dice theme updated successfully.")}

      {:error, changeset} ->
        {:noreply, assign(socket, theme_form: to_form(changeset))}
    end
  end
end
