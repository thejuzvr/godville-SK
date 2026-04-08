defmodule GodvilleSkWeb.UserRegistrationLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Accounts
  alias GodvilleSk.Accounts.User

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
              Register for an account
            </h1>

            <!-- Log in link -->
            <p class="font-body text-center text-foreground/70 mb-8">
              Already have an account?
              <.link navigate={~p"/users/log_in"} class="text-primary hover:text-primary/80 underline transition-colors">
                Log in
              </.link>
            </p>

            <!-- Form -->
            <.form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              phx-trigger-action={@trigger_submit}
              action={~p"/users/log_in?_action=registered"}
              method="post"
              class="space-y-6"
            >
              <.error :if={@check_errors}>
                Oops, something went wrong! Please check the errors below.
              </.error>

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

              <!-- Submit Button -->
              <div class="pt-2">
                <button
                  type="submit"
                  phx-disable-with="Creating account..."
                  class="font-headline w-full px-6 py-3 bg-primary text-background hover:bg-primary/90 border-2 border-primary hover:border-primary/80 transition-all duration-300 text-lg tracking-wide shadow-lg hover:shadow-xl hover:shadow-primary/30"
                >
                  Create an account
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
