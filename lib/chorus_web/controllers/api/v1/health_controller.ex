defmodule ChorusWeb.Api.V1.HealthController do
  use ChorusWeb, :controller

  def index(conn, _params) do
    json(conn, %{success: true, data: %{status: "ok"}})
  end
end
