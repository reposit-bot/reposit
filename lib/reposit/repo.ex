defmodule Reposit.Repo do
  use Ecto.Repo,
    otp_app: :reposit,
    adapter: Ecto.Adapters.Postgres
end
