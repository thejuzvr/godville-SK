# GodvilleSk - Elder Scrolls Zero-Player RPG

## Project Overview

A Phoenix LiveView web application implementing a "zero-player" RPG game inspired by Godville, themed around The Elder Scrolls universe. Users can register, create a hero (choosing name, race, and class), and watch their hero automatically embark on adventures.

## Tech Stack

- **Language**: Elixir (~> 1.14)
- **Framework**: Phoenix (~> 1.7) with Phoenix LiveView (~> 0.19)
- **Database**: PostgreSQL via Ecto (~> 3.10)
- **Styling**: Tailwind CSS (~> 3.4) with Heroicons v2.1.1
- **Assets**: esbuild (~> 0.17) for JavaScript bundling
- **HTTP Server**: Cowboy via plug_cowboy (~> 2.5)
- **Auth**: bcrypt_elixir for password hashing

## Project Structure

```
lib/
  godville_sk/          # Business logic (contexts)
    accounts/           # User auth (User, UserToken, UserNotifier)
    game/               # Game logic (Hero schema)
    application.ex      # OTP Application supervisor
    mailer.ex           # Swoosh mailer
    repo.ex             # Ecto repository
  godville_sk_web/      # Web layer
    live/               # Phoenix LiveView modules
      dashboard_live.ex
      hero_creation_live.ex
      user_*_live.ex    # Auth LiveViews
    controllers/        # HTTP controllers
    components/         # Reusable UI components
    router.ex           # Route definitions
    endpoint.ex         # Phoenix endpoint
assets/                 # Frontend source files
  css/app.css
  js/app.js
  tailwind.config.js
priv/
  repo/migrations/      # Database migrations
  static/assets/        # Compiled CSS and JS
config/
  config.exs            # Base configuration
  dev.exs               # Dev config (port 5000, 0.0.0.0)
  prod.exs              # Production config
  runtime.exs           # Runtime/env var config
```

## Development Setup

The app runs on **port 5000** bound to **0.0.0.0** for Replit preview compatibility.

### Key Configuration Changes Made for Replit
1. `config/dev.exs`: Changed port from 4000 to 5000, IP from `{127,0,0,1}` to `{0,0,0,0}`
2. `config/dev.exs`: Database uses `DATABASE_URL` env var (Replit PostgreSQL)
3. `config/config.exs`: Removed `Bandit.PhoenixAdapter` (not in deps; uses Cowboy instead)
4. `lib/godville_sk/application.ex`: Removed `Finch` child (not needed in dev; not in deps)
5. `mix.exs`: Added `heroicons` GitHub dependency (required by tailwind.config.js)

### Run Commands
- **Start server**: `mix phx.server`
- **Install deps + setup DB + build assets**: `mix setup`
- **Run migrations**: `mix ecto.migrate`
- **Build assets**: `mix assets.build`

## Database

Uses Replit's built-in PostgreSQL. Connection configured via `DATABASE_URL` environment variable.

**Tables**:
- `users` - User accounts (email, hashed_password, confirmed_at)
- `users_tokens` - Auth tokens
- `heroes` - Hero profiles (name, race, class, level, hp, gold, exp, attributes)

## Workflow

- **Start application**: `mix phx.server` on port 5000 (webview)
