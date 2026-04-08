defmodule GodvilleSkWeb.DashboardLive do
  use GodvilleSkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-[calc(100vh-80px)] p-4 md:p-8">
      <div class="max-w-7xl mx-auto">
        <!-- Page Title -->
        <div class="mb-8">
          <div class="flex items-center justify-center mb-4">
            <div class="h-px bg-border/30 flex-1"></div>
            <h1 class="font-headline text-3xl md:text-4xl text-primary mx-6 tracking-wider">
              DASHBOARD
            </h1>
            <div class="h-px bg-border/30 flex-1"></div>
          </div>
        </div>

        <!-- Two Column Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <!-- Hero Stats Card -->
          <div class="bg-card border border-border/50 shadow-xl p-6 relative">
            <!-- Decorative corners -->
            <div class="absolute top-0 left-0 w-16 h-16 border-l-2 border-t-2 border-primary/20"></div>
            <div class="absolute top-0 right-0 w-16 h-16 border-r-2 border-t-2 border-primary/20"></div>
            <div class="absolute bottom-0 left-0 w-16 h-16 border-l-2 border-b-2 border-primary/20"></div>
            <div class="absolute bottom-0 right-0 w-16 h-16 border-r-2 border-b-2 border-primary/20"></div>

            <div class="relative z-10">
              <h2 class="font-headline text-2xl text-primary mb-6 tracking-wide text-center">
                Hero Stats
              </h2>

              <div class="space-y-4 font-body">
                <div class="flex justify-between items-center border-b border-border/30 pb-3">
                  <span class="text-foreground/70">Level:</span>
                  <span class="text-primary font-headline text-xl">1</span>
                </div>

                <div class="flex justify-between items-center border-b border-border/30 pb-3">
                  <span class="text-foreground/70">HP:</span>
                  <span class="text-foreground">
                    <span class="text-primary font-headline">100</span>
                    <span class="text-foreground/50"> / 100</span>
                  </span>
                </div>

                <div class="flex justify-between items-center border-b border-border/30 pb-3">
                  <span class="text-foreground/70">Gold:</span>
                  <span class="text-primary font-headline text-xl">0</span>
                </div>

                <div class="flex justify-between items-center border-b border-border/30 pb-3">
                  <span class="text-foreground/70">Race:</span>
                  <span class="text-foreground">Khajiit</span>
                </div>

                <div class="flex justify-between items-center">
                  <span class="text-foreground/70">Class:</span>
                  <span class="text-foreground">Thief</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Inventory Card -->
          <div class="bg-card border border-border/50 shadow-xl p-6 relative">
            <!-- Decorative corners -->
            <div class="absolute top-0 left-0 w-16 h-16 border-l-2 border-t-2 border-primary/20"></div>
            <div class="absolute top-0 right-0 w-16 h-16 border-r-2 border-t-2 border-primary/20"></div>
            <div class="absolute bottom-0 left-0 w-16 h-16 border-l-2 border-b-2 border-primary/20"></div>
            <div class="absolute bottom-0 right-0 w-16 h-16 border-r-2 border-b-2 border-primary/20"></div>

            <div class="relative z-10">
              <h2 class="font-headline text-2xl text-primary mb-6 tracking-wide text-center">
                Inventory
              </h2>

              <div class="space-y-3 font-body">
                <div class="flex items-center gap-3 p-3 bg-background/30 border border-border/30 hover:border-primary/30 transition-colors">
                  <svg class="w-5 h-5 text-primary/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 7L12 3L4 7M20 7L12 11M20 7V17L12 21M12 11L4 7M12 11V21M4 7V17L12 21" />
                  </svg>
                  <span class="text-foreground">Iron Sword</span>
                </div>

                <div class="flex items-center gap-3 p-3 bg-background/30 border border-border/30 hover:border-primary/30 transition-colors">
                  <svg class="w-5 h-5 text-primary/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 7L12 3L4 7M20 7L12 11M20 7V17L12 21M12 11L4 7M12 11V21M4 7V17L12 21" />
                  </svg>
                  <span class="text-foreground">Sweetroll</span>
                </div>

                <div class="flex items-center gap-3 p-3 bg-background/30 border border-border/30 hover:border-primary/30 transition-colors">
                  <svg class="w-5 h-5 text-primary/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 7L12 3L4 7M20 7L12 11M20 7V17L12 21M12 11L4 7M12 11V21M4 7V17L12 21" />
                  </svg>
                  <span class="text-foreground">Leather Boots</span>
                </div>

                <div class="flex items-center gap-3 p-3 bg-background/30 border border-border/30 hover:border-primary/30 transition-colors">
                  <svg class="w-5 h-5 text-primary/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 7L12 3L4 7M20 7L12 11M20 7V17L12 21M12 11L4 7M12 11V21M4 7V17L12 21" />
                  </svg>
                  <span class="text-foreground">Health Potion</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Adventure Journal Card (Full Width) -->
        <div class="bg-card border border-border/50 shadow-xl p-6 relative">
          <!-- Decorative corners -->
          <div class="absolute top-0 left-0 w-16 h-16 border-l-2 border-t-2 border-primary/20"></div>
          <div class="absolute top-0 right-0 w-16 h-16 border-r-2 border-t-2 border-primary/20"></div>
          <div class="absolute bottom-0 left-0 w-16 h-16 border-l-2 border-b-2 border-primary/20"></div>
          <div class="absolute bottom-0 right-0 w-16 h-16 border-r-2 border-b-2 border-primary/20"></div>

          <div class="relative z-10">
            <h2 class="font-headline text-2xl text-primary mb-6 tracking-wide text-center">
              Adventure Journal
            </h2>

            <!-- Scrollable Log Area -->
            <div class="bg-background/30 border border-border/30 p-4 max-h-64 overflow-y-auto font-body text-sm leading-relaxed">
              <div class="space-y-2">
                <p class="text-foreground/80">
                  <span class="text-primary/70 font-headline">[12:00]</span> You entered the dungeon.
                </p>
                <p class="text-foreground/80">
                  <span class="text-primary/70 font-headline">[12:05]</span> Found 10 gold.
                </p>
                <p class="text-foreground/80">
                  <span class="text-primary/70 font-headline">[12:10]</span> Encountered a bandit. Battle begins!
                </p>
                <p class="text-foreground/80">
                  <span class="text-primary/70 font-headline">[12:12]</span> Defeated the bandit. Gained 25 experience.
                </p>
                <p class="text-foreground/80">
                  <span class="text-primary/70 font-headline">[12:15]</span> Found a rusty key in a chest.
                </p>
                <p class="text-foreground/80">
                  <span class="text-primary/70 font-headline">[12:20]</span> Discovered a hidden passage.
                </p>
                <p class="text-foreground/80">
                  <span class="text-primary/70 font-headline">[12:25]</span> Your torch flickers in the darkness...
                </p>
              </div>
            </div>

            <!-- Bottom decorative element -->
            <div class="flex items-center justify-center mt-6">
              <div class="h-px bg-border/30 w-24"></div>
              <svg class="w-6 h-6 mx-3 text-primary/40" viewBox="0 0 24 24" fill="currentColor">
                <circle cx="12" cy="12" r="3" />
              </svg>
              <div class="h-px bg-border/30 w-24"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
