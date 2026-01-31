defmodule RepositWeb.Plugs.Redirect do
  @moduledoc """
  A simple plug that redirects to a configured path.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> redirect(to: opts[:to])
    |> halt()
  end
end
