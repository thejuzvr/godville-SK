defmodule GodvilleSk.Repo.Migrations.NormalizeHeroesSchema do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS stamina INTEGER DEFAULT 100 NOT NULL"
    execute "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS stamina_max INTEGER DEFAULT 100 NOT NULL"
    execute "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS luck_modifier INTEGER DEFAULT 0 NOT NULL"

    execute "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS inventory VARCHAR[] DEFAULT '{}' NOT NULL"

    execute "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS location VARCHAR DEFAULT 'Балмора' NOT NULL"

    execute "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS quest_progress INTEGER DEFAULT 0 NOT NULL"

    execute "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS turn VARCHAR DEFAULT 'hero' NOT NULL"
    execute "ALTER TABLE heroes ADD COLUMN IF NOT EXISTS respawn_at TIMESTAMP"

    execute "CREATE INDEX IF NOT EXISTS index_heroes_on_status ON heroes (status)"
  end

  def down do
    execute "DROP INDEX IF EXISTS index_heroes_on_status"

    alter table(:heroes) do
      remove :stamina
      remove :stamina_max
      remove :luck_modifier
      remove :inventory
      remove :location
      remove :quest_progress
      remove :turn
      remove :respawn_at
    end
  end
end
