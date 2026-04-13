defmodule GodvilleSk.Repo.Migrations.AddDiceThemeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :dice_theme, :string, default: "default"
    end
  end
end
