defmodule GodvilleSkWeb.HeroCreationLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center p-4">
      <div class="max-w-3xl w-full">
        <div class="flex items-center justify-center mb-8">
          <div class="h-px bg-border/30 flex-1"></div>
          <svg
            class="w-8 h-8 mx-4 text-primary/60"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" />
          </svg>
          <div class="h-px bg-border/30 flex-1"></div>
        </div>

        <div class="bg-card border border-border/50 shadow-2xl p-8 md:p-12 relative overflow-hidden">
          <div class="absolute top-0 left-0 w-24 h-24 border-l-2 border-t-2 border-primary/20"></div>
          <div class="absolute top-0 right-0 w-24 h-24 border-r-2 border-t-2 border-primary/20"></div>
          <div class="absolute bottom-0 left-0 w-24 h-24 border-l-2 border-b-2 border-primary/20">
          </div>
          <div class="absolute bottom-0 right-0 w-24 h-24 border-r-2 border-b-2 border-primary/20">
          </div>

          <div class="relative z-10">
            <h1 class="font-headline text-3xl md:text-5xl text-center text-primary mb-3 tracking-wider">
              СОЗДАНИЕ ГЕРОЯ
            </h1>
            <div class="flex items-center justify-center mb-10">
              <div class="h-px bg-primary/40 w-20"></div>
              <p class="font-body text-sm md:text-base text-center text-foreground/70 mx-4 italic">
                Выкуй свою судьбу
              </p>
              <div class="h-px bg-primary/40 w-20"></div>
            </div>

            <.form
              for={@form}
              id="hero_creation_form"
              phx-submit="save"
              class="space-y-8 max-w-xl mx-auto"
            >
              <div>
                <label
                  for="hero-name"
                  class="font-headline block text-lg text-primary/90 mb-3 tracking-wide"
                >
                  Имя героя
                </label>
                <.input
                  field={@form[:name]}
                  type="text"
                  id="hero-name"
                  placeholder="Введи имя..."
                  required
                  class="font-body w-full px-4 py-3 bg-background/50 border-2 border-border/50 text-foreground placeholder:text-foreground/40 focus:border-primary focus:outline-none"
                />
              </div>

              <div>
                <label
                  for="hero-race"
                  class="font-headline block text-lg text-primary/90 mb-3 tracking-wide"
                >
                  Раса
                </label>
                <div class="relative">
                  <.input
                    field={@form[:race]}
                    type="select"
                    id="hero-race"
                    options={[
                      "Имперец",
                      "Норд",
                      "Бретонец",
                      "Редгард",
                      "Альтмер",
                      "Босмер",
                      "Данмер",
                      "Орсимер",
                      "Каджит",
                      "Аргонианин"
                    ]}
                    prompt="Выбери расу..."
                    required
                    class="font-body w-full px-4 py-3 bg-background/50 border-2 border-border/50 text-foreground focus:border-primary focus:outline-none appearance-none cursor-pointer"
                  />
                  <svg
                    class="absolute right-4 top-[2.2rem] -translate-y-1/2 w-5 h-5 text-primary/60 pointer-events-none"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                  >
                    <path d="M6 9L12 15L18 9" />
                  </svg>
                </div>
              </div>

              <div>
                <label
                  for="hero-class"
                  class="font-headline block text-lg text-primary/90 mb-3 tracking-wide"
                >
                  Класс
                </label>
                <div class="relative">
                  <.input
                    field={@form[:class]}
                    type="select"
                    id="hero-class"
                    options={["Воин", "Маг", "Вор", "Убийца", "Рыцарь"]}
                    prompt="Выбери класс..."
                    required
                    class="font-body w-full px-4 py-3 bg-background/50 border-2 border-border/50 text-foreground focus:border-primary focus:outline-none appearance-none cursor-pointer"
                  />
                  <svg
                    class="absolute right-4 top-[2.2rem] -translate-y-1/2 w-5 h-5 text-primary/60 pointer-events-none"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                  >
                    <path d="M6 9L12 15L18 9" />
                  </svg>
                </div>
              </div>

              <div
                :if={@error}
                class="p-3 bg-destructive/20 border border-destructive/50 text-destructive-foreground text-sm font-body"
              >
                {@error}
              </div>

              <div class="pt-4">
                <button
                  type="submit"
                  phx-disable-with="Создаём героя..."
                  class="font-headline w-full px-8 py-4 bg-primary text-background hover:bg-primary/90 border-2 border-primary transition-all duration-300 text-lg tracking-wide shadow-lg"
                >
                  Начать странствие
                </button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    case Game.get_hero_by_user_id(user.id) do
      nil ->
        {:ok, assign(socket, form: to_form(%{}, as: "hero"), error: nil)}

      _hero ->
        {:ok, push_navigate(socket, to: ~p"/dashboard")}
    end
  end

  def handle_event("save", %{"hero" => hero_params}, socket) do
    user = socket.assigns.current_user

    attrs = %{
      name: hero_params["name"],
      race: hero_params["race"],
      class: hero_params["class"],
      level: 1,
      hp: 100,
      max_hp: 100,
      exp: 0,
      gold: 100,
      perks: [],
      user_id: user.id,
      attributes: %{
        "strength" => 50,
        "intelligence" => 50,
        "willpower" => 50,
        "agility" => 50,
        "speed" => 50,
        "endurance" => 50,
        "personality" => 50,
        "luck" => 50
      }
    }

    case Game.create_hero(attrs) do
      {:ok, hero} ->
        Game.ensure_hero_running(hero)
        {:noreply, push_navigate(socket, to: ~p"/dashboard")}

      {:error, _changeset} ->
        {:noreply, assign(socket, error: "Не удалось создать героя. Проверь введённые данные.")}
    end
  end
end
