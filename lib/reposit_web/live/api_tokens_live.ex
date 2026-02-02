defmodule RepositWeb.ApiTokensLive do
  @moduledoc """
  Authenticated LiveView for managing API tokens: create, delete, rename.
  """
  use RepositWeb, :live_view

  alias Reposit.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:page_title, "API Tokens")
     |> assign(:api_tokens, Accounts.list_api_tokens(user))
     |> assign(:editing_token_id, nil)
     |> assign(:new_token_plaintext, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-xl space-y-6">
        <div class="text-center">
          <.header>
            API Tokens
            <:subtitle>
              Create and manage tokens for the Reposit API and MCP endpoints. You can have up to 50 tokens.
            </:subtitle>
          </.header>
        </div>

        <%= if @new_token_plaintext do %>
          <div class="alert alert-warning">
            <.icon name="alert-triangle" class="size-5" />
            <div class="flex-1">
              <p class="font-semibold">Copy your token now - it won't be shown again!</p>
              <code class="block mt-2 p-2 bg-neutral text-neutral-content rounded text-sm break-all select-all">
                {@new_token_plaintext}
              </code>
              <button
                type="button"
                class="btn btn-sm btn-outline mt-2"
                phx-click="clear_new_token"
              >
                Dismiss
              </button>
            </div>
          </div>
        <% end %>

        <div class="space-y-4">
          <form phx-submit="create" class="flex gap-2" id="create-token-form">
            <input
              type="text"
              name="name"
              placeholder="Token name (e.g., 'My Laptop')"
              class="input input-bordered flex-1"
              required
              maxlength="255"
            />
            <button type="submit" class="btn btn-primary" phx-disable-with="Creating...">
              Create Token
            </button>
          </form>

          <div class="space-y-2">
            <%= if Enum.empty?(@api_tokens) do %>
              <div class="text-sm opacity-70 p-4 bg-base-200 rounded-lg text-center">
                No API tokens yet. Create one to use the API.
              </div>
            <% else %>
              <%= for token <- @api_tokens do %>
                <div class="flex items-center justify-between gap-2 p-3 bg-base-200 rounded-lg flex-wrap">
                  <div class="flex-1 min-w-0">
                    <%= if @editing_token_id == token.id do %>
                      <form
                        phx-submit="rename"
                        phx-click-away="cancel_rename"
                        class="flex items-center gap-2 flex-wrap"
                        id={"rename-form-#{token.id}"}
                      >
                        <input type="hidden" name="token_id" value={token.id} />
                        <input
                          type="text"
                          name="name"
                          value={token.name}
                          class="input input-bordered input-sm flex-1 min-w-[120px]"
                          maxlength="255"
                        />
                        <button type="submit" class="btn btn-sm btn-primary">Save</button>
                        <button type="button" class="btn btn-sm btn-ghost" phx-click="cancel_rename">
                          Cancel
                        </button>
                      </form>
                    <% else %>
                      <div class="font-medium truncate">{token.name}</div>
                      <div class="text-xs opacity-60 mt-1 flex flex-wrap gap-x-3 gap-y-1">
                        <span>Created: {Calendar.strftime(token.inserted_at, "%b %d, %Y")}</span>
                        <span>
                          <%= if token.last_used_at do %>
                            Last used: {Calendar.strftime(token.last_used_at, "%b %d, %Y %H:%M")}
                          <% else %>
                            Never used
                          <% end %>
                        </span>
                        <span class={"badge badge-xs #{if token.source == :device_flow, do: "badge-info", else: "badge-ghost"}"}>
                          {if token.source == :device_flow, do: "Device", else: "Settings"}
                        </span>
                        <%= if token.device_name do %>
                          <span class="opacity-50">({token.device_name})</span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                  <div class="flex items-center gap-1 shrink-0">
                    <%= if @editing_token_id != token.id do %>
                      <button
                        type="button"
                        class="btn btn-sm btn-ghost"
                        phx-click="edit_rename"
                        phx-value-id={token.id}
                      >
                        Rename
                      </button>
                      <button
                        type="button"
                        class="btn btn-sm btn-ghost text-error"
                        phx-click="delete"
                        phx-value-id={token.id}
                        data-confirm="Delete this token? Any applications using it will stop working."
                      >
                        Delete
                      </button>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>

          <p class="text-xs opacity-50">{length(@api_tokens)} / 50 tokens used</p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("create", %{"name" => name}, socket) do
    user = socket.assigns.current_scope.user
    name = String.trim(name)

    socket =
      if name == "" do
        put_flash(socket, :error, "Token name can't be blank.")
      else
        case Accounts.create_api_token(user, name, :settings) do
          {:ok, plaintext, _api_token} ->
            socket
            |> put_flash(:info, "API token created. Copy it now - it won't be shown again.")
            |> assign(:new_token_plaintext, plaintext)
            |> assign(:api_tokens, Accounts.list_api_tokens(user))

          {:error, :token_limit_reached} ->
            socket
            |> put_flash(:error, "Token limit reached (50 max). Delete unused tokens first.")
            |> assign(:api_tokens, Accounts.list_api_tokens(user))

          {:error, _changeset} ->
            socket
            |> put_flash(:error, "Failed to create API token.")
            |> assign(:api_tokens, Accounts.list_api_tokens(user))
        end
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user

    socket =
      case Accounts.delete_api_token(user, id) do
        {:ok, :deleted} ->
          socket
          |> put_flash(:info, "API token deleted.")
          |> assign(:api_tokens, Accounts.list_api_tokens(user))
          |> assign(
            :editing_token_id,
            if(socket.assigns.editing_token_id == id,
              do: nil,
              else: socket.assigns.editing_token_id
            )
          )

        {:error, :not_found} ->
          put_flash(socket, :error, "Token not found.")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("rename", %{"token_id" => token_id, "name" => name}, socket) do
    user = socket.assigns.current_scope.user
    name = String.trim(name)

    socket =
      if name == "" do
        put_flash(socket, :error, "Token name can't be blank.")
      else
        case Accounts.rename_api_token(user, token_id, name) do
          {:ok, _token} ->
            socket
            |> put_flash(:info, "Token renamed.")
            |> assign(:api_tokens, Accounts.list_api_tokens(user))
            |> assign(:editing_token_id, nil)

          {:error, :not_found} ->
            socket
            |> put_flash(:error, "Token not found.")
            |> assign(:editing_token_id, nil)

          {:error, _changeset} ->
            socket
            |> put_flash(:error, "Failed to rename token.")
            |> assign(:api_tokens, Accounts.list_api_tokens(user))
            |> assign(:editing_token_id, nil)
        end
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit_rename", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_token_id, id)}
  end

  @impl true
  def handle_event("cancel_rename", _params, socket) do
    {:noreply, assign(socket, :editing_token_id, nil)}
  end

  @impl true
  def handle_event("clear_new_token", _params, socket) do
    {:noreply, assign(socket, :new_token_plaintext, nil)}
  end
end
