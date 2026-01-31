defmodule RepositWeb.Api.V1.HealthController do
  use RepositWeb, :controller

  def index(conn, _params) do
    json(conn, %{success: true, data: %{status: "ok"}})
  end
end
