defmodule GodvilleSkWeb.UserRegistrationLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Accounts
  alias GodvilleSk.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-[#0e0c07] overflow-hidden">
      <!-- Left atmospheric panel -->
      <div class="hidden lg:flex lg:w-[58%] relative flex-col overflow-hidden bg-[url('/images/elder_scrolls_login_bg.png')] bg-cover bg-center">
        <!-- Deep background -->
        <div class="absolute inset-0 bg-gradient-to-r from-black/60 to-[#0e0c07]/90"></div>
        <div class="absolute inset-0 bg-gradient-to-t from-[#0e0c07] via-transparent to-black/50"></div>
        <div class="relative z-10 p-8 flex items-center gap-2.5">
          <svg class="w-6 h-6 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M12 2L2 7v5c0 5.25 4.25 10.15 10 11.25C17.75 22.15 22 17.25 22 12V7L12 2z" />
          </svg>
          <span class="font-headline text-primary/90 text-sm tracking-widest uppercase">ElderScrollsIdle</span>
        </div>
        <div class="relative z-10 flex-1 flex items-center justify-center">
          <div class="relative">
            <div class="w-64 h-64 rounded-full border border-primary/10 absolute -inset-8 animate-[spin_40s_linear_infinite]"></div>
            <div class="w-48 h-48 rounded-full border border-primary/15 absolute -inset-4"></div>
            <svg class="w-40 h-40 text-primary/20" viewBox="0 0 200 200" fill="currentColor">
              <polygon points="100,10 120,80 195,80 135,125 158,195 100,155 42,195 65,125 5,80 80,80" />
            </svg>
            <div class="absolute inset-0 flex items-center justify-center">
              <svg class="w-16 h-16 text-primary/40" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 17l-6.2 4.3 2.4-7.4L2 9.4h7.6z" />
              </svg>
            </div>
          </div>
        </div>
        <div class="relative z-10 p-8 pb-12 border-t border-primary/10">
          <p class="font-headline italic text-foreground/70 text-base leading-relaxed">
            "Знание — самое могущественное оружие из всех существующих."
          </p>
          <p class="font-body text-foreground/40 text-sm mt-2">— Архимаг Нирус</p>
        </div>
      </div>

      <!-- Right form panel -->
      <div class="w-full lg:w-[42%] bg-[#13100a] flex flex-col items-center justify-center p-8 lg:p-12 relative">
        <div class="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-primary/30 to-transparent"></div>

        <div class="w-full max-w-sm">
          <div class="flex items-center justify-center gap-2 mb-8 lg:hidden">
            <svg class="w-5 h-5 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M12 2L2 7v5c0 5.25 4.25 10.15 10 11.25C17.75 22.15 22 17.25 22 12V7L12 2z" />
            </svg>
            <span class="font-headline text-primary text-sm tracking-widest">ElderScrollsIdle</span>
          </div>

          <h1 class="font-headline text-2xl text-foreground text-center mb-2 leading-tight">
            Добро пожаловать, странник
          </h1>
          <p class="font-body text-foreground/50 text-sm text-center mb-8 leading-relaxed">
            Ваша эпическая история начинается здесь.<br/>Войдите или создайте своего героя.
          </p>

          <!-- Tabs -->
          <div class="flex w-full mb-6 border border-border/40">
            <.link
              navigate={~p"/users/log_in"}
              class="flex-1 py-2.5 text-center text-sm font-headline tracking-wide text-foreground/50 hover:text-foreground/80 transition-colors"
            >
              Вход
            </.link>
            <span class="flex-1 py-2.5 text-center text-sm font-headline tracking-wide bg-primary/15 text-primary border-b-2 border-primary cursor-default">
              Регистрация
            </span>
          </div>

          <.error :if={@check_errors}>
            Что-то пошло не так! Проверьте ошибки ниже.
          </.error>

          <.form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/log_in?_action=registered"}
            method="post"
            class="space-y-4"
          >
            <div>
              <label class="font-body block text-sm text-foreground/70 mb-1.5">Электронная почта</label>
              <.input
                field={@form[:email]}
                type="email"
                placeholder="you@example.com"
                required
              />
            </div>

            <div>
              <label class="font-body block text-sm text-foreground/70 mb-1.5">Пароль</label>
              <.input
                field={@form[:password]}
                type="password"
                placeholder="Минимум 12 символов"
                required
              />
            </div>

            <button
              type="submit"
              phx-disable-with="Создаём аккаунт..."
              class="w-full py-2.5 bg-primary text-background font-headline tracking-wide hover:bg-primary/90 transition-colors mt-2"
            >
              Создать аккаунт
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)
    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )
        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
