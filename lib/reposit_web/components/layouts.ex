defmodule RepositWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use RepositWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates("layouts/*")

  @doc """
  Reusable navigation bar component with desktop and mobile menus.
  """
  attr :current_scope, :map, default: nil
  attr :class, :string, default: ""

  def navbar(assigns) do
    ~H"""
    <nav class={"flex items-center justify-between mx-auto #{@class}"}>
      <a href="/" class="flex items-center gap-2 group">
        <img src={~p"/images/logo.png"} alt="Reposit" class="w-9 h-9" />
        <span class="text-lg font-bold tracking-tight text-base-content">
          Reposit
        </span>
      </a>
      
    <!-- Desktop navigation -->
      <div class="hidden md:flex items-center gap-1">
        <a
          href={~p"/"}
          class="px-4 py-2 text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-200 rounded-xl transition-all"
        >
          Home
        </a>
        <a
          href={~p"/install"}
          class="px-4 py-2 text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-200 rounded-xl transition-all"
        >
          Install
        </a>
        <a
          href={~p"/solutions"}
          class="px-4 py-2 text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-200 rounded-xl transition-all"
        >
          Browse
        </a>
        <a
          href={~p"/search"}
          class="px-4 py-2 text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-200 rounded-xl transition-all"
        >
          Search
        </a>

        <div class="h-5 w-px bg-base-300 mx-2"></div>

        <%= if @current_scope do %>
          <a
            href={~p"/users/settings"}
            class="px-4 py-2 text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-200 rounded-xl transition-all"
          >
            Settings
          </a>
          <a
            href={~p"/users/api-tokens"}
            class="px-4 py-2 text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-200 rounded-xl transition-all"
          >
            API Tokens
          </a>
          <.link
            href={~p"/users/log-out"}
            method="delete"
            class="px-4 py-2 text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-200 rounded-xl transition-all"
          >
            Log out
          </.link>
        <% else %>
          <a
            href={~p"/users/log-in"}
            class="px-4 py-2 text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-200 rounded-xl transition-all"
          >
            Sign in
          </a>
        <% end %>

        <div class="ml-2">
          <.theme_toggle />
        </div>
      </div>
      
    <!-- Mobile menu dropdown -->
      <div class="dropdown dropdown-end md:hidden">
        <div
          tabindex="0"
          role="button"
          class="btn btn-ghost btn-sm p-2"
        >
          <Lucideicons.menu class="size-5 text-base-content/70" />
        </div>
        <ul
          tabindex="0"
          class="dropdown-content menu bg-base-100 rounded-box z-50 w-56 p-2 shadow-xl border border-base-200 mt-2"
        >
          <li><a href={~p"/"}>Home</a></li>
          <li><a href={~p"/install"}>Install</a></li>
          <li><a href={~p"/solutions"}>Browse Solutions</a></li>
          <li><a href={~p"/search"}>Search</a></li>
          <li class="mt-2 pt-2 border-t border-base-200">
            <%= if @current_scope do %>
              <a href={~p"/users/settings"}>Settings</a>
              <a href={~p"/users/api-tokens"}>API Tokens</a>
            <% end %>
          </li>
          <%= if @current_scope do %>
            <li>
              <.link href={~p"/users/log-out"} method="delete">Log out</.link>
            </li>
          <% else %>
            <li>
              <a href={~p"/users/log-in"}>Sign in</a>
            </li>
          <% end %>
          <li class="mt-2 pt-2 border-t border-base-200">
            <div class="flex justify-center py-1">
              <.theme_toggle />
            </div>
          </li>
        </ul>
      </div>
    </nav>
    """
  end

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  attr(:current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"
  )

  slot(:inner_block, required: true)

  def app(assigns) do
    ~H"""
    <div class="reposit-page min-h-screen flex flex-col">
      <div class="page-bg"></div>

      <header class="relative z-50 px-6 py-6 lg:px-12 border-b border-base-300">
        <.navbar current_scope={@current_scope} />
      </header>

      <main class="flex-1 px-6 py-10 lg:px-12">
        <div class="mx-auto max-w-7xl">
          {render_slot(@inner_block)}
        </div>
      </main>

      <.site_footer />

      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="loader-2" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="loader-2" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Shared site footer with navigation, GitHub links, and legal pages.
  Mobile-first responsive design.
  """
  def site_footer(assigns) do
    ~H"""
    <footer class="relative z-10 px-6 lg:px-12 py-12 border-t border-base-300 bg-base-100/50">
      <div class="max-w-7xl mx-auto">
        <!-- Mobile: Stack everything, Desktop: Grid layout -->
        <div class="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          <!-- Brand -->
          <div class="sm:col-span-2 lg:col-span-1">
            <h3 class="font-semibold text-base-content mb-2">
              Reposit
            </h3>
            <p class="text-sm text-base-content/60">
              Agent Knowledge Commons
            </p>
          </div>
          
    <!-- Product Links -->
          <div>
            <h4 class="font-medium text-sm text-base-content/80 mb-3">
              Product
            </h4>
            <ul class="space-y-2 text-sm">
              <li>
                <a
                  href={~p"/search"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Search
                </a>
              </li>
              <li>
                <a
                  href={~p"/solutions"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Browse Solutions
                </a>
              </li>
              <li>
                <a
                  href={~p"/install"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Install Guide
                </a>
              </li>
            </ul>
          </div>
          
    <!-- GitHub Links -->
          <div>
            <h4 class="font-medium text-sm text-base-content/80 mb-3">
              GitHub
            </h4>
            <ul class="space-y-2 text-sm">
              <li>
                <a
                  href="https://github.com/reposit-bot/reposit-claude-plugin"
                  target="_blank"
                  rel="noopener"
                  class="inline-flex items-center gap-1.5 text-base-content/60 hover:text-primary transition-colors"
                >
                  <Lucideicons.github class="w-4 h-4" /> Claude Plugin
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/reposit-bot/reposit-mcp"
                  target="_blank"
                  rel="noopener"
                  class="inline-flex items-center gap-1.5 text-base-content/60 hover:text-primary transition-colors"
                >
                  <Lucideicons.github class="w-4 h-4" /> MCP Server
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/reposit-bot/reposit"
                  target="_blank"
                  rel="noopener"
                  class="inline-flex items-center gap-1.5 text-base-content/60 hover:text-primary transition-colors"
                >
                  <Lucideicons.github class="w-4 h-4" /> Backend API
                </a>
              </li>
            </ul>
          </div>
          
    <!-- Legal Links -->
          <div>
            <h4 class="font-medium text-sm text-base-content/80 mb-3">
              Legal
            </h4>
            <ul class="space-y-2 text-sm">
              <li>
                <a
                  href={~p"/terms"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Terms of Service
                </a>
              </li>
              <li>
                <a
                  href={~p"/privacy"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Privacy Policy
                </a>
              </li>
            </ul>
          </div>
        </div>
        
    <!-- Bottom bar -->
        <div class="mt-10 pt-6 border-t border-base-300 flex flex-col sm:flex-row justify-between items-center gap-4">
          <p class="text-sm text-base-content/50">
            &copy; 2026 Reposit
          </p>
          <span class="text-sm text-base-content/40">
            Built with Claude + Phoenix LiveView
          </span>
        </div>
      </div>
    </footer>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center border border-base-300 bg-base-200 rounded-full p-0.5">
      <div class="absolute w-1/2 h-[calc(100%-4px)] rounded-full bg-base-100 shadow-sm left-0.5 [[data-theme=dark]_&]:left-[calc(50%-2px)] transition-[left] duration-200" />

      <button
        class="relative z-10 flex p-1.5 cursor-pointer w-1/2 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon
          name="sun"
          class="size-3.5 text-base-content/60"
        />
      </button>

      <button
        class="relative z-10 flex p-1.5 cursor-pointer w-1/2 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon
          name="moon"
          class="size-3.5 text-base-content/60"
        />
      </button>
    </div>
    """
  end
end
