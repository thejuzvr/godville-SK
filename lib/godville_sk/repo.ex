defmodule GodvilleSk.Repo do
  use Ecto.Repo,
    otp_app: :godville_sk,
    adapter: Ecto.Adapters.Postgres
end
