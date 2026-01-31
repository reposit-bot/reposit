defmodule RepositWeb.PageController do
  use RepositWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
