defmodule GodvilleSkWeb.HeroCreationLive do
  use GodvilleSkWeb, :live_view

  alias GodvilleSk.Game
  alias GodvilleSk.Game.Hero

  def mount(_params, _session, socket) do
    if socket.assigns.current_user do
      case Game.get_hero_by_user_id(socket.assigns.current_user.id) do
        nil ->
          changeset = Game.Hero.changeset(%Hero{}, %{})
          {:ok, assign(socket, form: to_form(changeset), page_title: "Create your Hero")}
        _hero ->
          {:ok, redirect(socket, to: "/dashboard")}
      end
    else
      {:ok, redirect(socket, to: "/users/log_in")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm mt-10">
      <.header class="text-center">
        Forge Your Destiny
        <:subtitle>Name your hero and choose your origin to begin your adventure in Oblivion.</:subtitle>
      </.header>

      <.simple_form for={@form} id="hero-creation-form" phx-submit="create_hero">
        <.input field={@form[:name]} type="text" label="Hero Name" required />

        <.input field={@form[:race]} type="select" label="Race" options={["Nord", "Dark Elf", "Imperial", "Khajiit", "Argonian", "Breton", "High Elf", "Wood Elf", "Redguard", "Orc"]} required />

        <.input field={@form[:class]} type="select" label="Class" options={["Warrior", "Mage", "Thief", "Adventurer", "Assassin", "Knight", "Spellsword"]} required />

        <:actions>
          <.button phx-disable-with="Forging..." class="w-full">
            Begin Adventure
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("create_hero", %{"hero" => hero_params}, socket) do
    user_id = socket.assigns.current_user.id
    hero_params = Map.put(hero_params, "user_id", user_id)

    case Game.create_hero(hero_params) do
      {:ok, hero} ->
        case :global.whereis_name({:hero, hero.name}) do
          :undefined ->
            {:ok, _pid} = GodvilleSk.Hero.start_link(id: hero.id, name: hero.name)
          _pid ->
            :ok
        end

        {:noreply,
         socket
         |> put_flash(:info, "Hero created successfully! Let the adventure begin.")
         |> redirect(to: "/dashboard")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
