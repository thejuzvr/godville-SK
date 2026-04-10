alias GodvilleSk.Game.LogMetadata
alias GodvilleSk.Hero
alias GodvilleSk.Repo

IO.puts("\n=== Scenario 5: Metadata Validation Tests ===")

# Test valid combat roll
metadata = %{type: "combat_roll", actor: "hero", target: "enemy", roll: 10, total: 15, damage: 5, is_hit: true}
case LogMetadata.validate(metadata, :normal) do
  {:ok, normalized} -> IO.puts("✅ Valid combat_roll normalized: #{inspect(normalized)}")
  error -> IO.puts("❌ Combat_roll validation failed: #{inspect(error)}")
end

# Test invalid type
case LogMetadata.validate(%{type: "invalid_type"}, :normal) do
  {:error, {:invalid_event_type, "invalid_type"}} -> IO.puts("✅ Correctly rejected invalid type")
  other -> IO.puts("❌ Did not reject invalid type correctly: #{inspect(other)}")
end

# Test missing fields
case LogMetadata.validate(%{type: "combat_roll", actor: "hero"}, :normal) do
  {:error, {:missing_fields, "combat_roll", fields}} -> IO.puts("✅ Correctly rejected missing fields: #{inspect(fields)}")
  other -> IO.puts("❌ Did not reject missing fields correctly: #{inspect(other)}")
end

IO.puts("\n=== Scenario 6: Backward Compatibility Check ===")
# Find a log without context (if any) or check if they are handled correctly by logic
# We can simulate this by manually inserting a record and loading it

IO.puts("\n=== Starting Interactive Scenarios (1-4) ===")
# We need a hero name to test with. Let's find one.
import Ecto.Query
hero = Repo.one(from h in GodvilleSk.Game.Hero, limit: 1)

if hero do
  IO.puts("Testing with hero: #{hero.name} (LVL #{hero.level})")
  
  # Wait for hero GenServer to be registered
  wait_for_hero = fn func, retries ->
    if retries == 0 do
      nil
    else
      case GodvilleSk.Hero.get_state(hero.name) do
        nil -> 
          :timer.sleep(500)
          func.(func, retries - 1)
        state -> state
      end
    end
  end

  state = wait_for_hero.(wait_for_hero, 10)
  
  if state do
    # ... previous logic ...
    IO.puts("Current state: #{state.status} at #{state.location}")
    # ... (skipping some for brevity) ...

    # Scenario 4: Death
    IO.puts("\n--- Scenario 4: Testing Death Event ---")
    Hero.debug_update(hero.name, %{hp: 0})
    :timer.sleep(1000) 
    
    new_state = Hero.get_state(hero.name)
    death_event = Enum.find(new_state.log, fn l -> (l.metadata || %{})[:type] == "death" end)
    if death_event do
      IO.puts("✅ Death event found!")
      IO.puts("Context: #{inspect(death_event.metadata[:context])}")
    end
    
    # Scenario 3: Resurrection
    IO.puts("\n--- Scenario 3: Testing Resurrection ---")
    Hero.debug_update(hero.name, %{intervention_power: 100})
    Hero.divine_intervention(hero.name)
    :timer.sleep(1000)
    
    res_state = Hero.get_state(hero.name)
    res_event = Enum.find(res_state.log, fn l -> (l.metadata || %{})[:type] == "resurrection" end)
    if res_event do
      IO.puts("✅ Resurrection event found!")
      IO.puts("Context: #{inspect(res_event.metadata[:context])}")
    end

    IO.puts("\n=== Scenario 7: Index Performance Verification ===")
    sql = "EXPLAIN ANALYZE SELECT * FROM hero_logs WHERE metadata->>'context' = 'sovngarde'"
    {:ok, %{rows: rows}} = Ecto.Adapters.SQL.query(Repo, sql)
    IO.puts("SQL Explain Result:")
    Enum.each(rows, fn [line] -> IO.puts(line) end)

  else
    IO.puts("❌ Could not get live state for hero after retries")
  end
else
  IO.puts("❌ No heroes found in database")
end
