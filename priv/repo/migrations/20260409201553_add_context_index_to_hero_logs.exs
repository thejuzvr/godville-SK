defmodule GodvilleSk.Repo.Migrations.AddContextIndexToHeroLogs do
  use Ecto.Migration

  def up do
    execute "CREATE INDEX IF NOT EXISTS hero_logs_metadata_gin_index ON hero_logs USING GIN (metadata)"

    execute """
    CREATE INDEX IF NOT EXISTS hero_logs_context_index
    ON hero_logs ((metadata->>'context'))
    """

    execute """
    CREATE INDEX IF NOT EXISTS hero_logs_type_index
    ON hero_logs ((metadata->>'type'))
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS hero_logs_type_index"
    execute "DROP INDEX IF EXISTS hero_logs_context_index"
    execute "DROP INDEX IF EXISTS hero_logs_metadata_gin_index"
  end
end
