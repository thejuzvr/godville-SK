defmodule GodvilleSkWeb.HomeLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Accounts
  alias GodvilleSk.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    login_form = to_form(%{"email" => email}, as: "user")

    changeset = Accounts.change_user_registration(%User{})
    register_form = to_form(changeset, as: "user")

    {:ok,
     assign(socket,
       tab: :login,
       login_form: login_form,
       register_form: register_form,
       trigger_submit: false,
       check_errors: false,
       page_title: "Welcome"
     )}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab =
      case tab do
        "register" -> :register
        _ -> :login
      end

    {:noreply, assign(socket, tab: tab)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    register_form = to_form(Map.put(changeset, :action, :validate), as: "user")
    {:noreply, assign(socket, register_form: register_form)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)

        {:noreply,
         socket
         |> assign(trigger_submit: true, check_errors: false, tab: :register)
         |> assign(register_form: to_form(changeset, as: "user"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(socket,
           check_errors: true,
           register_form: to_form(changeset, as: "user"),
           tab: :register
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-background text-foreground relative flex items-center justify-center p-4 lg:p-8">
      <!-- Background texture/image with heavy overlay -->
      <div class="absolute inset-0 bg-[url('/images/login-bg2.jpg')] bg-cover bg-center opacity-30"></div>
      <div class="absolute inset-0 bg-gradient-to-t from-background via-background/80 to-transparent"></div>
      <div class="absolute inset-0 border-[8px] md:border-[16px] border-background/90 z-10 pointer-events-none"></div>

      <!-- Core monolith -->
      <div class="w-full max-w-4xl grid grid-cols-1 lg:grid-cols-2 bg-card/80 border border-border/80 backdrop-blur-md relative z-20 shadow-2xl">
        
        <!-- Left storytelling column (Editorial) -->
        <div class="p-8 lg:p-12 border-b lg:border-b-0 lg:border-r border-border/50 flex flex-col justify-between">
          <div>
            <div class="flex items-center gap-3 text-primary font-headline tracking-widest uppercase text-xs mb-8">
              <span class="inline-block w-2 h-2 bg-primary"></span>
              ElderScrollsIdle
            </div>
            <h1 class="font-headline text-4xl lg:text-5xl text-foreground leading-[1.1] tracking-tight mb-4">
              Судьба<br/>Ожидает
            </h1>
            <p class="text-foreground/70 font-body leading-relaxed text-sm lg:text-base max-w-sm mt-6 border-l-2 border-foreground/20 pl-4 py-1">
              Ваша эпическая история начинается здесь. Войдите в архив героев или добавьте новое имя в летописи Тамриэля.
            </p>
          </div>
          
          <div class="mt-12 lg:mt-0 p-4 bg-background/50 border border-border/30 relative">
            <div class="absolute top-0 left-0 w-2 h-2 border-t border-l border-primary/40"></div>
            <div class="absolute bottom-0 right-0 w-2 h-2 border-b border-r border-primary/40"></div>
            <div class="text-foreground/90 font-headline text-lg italic tracking-wide">
              "Единственная настоящая сила идёт изнутри."
            </div>
            <div class="mt-3 text-[10px] text-foreground/50 font-body uppercase tracking-wider">
              Старая оркская пословица
            </div>
          </div>
        </div>

        <!-- Right interactive column (Utilitarian Terminal) -->
        <div class="p-8 lg:p-12 bg-background/70 flex flex-col justify-center relative">
          <!-- Decorative corners -->
          <div class="absolute top-0 left-0 w-3 h-3 border-t border-l border-primary/50"></div>
          <div class="absolute top-0 right-0 w-3 h-3 border-t border-r border-primary/50"></div>
          <div class="absolute bottom-0 left-0 w-3 h-3 border-b border-l border-primary/50"></div>
          <div class="absolute bottom-0 right-0 w-3 h-3 border-b border-r border-primary/50"></div>

          <div class="flex gap-0 border-b border-border/80 mb-8 mt-2">
            <button
              type="button"
              phx-click="switch_tab"
              phx-value-tab="login"
              class={[
                "flex-1 px-4 py-3 text-xs font-headline tracking-widest uppercase transition-all border-b-2",
                @tab == :login && "text-primary border-primary bg-primary/5",
                @tab != :login && "text-foreground/40 border-transparent hover:text-foreground/70 hover:bg-foreground/5"
              ]}
            >
              Врата
            </button>
            <button
              type="button"
              phx-click="switch_tab"
              phx-value-tab="register"
              class={[
                "flex-1 px-4 py-3 text-xs font-headline tracking-widest uppercase transition-all border-b-2",
                @tab == :register && "text-primary border-primary bg-primary/5",
                @tab != :register && "text-foreground/40 border-transparent hover:text-foreground/70 hover:bg-foreground/5"
              ]}
            >
              Ритуал
            </button>
          </div>

          <div :if={@tab == :login}>
            <.form
              for={@login_form}
              id="login_form"
              action={~p"/users/log_in"}
              phx-update="ignore"
              class="space-y-6"
            >
              <div class="space-y-1">
                <label class="block text-[10px] text-primary/70 font-headline uppercase tracking-widest">
                  Свиток почты
                </label>
                <.input field={@login_form[:email]} type="email" required class="w-full" />
              </div>

              <div class="space-y-1">
                <label class="block text-[10px] text-primary/70 font-headline uppercase tracking-widest">
                  Тайное слово (Пароль)
                </label>
                <.input field={@login_form[:password]} type="password" required class="w-full" />
              </div>

              <div class="flex items-center justify-between pt-2">
                <label class="flex items-center gap-2 text-xs text-foreground/60 font-body tracking-wide">
                  <.input field={@login_form[:remember_me]} type="checkbox" /> Запомнить руны
                </label>
                <.link
                  href={~p"/users/reset_password"}
                  class="text-[10px] text-primary/60 hover:text-primary font-headline uppercase tracking-widest transition-colors"
                >
                  Забыли пароль?
                </.link>
              </div>

              <button
                type="submit"
                class="w-full mt-4 border border-primary/50 bg-primary/10 hover:bg-primary/20 text-primary px-6 py-4 font-headline uppercase tracking-widest transition-all focus:outline-none focus:ring-1 focus:ring-primary"
              >
                Войти в Мир
              </button>
            </.form>
          </div>

          <div :if={@tab == :register}>
            <.form
              for={@register_form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              phx-trigger-action={@trigger_submit}
              action={~p"/users/log_in?_action=registered"}
              method="post"
              class="space-y-6"
            >
              <.error :if={@check_errors}>
                <div class="text-xs font-body p-2 bg-red-500/10 border border-red-500/30 text-red-500 uppercase tracking-wide">
                  Архивы отвергли запись — проверьте символы.
                </div>
              </.error>

              <div class="space-y-1">
                <label class="block text-[10px] text-primary/70 font-headline uppercase tracking-widest">
                  Свиток почты
                </label>
                <.input field={@register_form[:email]} type="email" required class="w-full" />
              </div>

              <div class="space-y-1">
                <label class="block text-[10px] text-primary/70 font-headline uppercase tracking-widest">
                  Сформировать слово (Пароль)
                </label>
                <.input field={@register_form[:password]} type="password" required class="w-full" />
              </div>

              <button
                type="submit"
                phx-disable-with="Написание рун..."
                class="w-full mt-4 border border-primary/50 bg-primary/10 hover:bg-primary/20 text-primary px-6 py-4 font-headline uppercase tracking-widest transition-all focus:outline-none focus:ring-1 focus:ring-primary"
              >
                Начать Хронику
              </button>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
