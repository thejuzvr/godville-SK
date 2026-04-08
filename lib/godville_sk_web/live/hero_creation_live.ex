defmodule GodvilleSkWeb.HeroCreationLive do
  use GodvilleSkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-[calc(100vh-80px)] flex items-center justify-center p-4">
      <div class="max-w-3xl w-full">
        <!-- Decorative top border -->
        <div class="flex items-center justify-center mb-8">
          <div class="h-px bg-border/30 flex-1"></div>
          <svg class="w-8 h-8 mx-4 text-primary/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" />
          </svg>
          <div class="h-px bg-border/30 flex-1"></div>
        </div>

        <!-- Main content card -->
        <div class="bg-card border border-border/50 shadow-2xl p-8 md:p-12 relative overflow-hidden">
          <!-- Decorative corner elements -->
          <div class="absolute top-0 left-0 w-24 h-24 border-l-2 border-t-2 border-primary/20"></div>
          <div class="absolute top-0 right-0 w-24 h-24 border-r-2 border-t-2 border-primary/20"></div>
          <div class="absolute bottom-0 left-0 w-24 h-24 border-l-2 border-b-2 border-primary/20"></div>
          <div class="absolute bottom-0 right-0 w-24 h-24 border-r-2 border-b-2 border-primary/20"></div>

          <div class="relative z-10">
            <!-- Title -->
            <h1 class="font-headline text-3xl md:text-5xl text-center text-primary mb-3 tracking-wider">
              HERO CREATION
            </h1>
            <div class="flex items-center justify-center mb-10">
              <div class="h-px bg-primary/40 w-20"></div>
              <p class="font-body text-sm md:text-base text-center text-foreground/70 mx-4 italic">
                Forge Your Destiny
              </p>
              <div class="h-px bg-primary/40 w-20"></div>
            </div>

            <!-- Form -->
            <.form for={@form} id="hero_creation_form" phx-submit="save" class="space-y-8 max-w-xl mx-auto">
              <!-- Name Field -->
              <div>
                <label for="hero-name" class="font-headline block text-lg text-primary/90 mb-3 tracking-wide">
                  Hero Name
                </label>
                <.input
                  field={@form[:name]}
                  type="text"
                  id="hero-name"
                  placeholder="Enter your name..."
                  required
                  class="font-body w-full px-4 py-3 bg-background/50 border-2 border-border/50 text-foreground placeholder:text-foreground/40 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all duration-300"
                />
              </div>

              <!-- Race Selection -->
              <div>
                <label for="hero-race" class="font-headline block text-lg text-primary/90 mb-3 tracking-wide">
                  Race
                </label>
                <div class="relative">
                  <.input
                    field={@form[:race]}
                    type="select"
                    id="hero-race"
                    options={["Imperial", "Nord", "Breton", "Redguard", "Altmer", "Bosmer", "Dunmer", "Orsimer", "Khajiit", "Argonian"]}
                    prompt="Select your race..."
                    required
                    class="font-body w-full px-4 py-3 bg-background/50 border-2 border-border/50 text-foreground focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all duration-300 appearance-none cursor-pointer"
                  />
                  <!-- Custom dropdown arrow -->
                  <svg class="absolute right-4 top-[2.2rem] -translate-y-1/2 w-5 h-5 text-primary/60 pointer-events-none" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M6 9L12 15L18 9" />
                  </svg>
                </div>
              </div>

              <!-- Class Selection -->
              <div>
                <label for="hero-class" class="font-headline block text-lg text-primary/90 mb-3 tracking-wide">
                  Class
                </label>
                <div class="relative">
                  <.input
                    field={@form[:class]}
                    type="select"
                    id="hero-class"
                    options={["Warrior", "Mage", "Thief", "Assassin", "Knight"]}
                    prompt="Select your class..."
                    required
                    class="font-body w-full px-4 py-3 bg-background/50 border-2 border-border/50 text-foreground focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all duration-300 appearance-none cursor-pointer"
                  />
                  <!-- Custom dropdown arrow -->
                  <svg class="absolute right-4 top-[2.2rem] -translate-y-1/2 w-5 h-5 text-primary/60 pointer-events-none" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M6 9L12 15L18 9" />
                  </svg>
                </div>
              </div>

              <!-- Submit Button -->
              <div class="pt-4">
                <button
                  type="submit"
                  class="font-headline w-full px-8 py-4 bg-primary text-background hover:bg-primary/90 border-2 border-primary hover:border-primary/80 transition-all duration-300 text-lg tracking-wide shadow-lg hover:shadow-xl hover:shadow-primary/30"
                >
                  Begin Journey
                </button>
              </div>
            </.form>

            <!-- Bottom decorative element -->
            <div class="flex items-center justify-center mt-10">
              <div class="h-px bg-border/30 w-24"></div>
              <svg class="w-6 h-6 mx-3 text-primary/40" viewBox="0 0 24 24" fill="currentColor">
                <circle cx="12" cy="12" r="3" />
              </svg>
              <div class="h-px bg-border/30 w-24"></div>
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
    {:ok, assign(socket, form: to_form(%{}, as: "hero"))}
  end

  def handle_event("save", %{"hero" => _hero_params}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/dashboard")}
  end
end
