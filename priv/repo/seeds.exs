# Script for populating the database with initial game content.
#
# Run as: mix run priv/repo/seeds.exs

alias GodvilleSk.Repo
alias GodvilleSk.Accounts
alias GodvilleSk.Accounts.User
alias GodvilleSk.Game
alias GodvilleSk.Game.{Hero, Items}
alias GodvilleSk.Game.ContentEntry

IO.puts("Seeding database...")

# Create demo user if not exists
demo_user =
  case Repo.get_by(User, email: "god@demo.dev") do
    nil ->
      {:ok, user} =
        Accounts.register_user(%{
          email: "god@demo.dev",
          password: "demo_password_123",
          name: "Божество"
        })

      user

    user ->
      IO.puts("Demo user already exists")
      user
  end

# Create demo hero if not exists for user
demo_hero = Game.get_hero_by_user_id(demo_user.id)

if !demo_hero do
  {:ok, hero} =
    Game.create_hero(%{
      user_id: demo_user.id,
      name: "Торик Девятизвон",
      race: "Норд",
      class: "Воин",
      level: 1,
      gold: 50,
      xp: 0,
      hp: 100,
      max_hp: 100,
      exp: 0,
      location: "Балмора",
      intervention_power: 100,
      stamina: 100,
      stamina_max: 100,
      perks: [],
      attributes: %{
        strength: 50,
        intelligence: 50,
        willpower: 50,
        agility: 50,
        speed: 50,
        endurance: 50,
        personality: 50,
        luck: 50
      }
    })

  IO.puts("Created demo hero: #{hero.name}")
else
  IO.puts("Demo hero already exists: #{demo_hero.name}")
end

IO.puts("Using GodvilleSk.Game.Items helper module for item definitions")

IO.puts(
  "Available items: #{length(Items.get_weapons())} weapons, #{length(Items.get_armor_pieces())} armor pieces"
)

# Create sample locations
locations = [
  "Балмора",
  "Солитьютд",
  "Винтерхолд",
  "Ривервуд",
  "Имперский город",
  "Чейдинхолл",
  "Маркарт",
  "Унковер"
]

Enum.each(locations, fn location_name ->
  case Repo.get_by(ContentEntry, kind: "location", key: String.downcase(location_name)) do
    nil ->
      %ContentEntry{}
      |> ContentEntry.changeset(%{
        kind: "location",
        key: String.downcase(location_name),
        payload: %{"name" => location_name},
        active: true
      })
      |> Repo.insert!()

      IO.puts("Created location: #{location_name}")

    entry ->
      IO.puts("Location already exists: #{location_name}")
  end
end)

# Create sample monsters
monsters = [
  %{name: "Грязевой краб", level: 1, hp: 10, damage: 1},
  %{name: "Злокрыс", level: 1, hp: 15, damage: 2},
  %{name: "Волк", level: 1, hp: 20, damage: 3},
  %{name: "Скелет", level: 2, hp: 25, damage: 4},
  %{name: "Бандит", level: 3, hp: 45, damage: 6}
]

Enum.each(monsters, fn monster_attrs ->
  key = String.downcase(monster_attrs.name)

  case Repo.get_by(ContentEntry, kind: "monster", key: key) do
    nil ->
      %ContentEntry{}
      |> ContentEntry.changeset(%{
        kind: "monster",
        key: key,
        payload: Map.put(monster_attrs, :id, key),
        active: true
      })
      |> Repo.insert!()

      IO.puts("Created monster: #{monster_attrs.name}")

    entry ->
      IO.puts("Monster already exists: #{monster_attrs.name}")
  end
end)

IO.puts("Seeding complete!")
