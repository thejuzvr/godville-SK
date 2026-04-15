defmodule GodvilleSk.Repo.Migrations.AddBodyPartsSystem do
  use Ecto.Migration

  def up do
    execute(
      "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS body_parts jsonb DEFAULT '{\"left_arm\": \"healthy\", \"right_arm\": \"healthy\", \"left_leg\": \"healthy\", \"right_leg\": \"healthy\", \"head\": \"healthy\"}'::jsonb NOT NULL"
    )

    execute(
      "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS permanent_injuries INTEGER DEFAULT 0 NOT NULL"
    )

    execute("CREATE INDEX IF NOT EXISTS index_heroes_body_parts ON heroes USING GIN (body_parts)")
  end

  def down do
    execute("DROP INDEX IF EXISTS index_heroes_body_parts")

    alter table(:heroes) do
      remove(:body_parts)
      remove(:permanent_injuries)
    end
  end
end
