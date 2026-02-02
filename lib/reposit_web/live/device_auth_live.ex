defmodule RepositWeb.DeviceAuthLive do
  @moduledoc """
  LiveView for device code authorization.

  Users arrive here after starting a device auth flow from CLI/MCP.
  They enter the code shown in their terminal to link their account.
  """
  use RepositWeb, :live_view

  alias Reposit.Accounts

  @impl true
  def mount(params, _session, socket) do
    # Pre-fill code from URL query param if present
    code_from_url = Map.get(params, "code", "")
    formatted_code = format_user_code(code_from_url)

    socket =
      socket
      |> assign(:page_title, "Authorize Device")
      |> assign(:referrer_policy, "no-referrer")
      |> assign(:user_code, formatted_code)
      |> assign(:error, nil)
      |> assign(:success, false)
      |> assign(:auto_submit, formatted_code != "")

    {:ok, socket}
  end

  @impl true
  def handle_info(:auto_submit, socket) do
    # Auto-submit if we have a pre-filled code and user is logged in
    if socket.assigns.auto_submit && socket.assigns.current_scope &&
         socket.assigns.current_scope.user do
      {:noreply, handle_code_submit(socket, socket.assigns.user_code)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    # Trigger auto-submit after mount if code was pre-filled
    if socket.assigns.auto_submit do
      send(self(), :auto_submit)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"user_code" => user_code}, socket) do
    # Format the code as user types (add dash after 4 chars)
    formatted = format_user_code(user_code)
    {:noreply, assign(socket, :user_code, formatted)}
  end

  @impl true
  def handle_event("submit", %{"user_code" => user_code}, socket) do
    {:noreply, handle_code_submit(socket, user_code)}
  end

  defp handle_code_submit(socket, user_code) do
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    return_to =
      if socket.assigns.user_code != "" do
        "/auth/device?code=#{socket.assigns.user_code}"
      else
        "/auth/device"
      end

    cond do
      is_nil(current_user) ->
        # User not logged in - redirect to login with return path (preserve code)
        socket
        |> put_flash(:info, "Please log in first to authorize this device.")
        |> push_navigate(to: "/users/log-in?return_to=#{URI.encode_www_form(return_to)}")

      String.length(String.replace(user_code, "-", "")) != 8 ->
        assign(socket, :error, "Please enter the complete 8-character code.")

      true ->
        case Accounts.get_device_code_by_user_code(user_code) do
          nil ->
            assign(socket, :error, "Invalid or expired code. Please check and try again.")

          device_code ->
            case Accounts.approve_device_code(device_code, current_user) do
              {:ok, _} ->
                socket
                |> assign(:success, true)
                |> assign(:error, nil)

              {:error, _} ->
                assign(socket, :error, "Failed to authorize device. Please try again.")
            end
        end
    end
  end

  defp login_url_with_return_to(user_code) do
    return_to =
      if user_code != "" do
        "/auth/device?code=#{user_code}"
      else
        "/auth/device"
      end

    "/users/log-in?return_to=#{URI.encode_www_form(return_to)}"
  end

  defp format_user_code(code) do
    # Remove any existing dashes and non-alphanumeric chars, uppercase
    clean =
      code
      |> String.upcase()
      |> String.replace(~r/[^A-Z0-9]/, "")
      |> String.slice(0, 8)

    # Add dash after 4 chars if we have more than 4
    if String.length(clean) > 4 do
      String.slice(clean, 0, 4) <> "-" <> String.slice(clean, 4, 4)
    else
      clean
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <header class="px-6 py-6 lg:px-12">
        <Layouts.navbar current_scope={@current_scope} />
      </header>

      <main class="flex flex-col items-center justify-center px-6 py-12">
        <div class="w-full max-w-md">
          <div class="text-center mb-8">
            <div class="w-16 h-16 rounded-2xl bg-primary/10 flex items-center justify-center mx-auto mb-4">
              <Lucideicons.terminal class="w-8 h-8 text-primary" />
            </div>
            <h1 class="text-2xl font-bold text-base-content">Authorize Device</h1>
            <p class="text-base-content/60 mt-2">
              Enter the code shown in your terminal to connect your account.
            </p>
          </div>

          <%= if @success do %>
            <div class="card bg-success/10 border border-success/20">
              <div class="card-body items-center text-center">
                <div class="w-12 h-12 rounded-full bg-success/20 flex items-center justify-center mb-2">
                  <Lucideicons.check class="w-6 h-6 text-success" />
                </div>
                <h2 class="card-title text-success">Device Authorized!</h2>
                <p class="text-base-content/70">
                  You can close this window and return to your terminal.
                  Your CLI/MCP tool should now be authenticated.
                </p>
              </div>
            </div>
          <% else %>
            <div class="card bg-base-200">
              <div class="card-body">
                <form phx-submit="submit" phx-change="validate" class="space-y-6">
                  <div class="flex flex-col items-center">
                    <label class="label">
                      <span class="label-text font-medium">Device Code</span>
                    </label>
                    <input
                      type="text"
                      name="user_code"
                      value={@user_code}
                      placeholder="XXXX-XXXX"
                      class={"input input-bordered input-lg text-center font-mono tracking-widest text-2xl #{if @error, do: "input-error", else: ""}"}
                      autocomplete="off"
                      autocapitalize="characters"
                      spellcheck="false"
                      maxlength="9"
                    />
                    <%= if @error do %>
                      <label class="label">
                        <span class="label-text-alt text-error">{@error}</span>
                      </label>
                    <% end %>
                  </div>

                  <%= if @current_scope && @current_scope.user do %>
                    <button type="submit" class="btn btn-primary btn-block btn-lg">
                      Authorize
                    </button>
                  <% else %>
                    <a
                      href={login_url_with_return_to(@user_code)}
                      class="btn btn-primary btn-block btn-lg"
                    >
                      Log in to Authorize
                    </a>
                  <% end %>
                </form>
              </div>
            </div>

            <div class="mt-6 text-center text-sm text-base-content/50">
              <p>The code expires in 15 minutes.</p>
              <p class="mt-1">
                Don't have the code?
                <a href={~p"/install"} class="link link-primary">Learn how to get started</a>
              </p>
            </div>
          <% end %>
        </div>
      </main>

      <Layouts.flash_group flash={@flash} />
    </div>
    """
  end
end
