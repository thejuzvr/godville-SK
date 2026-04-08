defmodule GodvilleSkWeb.UserLoginLive do
  use GodvilleSkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-[#0e0c07] overflow-hidden">
      <!-- Left atmospheric panel -->
      <div class="hidden lg:flex lg:w-[58%] relative flex-col overflow-hidden">
        <!-- Deep background -->
        <div class="absolute inset-0 bg-gradient-to-br from-[#0a0804] via-[#16120a] to-[#0a0804]"></div>
        <!-- Radial glow from bottom -->
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_80%_60%_at_50%_100%,rgba(180,148,70,0.10)_0%,transparent_70%)]"></div>
        <!-- Top glow -->
        <div class="absolute top-0 inset-x-0 h-64 bg-[radial-gradient(ellipse_60%_100%_at_50%_0%,rgba(180,148,70,0.06)_0%,transparent_100%)]"></div>

        <!-- Grid texture overlay -->
        <div class="absolute inset-0 opacity-[0.03]"
             style="background-image: repeating-linear-gradient(0deg, #c4a046 0px, transparent 1px, transparent 60px),
                                      repeating-linear-gradient(90deg, #c4a046 0px, transparent 1px, transparent 60px)">
        </div>

        <!-- Logo top-left -->
        <div class="relative z-10 p-8 flex items-center gap-2.5">
          <svg class="w-6 h-6 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M12 2L2 7v5c0 5.25 4.25 10.15 10 11.25C17.75 22.15 22 17.25 22 12V7L12 2z" />
          </svg>
          <span class="font-headline text-primary/90 text-sm tracking-widest uppercase">ElderScrollsIdle</span>
        </div>

        <!-- Center decorative emblem -->
        <div class="relative z-10 flex-1 flex items-center justify-center">
          <div class="relative">
            <!-- Outer ring -->
            <div class="w-64 h-64 rounded-full border border-primary/10 absolute -inset-8 animate-[spin_40s_linear_infinite]"></div>
            <div class="w-48 h-48 rounded-full border border-primary/15 absolute -inset-4"></div>
            <!-- Main emblem -->
            <svg class="w-40 h-40 text-primary/20" viewBox="0 0 200 200" fill="currentColor">
              <polygon points="100,10 120,80 195,80 135,125 158,195 100,155 42,195 65,125 5,80 80,80" />
            </svg>
            <!-- Center star -->
            <div class="absolute inset-0 flex items-center justify-center">
              <svg class="w-16 h-16 text-primary/40" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 17l-6.2 4.3 2.4-7.4L2 9.4h7.6z" />
              </svg>
            </div>
          </div>
        </div>

        <!-- Bottom quote -->
        <div class="relative z-10 p-8 pb-12 border-t border-primary/10">
          <p class="font-headline italic text-foreground/70 text-base leading-relaxed">
            "Единственная настоящая сила идет изнутри."
          </p>
          <p class="font-body text-foreground/40 text-sm mt-2">— Старая аргонская пословица</p>
        </div>
      </div>

      <!-- Right form panel -->
      <div class="w-full lg:w-[42%] bg-[#13100a] flex flex-col items-center justify-center p-8 lg:p-12 relative">
        <!-- Subtle top border glow -->
        <div class="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-primary/30 to-transparent"></div>

        <div class="w-full max-w-sm">
          <!-- Mobile logo -->
          <div class="flex items-center justify-center gap-2 mb-8 lg:hidden">
            <svg class="w-5 h-5 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M12 2L2 7v5c0 5.25 4.25 10.15 10 11.25C17.75 22.15 22 17.25 22 12V7L12 2z" />
            </svg>
            <span class="font-headline text-primary text-sm tracking-widest">ElderScrollsIdle</span>
          </div>

          <!-- Heading -->
          <h1 class="font-headline text-2xl text-foreground text-center mb-2 leading-tight">
            Добро пожаловать, странник
          </h1>
          <p class="font-body text-foreground/50 text-sm text-center mb-8 leading-relaxed">
            Ваша эпическая история начинается здесь.<br/>Войдите или создайте своего героя.
          </p>

          <!-- Tabs -->
          <div class="flex w-full mb-6 border border-border/40">
            <span class="flex-1 py-2.5 text-center text-sm font-headline tracking-wide bg-primary/15 text-primary border-b-2 border-primary cursor-default">
              Вход
            </span>
            <.link
              navigate={~p"/users/register"}
              class="flex-1 py-2.5 text-center text-sm font-headline tracking-wide text-foreground/50 hover:text-foreground/80 transition-colors"
            >
              Регистрация
            </.link>
          </div>

          <!-- Flash error -->
          <div :if={@flash["error"]} class="mb-4 p-3 bg-destructive/20 border border-destructive/40 text-sm text-foreground/80 font-body">
            {@flash["error"]}
          </div>

          <!-- Form -->
          <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore" class="space-y-5">
            <div>
              <label class="font-body block text-sm text-foreground/70 mb-1.5">Электронная почта</label>
              <input
                type="email"
                name="user[email]"
                value={@form[:email].value}
                placeholder="you@example.com"
                required
                class="w-full px-3 py-2.5 bg-background/40 border border-border/60 text-foreground placeholder:text-foreground/30 focus:border-primary focus:outline-none text-sm font-body"
              />
            </div>

            <div>
              <label class="font-body block text-sm text-foreground/70 mb-1.5">Пароль</label>
              <input
                type="password"
                name="user[password]"
                placeholder="••••••••"
                required
                class="w-full px-3 py-2.5 bg-background/40 border border-border/60 text-foreground placeholder:text-foreground/30 focus:border-primary focus:outline-none text-sm font-body"
              />
            </div>

            <div class="flex items-center justify-between text-sm">
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" name="user[remember_me]" class="w-3.5 h-3.5 accent-primary" />
                <span class="font-body text-foreground/50">Запомнить меня</span>
              </label>
              <.link href={~p"/users/reset_password"} class="font-body text-foreground/50 hover:text-primary transition-colors text-xs">
                Забыли пароль?
              </.link>
            </div>

            <button
              type="submit"
              class="w-full py-2.5 bg-primary text-background font-headline tracking-wide hover:bg-primary/90 transition-colors"
            >
              Войти
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
