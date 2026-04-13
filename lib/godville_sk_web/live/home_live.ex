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
    <div class="min-h-screen bg-background text-foreground">
      <div class="min-h-screen grid grid-cols-1 lg:grid-cols-2">
        <div class="relative hidden lg:block">
          <div class="absolute inset-0 bg-[url('/images/login-bg2.jpg')] bg-cover bg-center opacity-80"></div>
          <div class="absolute inset-0 bg-gradient-to-r from-background/70 via-background/20 to-background"></div>

          <div class="relative z-10 h-full p-10 flex flex-col justify-between">
            <div class="flex items-center gap-2 text-primary font-headline tracking-wider">
              <span class="inline-flex h-8 w-8 items-center justify-center rounded-full border border-primary/30">E</span>
              <span>ElderScrollsIdle</span>
            </div>

            <div class="max-w-xl">
              <div class="text-foreground/80 font-headline text-xl">
                "Единственная настоящая сила идёт изнутри."
              </div>
              <div class="mt-2 text-sm text-foreground/50 font-body">Старая орочья пословица</div>
            </div>
          </div>
        </div>

        <div class="flex items-center justify-center p-6 lg:p-10">
          <div class="w-full max-w-md">
            <div class="text-center mb-6">
              <h1 class="font-headline text-3xl text-primary tracking-wide">Добро пожаловать, странник</h1>
              <p class="mt-2 text-sm text-foreground/60 font-body">
                Ваша эпическая история начинается здесь. Войдите или создайте своего героя.
              </p>
            </div>

            <div class="bg-card border border-border/50 shadow-2xl p-6 md:p-8">
              <div class="flex gap-2 mb-6 bg-secondary/40 p-1 rounded-md">
                <button
                  type="button"
                  phx-click="switch_tab"
                  phx-value-tab="login"
                  class={[
                    "flex-1 px-3 py-2 text-sm font-headline tracking-wide rounded",
                    @tab == :login && "bg-background border border-border/60",
                    @tab != :login && "text-foreground/70 hover:text-foreground"
                  ]}
                >
                  Вход
                </button>
                <button
                  type="button"
                  phx-click="switch_tab"
                  phx-value-tab="register"
                  class={[
                    "flex-1 px-3 py-2 text-sm font-headline tracking-wide rounded",
                    @tab == :register && "bg-background border border-border/60",
                    @tab != :register && "text-foreground/70 hover:text-foreground"
                  ]}
                >
                  Регистрация
                </button>
              </div>

              <div :if={@tab == :login}>
                <.form for={@login_form} id="login_form" action={~p"/users/log_in"} phx-update="ignore" class="space-y-4">
                  <div>
                    <label class="block text-xs text-foreground/70 font-headline tracking-wide mb-1">Электронная почта</label>
                    <.input field={@login_form[:email]} type="email" required class="w-full" />
                  </div>

                  <div>
                    <label class="block text-xs text-foreground/70 font-headline tracking-wide mb-1">Пароль</label>
                    <.input field={@login_form[:password]} type="password" required class="w-full" />
                  </div>

                  <div class="flex items-center justify-between">
                    <label class="flex items-center gap-2 text-xs text-foreground/60">
                      <.input field={@login_form[:remember_me]} type="checkbox" />
                      Запомнить меня
                    </label>
                    <.link href={~p"/users/reset_password"} class="text-xs text-primary underline hover:text-primary/80">
                      Забыли пароль?
                    </.link>
                  </div>

                  <button type="submit" class="w-full px-4 py-2 bg-primary text-primary-foreground font-headline tracking-wide">
                    Войти
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
                  class="space-y-4"
                >
                  <.error :if={@check_errors}>
                    Проверьте поля формы — есть ошибки.
                  </.error>

                  <div>
                    <label class="block text-xs text-foreground/70 font-headline tracking-wide mb-1">Электронная почта</label>
                    <.input field={@register_form[:email]} type="email" required class="w-full" />
                  </div>

                  <div>
                    <label class="block text-xs text-foreground/70 font-headline tracking-wide mb-1">Пароль</label>
                    <.input field={@register_form[:password]} type="password" required class="w-full" />
                  </div>

                  <button
                    type="submit"
                    phx-disable-with="Создаю аккаунт..."
                    class="w-full px-4 py-2 bg-primary text-primary-foreground font-headline tracking-wide"
                  >
                    Создать аккаунт
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
end

