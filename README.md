# GodvilleSk

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Docker Deployment

This project is prepared for deployment via Docker and Docker Compose.

### 1. Preparation
Create a `.env` file from the provided template:
```bash
cp .env.example .env
```

### 2. Configuration
Open the `.env` file and set the required variables:
- `SECRET_KEY_BASE`: Generate one with `mix phx.gen.secret`.
- `PHX_HOST`: Set to your domain (e.g., `skyrim.msdot.ru`).
- `DB_PASSWORD`: Set a strong password for the database.

### 3. Build and Run
To build the image and start the full stack (App + PostgreSQL):
```bash
docker compose up --build -d
```

### 4. Useful Commands
- **Check Status**: `docker compose ps`
- **View Logs**: `docker compose logs -f app`
- **Run Migrations Manually** (if needed): `docker compose exec app /app/bin/migrate`
- **Interactive Console (IEx)**: `docker compose exec app /app/bin/godville_sk remote`

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
