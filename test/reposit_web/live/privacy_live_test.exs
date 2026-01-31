defmodule RepositWeb.PrivacyLiveTest do
  use RepositWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "PrivacyLive" do
    test "renders privacy policy page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/privacy")

      assert html =~ "Privacy Policy"
      assert html =~ "Information We Collect"
      assert html =~ "How We Use Your Information"
      assert html =~ "Third-Party Services"
      assert html =~ "Your Rights"
    end
  end
end
