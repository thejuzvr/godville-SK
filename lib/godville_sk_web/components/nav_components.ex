defmodule GodvilleSkWeb.NavComponents do
  use GodvilleSkWeb, :html

  def game_nav(assigns) do
    ~H"""
    <nav class="flex-shrink-0 bg-card border-b border-border flex items-center px-4 h-11 gap-4">
      <div class="flex items-center gap-2 mr-4">
        <svg
          class="w-5 h-5 text-primary"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.5"
        >
          <path d="M12 2L2 7v5c0 5.25 4.25 10.15 10 11.25C17.75 22.15 22 17.25 22 12V7L12 2z" />
        </svg>
        <span class="font-headline text-primary text-xs tracking-widest uppercase">Godville-SK</span>
      </div>
      <div class="flex items-center gap-1 text-xs font-headline tracking-wide h-full">
        <.nav_link href={~p"/dashboard"} active={@active_tab == :dashboard}>Основное</.nav_link>
        <.nav_link href={~p"/equipment"} active={@active_tab == :equipment}>Снаряжение</.nav_link>
        <.nav_link href={~p"/marketplace"} active={@active_tab == :marketplace}>Рынок</.nav_link>
        <.nav_link href={~p"/arena"} active={@active_tab == :arena}>Арена</.nav_link>
        <.nav_link href={~p"/analytics"} active={@active_tab == :analytics}>Аналитика</.nav_link>
        <.nav_link href={~p"/temple"} active={@active_tab == :temple}>Храм Даэдра</.nav_link>
        <.nav_link href={~p"/users/settings"} active={@active_tab == :profile}>Профиль</.nav_link>
      </div>
      <div class="ml-auto flex items-center gap-3 text-xs">
        <span class="text-foreground/50 font-body hidden sm:inline">
          Realm: <span class="text-primary">Global</span>
        </span>
        <.link
          href={~p"/users/log_out"}
          method="delete"
          class="text-foreground/50 hover:text-primary transition-colors logout-btn"
          title="Выход"
        >
          <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9" />
          </svg>
        </.link>
      </div>
    </nav>
    """
  end

  defp nav_link(assigns) do
    ~H"""
    <.link
      href={@href}
      class={[
        "px-3 h-full flex items-center transition-all border-b-2 hover:text-primary",
        @active && "text-primary border-primary bg-primary/5 font-bold",
        !@active && "text-foreground/70 border-transparent hover:border-primary/30"
      ]}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
