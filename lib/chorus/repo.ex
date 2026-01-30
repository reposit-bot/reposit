defmodule Chorus.Repo do
  use Ecto.Repo,
    otp_app: :chorus,
    adapter: Ecto.Adapters.Postgres
end
