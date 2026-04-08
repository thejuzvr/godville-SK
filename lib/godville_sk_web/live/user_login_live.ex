defmodule GodvilleSkWeb.UserLoginLive do
  use GodvilleSkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-[calc(100vh-80px)] flex items-center justify-center p-4">
      <div class="max-w-md w-full">
        <!-- Decorative top border -->
        <div class="flex items-center justify-center mb-8">
          <div class="h-px bg-border/30 flex-1"></div>
          <svg class="w-8 h-8 mx-4 text-primary/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" />
          </svg>
          <div class="h-px bg-border/30 flex-1"></div>
        </div>

        <!-- Main content card -->
        <div class="bg-card border border-border/50 shadow-2xl p-8 md:p-10 relative overflow-hidden">
          <!-- Decorative corner elements -->
          <div class="absolute top-0 left-0 w-20 h-20 border-l-2 border-t-2 border-primary/20"></div>
          <div class="absolute top-0 right-0 w-20 h-20 border-r-2 border-t-2 border-primary/20"></div>
          <div class="absolute bottom-0 left-0 w-20 h-20 border-l-2 border-b-2 border-primary/20"></div>
          <div class="absolute bottom-0 right-0 w-20 h-20 border-r-2 border-b-2 border-primary/20"></div>

          <div class="relative z-10">
            <!-- Title -->
            <h1 class="font-headline text-2xl md:text-3xl text-center text-primary mb-2 tracking-wider">
              Log in to account
            </h1>

            <!-- Sign up link -->
            <p class="font-body text-center text-foreground/70 mb-8">
              Don't have an account?
              <.link navigate={~p"/users/register"} class="text-primary hover:text-primary/80 underline transition-colors">
                Sign up
              </.link>
            </p>

            <!-- Form -->
            <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore" class="space-y-6">
              <!-- Email Field -->
              <div>
                <label for="email" class="font-headline block text-sm text-primary/90 mb-2 tracking-wide">
                  Email
                </label>
                <.input
                  field={@form[:email]}
                  type="email"
                  id="email"
                  placeholder="your@email.com"
                  required
                  class="font-body w-full px-4 py-3 bg-background/50 border-2 border-border/50 text-foreground placeholder:text-foreground/40 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all duration-300"
                />
              </div>

              <!-- Password Field -->
              <div>
                <label for="password" class="font-headline block text-sm text-primary/90 mb-2 tracking-wide">
                  Password
                </label>
                <.input
                  field={@form[:password]}
                  type="password"
                  id="password"
                  placeholder="••••••••"
                  required
                  class="font-body w-full px-4 py-3 bg-background/50 border-2 border-border/50 text-foreground placeholder:text-foreground/40 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all duration-300"
                />
              </div>

              <!-- Keep me logged in & Forgot password -->
              <div class="flex items-center justify-between">
                <label class="flex items-center gap-2 cursor-pointer group">
                  <.input
                    field={@form[:remember_me]}
                    type="checkbox"
                    class="w-4 h-4 bg-background/50 border-2 border-border/50 text-primary focus:ring-2 focus:ring-primary/20 focus:outline-none cursor-pointer"
                  />
                  <span class="font-body text-sm text-foreground/70 group-hover:text-foreground transition-colors ml-[-1.5rem]">
                    Keep me logged in
                  </span>
                </label>

                <.link href={~p"/users/reset_password"} class="font-body text-sm text-primary hover:text-primary/80 underline transition-colors">
                  Forgot your password?
                </.link>
              </div>

              <!-- Submit Button -->
              <div class="pt-2">
                <button
                  type="submit"
                  class="font-headline w-full px-6 py-3 bg-primary text-background hover:bg-primary/90 border-2 border-primary hover:border-primary/80 transition-all duration-300 text-lg tracking-wide shadow-lg hover:shadow-xl hover:shadow-primary/30"
                >
                  Log in →
                </button>
              </div>
            </.form>

            <!-- Bottom decorative element -->
            <div class="flex items-center justify-center mt-8">
              <div class="h-px bg-border/30 w-20"></div>
              <svg class="w-5 h-5 mx-3 text-primary/40" viewBox="0 0 24 24" fill="currentColor">
                <circle cx="12" cy="12" r="3" />
              </svg>
              <div class="h-px bg-border/30 w-20"></div>
            </div>
          </div>
        </div>

        <!-- Decorative bottom border -->
        <div class="flex items-center justify-center mt-8">
          <div class="h-px bg-border/30 flex-1"></div>
          <svg class="w-6 h-6 mx-4 text-primary/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 2L2 7L12 12L22 7L12 2Z" />
            <path d="M2 17L12 22L22 17" />
            <path d="M2 12L12 17L22 12" />
          </svg>
          <div class="h-px bg-border/30 flex-1"></div>
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
