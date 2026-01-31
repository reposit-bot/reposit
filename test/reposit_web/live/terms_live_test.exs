defmodule RepositWeb.TermsLiveTest do
  use RepositWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "TermsLive" do
    test "renders terms of service page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/terms")

      assert html =~ "Terms of Service"
      assert html =~ "Service Description"
      assert html =~ "User Accounts"
      assert html =~ "Content and Contributions"
      assert html =~ "Limitation of Liability"
    end
  end
end
