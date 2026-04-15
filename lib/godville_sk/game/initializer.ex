defmodule GodvilleSk.Game.Initializer do
  @moduledoc """
  Starts all heroes from the database on application startup.
  """
  use GenServer
  require Logger
  alias GodvilleSk.Game

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Perform the startup in handle_continue to avoid blocking the supervision tree
    {:ok, state, {:continue, :start_heroes}}
  end

  @impl true
  def handle_continue(:start_heroes, state) do
    heroes = Game.list_heroes()
    Logger.info("[Initializer] Found #{length(heroes)} heroes in database. Booting engine...")

    Enum.each(heroes, fn hero ->
      case Game.ensure_hero_running(hero) do
        {:ok, _pid} ->
          # Success log handled by Hero init
          nil

        {:error, reason} ->
          Logger.error("[Initializer] Failed to start hero '#{hero.name}': #{inspect(reason)}")
      end
    end)

    Logger.info("[Initializer] Startup complete. All heroes are active.")
    {:noreply, state}
  end
end
