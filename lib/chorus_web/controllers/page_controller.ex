defmodule ChorusWeb.PageController do
  use ChorusWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
