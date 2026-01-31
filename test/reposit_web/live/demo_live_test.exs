defmodule RepositWeb.DemoLiveTest do
  use RepositWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "DemoLive" do
    test "renders counter", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/demo")

      assert html =~ "Counter: 0"
      assert html =~ "LiveView Demo"
    end

    test "increments counter", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/demo")

      assert render_click(view, "increment") =~ "Counter: 1"
      assert render_click(view, "increment") =~ "Counter: 2"
    end

    test "decrements counter", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/demo")

      assert render_click(view, "decrement") =~ "Counter: -1"
    end
  end
end
