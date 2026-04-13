defmodule GodvilleSkWeb.UserSettingsLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Accounts
  import GodvilleSkWeb.NavComponents
  
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen overflow-hidden bg-background">
      <!-- Top Nav -->
      <.game_nav active_tab={:profile} />

      <div class="flex-1 overflow-y-auto p-4 md:p-8">
        <div class="max-w-4xl mx-auto space-y-8">
          
          <!-- Page Header -->
          <div class="relative pb-6 border-b border-border/40">
            <h1 class="text-3xl font-headline text-primary tracking-widest uppercase">Настройки Профиля</h1>
            <p class="text-foreground/50 font-body mt-1 italic">Имперский реестр: управление вашей сущностью и божественными атрибутами.</p>
            <div class="absolute bottom-0 left-0 w-32 h-0.5 bg-primary/40"></div>
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            
            <!-- LEFT COLUMN: Theme & Social -->
            <div class="space-y-8">
              <!-- DICE THEME CARD -->
              <div class="bg-card border border-border/50 p-6 relative overflow-hidden group">
                <div class="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
                  <svg class="w-24 h-24 text-primary" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19,5V19H5V5H19M19,3H5A2,2 0 0,0 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5A2,2 0 0,0 19,3M12,10.5A1.5,1.5 0 1,1 10.5,12A1.5,1.5 0 0,1 12,10.5M7,7A1.5,1.5 0 1,1 5.5,8.5A1.5,1.5 0 0,1 7,7M17,17A1.5,1.5 0 1,1 15.5,18.5A1.5,1.5 0 0,1 17,17M17,7A1.5,1.5 0 1,1 15.5,8.5A1.5,1.5 0 0,1 17,7M7,17A1.5,1.5 0 1,1 5.5,18.5A1.5,1.5 0 0,1 7,17Z" />
                  </svg>
                </div>
                <h2 class="font-headline text-primary mb-6 flex items-center gap-2">
                  <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
                  </svg>
                  Оформление
                </h2>
                
                <.form for={@theme_form} phx-submit="update_theme" class="space-y-4">
                  <div class="space-y-1.5">
                    <label class="text-xs font-headline text-foreground/60 uppercase tracking-widest">Тема костей D20</label>
                    <select 
                      name="user[dice_theme]"
                      class="w-full bg-background/50 border border-border/40 text-foreground px-3 py-2 text-sm focus:border-primary outline-none transition-all cursor-pointer font-body"
                    >
                      <%= for {label, value} <- [{"Default (Dark Gold)", "default"}, {"Crimson (Dark Red)", "crimson"}, {"Obsidian (Black Gloss)", "obsidian"}, {"Sketch (Paper Teal)", "paper"}] do %>
                        <option value={value} selected={value == @theme_form[:dice_theme].value}><%= label %></option>
                      <% end %>
                    </select>
                  </div>
                  <button type="submit" class="w-full py-2 bg-primary/80 hover:bg-primary text-background font-headline text-xs tracking-widest transition-all shadow-lg active:translate-y-0.5">
                    СОХРАНИТЬ ТЕМУ
                  </button>
                </.form>
              </div>

              <!-- ACCOUNT INFO PREVIEW -->
               <div class="bg-card/30 border border-border/20 p-6 backdrop-blur-sm">
                 <h2 class="font-headline text-foreground/70 text-sm mb-4 uppercase tracking-widest">Текущий статус</h2>
                 <div class="space-y-3">
                    <div class="flex justify-between border-b border-border/10 pb-2">
                      <span class="text-xs text-foreground/40 font-body">ID Пользователя</span>
                      <span class="text-xs font-headline text-primary">#<%= @current_user.id %></span>
                    </div>
                    <div class="flex justify-between border-b border-border/10 pb-2">
                       <span class="text-xs text-foreground/40 font-body">В реестре с</span>
                       <span class="text-xs font-headline text-foreground/70"><%= Calendar.strftime(@current_user.inserted_at, "%d.%m.%Y") %></span>
                    </div>
                 </div>
               </div>
            </div>

            <!-- RIGHT COLUMN: Security & Email -->
            <div class="space-y-8">
              <!-- EMAIL SETTINGS -->
              <div class="bg-card border border-border/50 p-6 relative">
                 <h2 class="font-headline text-primary mb-6 flex items-center gap-2">
                   <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                     <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                     <polyline points="22,6 12,13 2,6" />
                   </svg>
                   Учетные данные
                 </h2>
                 
                 <.form for={@email_form} phx-submit="update_email" class="space-y-6">
                    <div class="space-y-1.5">
                      <label class="text-xs font-headline text-foreground/60 uppercase tracking-widest">Email Адрес</label>
                       <input 
                        type="email" 
                        name="user[email]" 
                        value={@email_form[:email].value}
                        class="w-full bg-background/50 border border-border/40 text-foreground px-3 py-2 text-sm focus:border-primary outline-none transition-all font-body"
                       />
                       <%= if error = List.first(@email_form[:email].errors) do %>
                         <span class="text-[10px] text-red-400 font-body italic"><%= translate_error(error) %></span>
                       <% end %>
                    </div>

                    <div class="space-y-1.5">
                      <label class="text-xs font-headline text-foreground/60 uppercase tracking-widest">Текущий пароль</label>
                       <input 
                        type="password" 
                        name="current_password" 
                        id="current_password_for_email"
                        class="w-full bg-background/50 border border-border/40 text-foreground px-3 py-2 text-sm focus:border-primary outline-none transition-all font-body"
                       />
                    </div>
                    
                    <button type="submit" class="w-full py-2 bg-foreground/10 hover:bg-foreground/20 text-foreground font-headline text-xs tracking-widest transition-all border border-foreground/20">
                      ИЗМЕНИТЬ EMAIL
                    </button>
                 </.form>
              </div>

              <!-- PASSWORD SETTINGS -->
              <div class="bg-card border border-border/50 p-6">
                <h2 class="font-headline text-primary mb-6 flex items-center gap-2">
                  <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0110 0v4" />
                  </svg>
                  Безопасность
                </h2>
                
                <.form 
                  for={@password_form} 
                  action={~p"/users/log_in?_action=password_updated"}
                  method="post"
                  phx-submit="update_password"
                  phx-trigger-action={@trigger_submit}
                  class="space-y-4"
                >
                   <input name={@password_form[:email].name} type="hidden" value={@current_email} />
                   
                   <div class="space-y-1.5">
                      <label class="text-xs font-headline text-foreground/60 uppercase tracking-widest">Новый пароль</label>
                      <input 
                        type="password" 
                        name="user[password]" 
                        class="w-full bg-background/50 border border-border/40 text-foreground px-3 py-2 text-sm focus:border-primary outline-none transition-all font-body"
                      />
                      <%= if error = List.first(@password_form[:password].errors) do %>
                        <span class="text-[10px] text-red-400 font-body italic"><%= translate_error(error) %></span>
                      <% end %>
                   </div>

                   <div class="space-y-1.5">
                      <label class="text-xs font-headline text-foreground/60 uppercase tracking-widest">Подтверждение пароля</label>
                      <input 
                        type="password" 
                        name="user[password_confirmation]" 
                        class="w-full bg-background/50 border border-border/40 text-foreground px-3 py-2 text-sm focus:border-primary outline-none transition-all font-body"
                      />
                   </div>

                   <div class="space-y-1.5">
                      <label class="text-xs font-headline text-foreground/60 uppercase tracking-widest">Текущий пароль</label>
                      <input 
                        type="password" 
                        name="current_password" 
                        id="current_password_for_password"
                        class="w-full bg-background/50 border border-border/40 text-foreground px-3 py-2 text-sm focus:border-primary outline-none transition-all font-body"
                      />
                   </div>

                   <button type="submit" class="w-full py-2 bg-foreground/10 hover:bg-foreground/20 text-foreground font-headline text-xs tracking-widest transition-all border border-foreground/20">
                     ОБНОВИТЬ ПАРОЛЬ
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
