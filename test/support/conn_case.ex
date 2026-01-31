defmodule RepositWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use RepositWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint RepositWeb.Endpoint

      use RepositWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import RepositWeb.ConnCase
    end
  end

  setup tags do
    Reposit.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn} = context) do
    user = Reposit.AccountsFixtures.user_fixture()
    scope = Reposit.Accounts.Scope.for_user(user)

    opts =
      context
      |> Map.take([:token_authenticated_at])
      |> Enum.into([])

    %{conn: log_in_user(conn, user, opts), user: user, scope: scope}
  end

  @doc """
  Setup helper that registers and logs in an admin user.

      setup :register_and_log_in_admin

  It stores an updated connection and a registered admin user in the
  test context.
  """
  def register_and_log_in_admin(%{conn: conn} = context) do
    user = Reposit.AccountsFixtures.admin_user_fixture()
    scope = Reposit.Accounts.Scope.for_user(user)

    opts =
      context
      |> Map.take([:token_authenticated_at])
      |> Enum.into([])

    %{conn: log_in_user(conn, user, opts), user: user, scope: scope}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user, opts \\ []) do
    token = Reposit.Accounts.generate_user_session_token(user)

    maybe_set_token_authenticated_at(token, opts[:token_authenticated_at])

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  defp maybe_set_token_authenticated_at(_token, nil), do: nil

  defp maybe_set_token_authenticated_at(token, authenticated_at) do
    Reposit.AccountsFixtures.override_token_authenticated_at(token, authenticated_at)
  end

  @doc """
  Setup helper that creates a user with an API token for authenticated API requests.

      setup :create_api_user

  It stores the API token and user in the test context.
  """
  def create_api_user(_context) do
    user = Reposit.AccountsFixtures.user_fixture()
    {:ok, token, user} = Reposit.Accounts.generate_api_token(user)
    %{api_token: token, api_user: user}
  end

  @doc """
  Adds API authentication to the connection using a Bearer token.
  """
  def authenticate_api(conn, token) do
    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{token}")
  end
end
