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
  Shared styles for the Reposit design system.
  Include this in pages that need the custom styling.
  """
  def shared_styles(assigns) do
    ~H"""
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

      .reposit-page { font-family: 'Sora', system-ui, sans-serif; }

      .page-bg {
        position: fixed;
        inset: 0;
        background:
          radial-gradient(ellipse 80% 50% at 50% -10%, oklch(60% 0.12 280 / 0.15), transparent),
          radial-gradient(ellipse 50% 40% at 90% 90%, oklch(65% 0.15 200 / 0.08), transparent);
        pointer-events: none;
        z-index: -1;
      }

      [data-theme="dark"] .page-bg {
        background:
          radial-gradient(ellipse 80% 50% at 50% -10%, oklch(50% 0.18 280 / 0.2), transparent),
          radial-gradient(ellipse 50% 40% at 90% 90%, oklch(55% 0.2 200 / 0.1), transparent);
      }

      .page-title {
        font-weight: 700;
        font-size: clamp(1.75rem, 4vw, 2.5rem);
        letter-spacing: -0.02em;
        background: linear-gradient(135deg, oklch(35% 0.02 280) 0%, oklch(45% 0.12 280) 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
      }

      [data-theme="dark"] .page-title {
        background: linear-gradient(135deg, oklch(95% 0.01 280) 0%, oklch(85% 0.12 280) 100%);
        -webkit-background-clip: text;
        background-clip: text;
      }

      .page-subtitle {
        font-weight: 400;
        font-size: 1.1rem;
        color: oklch(45% 0.02 280);
      }

      [data-theme="dark"] .page-subtitle { color: oklch(70% 0.02 280); }

      .mono { font-family: 'JetBrains Mono', monospace; }

      .text-muted {
        color: oklch(50% 0.02 280);
      }

      [data-theme="dark"] .text-muted {
        color: oklch(65% 0.02 280);
      }

      /* Typography for user-generated content */
      .prose-reposit {
        font-size: 1rem;
        line-height: 1.75;
        color: oklch(30% 0.02 280);
      }

      [data-theme="dark"] .prose-reposit {
        color: oklch(80% 0.02 280);
      }

      .prose-reposit > * + * {
        margin-top: 1.25em;
      }

      .prose-reposit h1, .prose-reposit h2, .prose-reposit h3, .prose-reposit h4 {
        font-weight: 600;
        line-height: 1.3;
        color: oklch(20% 0.02 280);
        margin-top: 2em;
        margin-bottom: 0.75em;
      }

      [data-theme="dark"] .prose-reposit h1,
      [data-theme="dark"] .prose-reposit h2,
      [data-theme="dark"] .prose-reposit h3,
      [data-theme="dark"] .prose-reposit h4 {
        color: oklch(92% 0.01 280);
      }

      .prose-reposit h1 { font-size: 1.875em; }
      .prose-reposit h2 { font-size: 1.5em; }
      .prose-reposit h3 { font-size: 1.25em; }
      .prose-reposit h4 { font-size: 1.125em; }

      .prose-reposit h1:first-child,
      .prose-reposit h2:first-child,
      .prose-reposit h3:first-child {
        margin-top: 0;
      }

      .prose-reposit p {
        margin-top: 1.25em;
        margin-bottom: 1.25em;
      }

      .prose-reposit p:first-child { margin-top: 0; }
      .prose-reposit p:last-child { margin-bottom: 0; }

      .prose-reposit a {
        color: oklch(50% 0.18 280);
        text-decoration: underline;
        text-underline-offset: 2px;
      }

      .prose-reposit a:hover {
        color: oklch(45% 0.2 280);
      }

      [data-theme="dark"] .prose-reposit a {
        color: oklch(70% 0.15 280);
      }

      .prose-reposit strong {
        font-weight: 600;
        color: oklch(20% 0.02 280);
      }

      [data-theme="dark"] .prose-reposit strong {
        color: oklch(92% 0.01 280);
      }

      .prose-reposit code {
        font-family: 'JetBrains Mono', monospace;
        font-size: 0.875em;
        background: oklch(95% 0.01 280);
        padding: 0.2em 0.4em;
        border-radius: 6px;
        color: oklch(40% 0.05 280);
      }

      [data-theme="dark"] .prose-reposit code {
        background: oklch(25% 0.02 280);
        color: oklch(80% 0.05 280);
      }

      .prose-reposit pre {
        font-family: 'JetBrains Mono', monospace;
        font-size: 0.875em;
        line-height: 1.7;
        background: oklch(18% 0.015 280);
        color: oklch(85% 0.02 280);
        padding: 1.25em 1.5em;
        border-radius: 12px;
        overflow-x: auto;
        margin: 1.5em 0;
      }

      .prose-reposit pre code {
        background: none;
        padding: 0;
        border-radius: 0;
        color: inherit;
        font-size: inherit;
      }

      .prose-reposit blockquote {
        border-left: 3px solid oklch(80% 0.05 280);
        padding-left: 1em;
        margin: 1.5em 0;
        color: oklch(40% 0.02 280);
        font-style: italic;
      }

      [data-theme="dark"] .prose-reposit blockquote {
        border-color: oklch(40% 0.05 280);
        color: oklch(70% 0.02 280);
      }

      .prose-reposit ul, .prose-reposit ol {
        padding-left: 1.5em;
        margin: 1.25em 0;
      }

      .prose-reposit li {
        margin: 0.5em 0;
      }

      .prose-reposit li > ul, .prose-reposit li > ol {
        margin: 0.5em 0;
      }

      .prose-reposit ul > li {
        list-style-type: disc;
      }

      .prose-reposit ul > li > ul > li {
        list-style-type: circle;
      }

      .prose-reposit ol > li {
        list-style-type: decimal;
      }

      .prose-reposit hr {
        border: none;
        border-top: 1px solid oklch(90% 0.02 280);
        margin: 2em 0;
      }

      [data-theme="dark"] .prose-reposit hr {
        border-color: oklch(30% 0.025 280);
      }

      .prose-reposit img {
        max-width: 100%;
        height: auto;
        border-radius: 12px;
        margin: 1.5em 0;
      }

      .prose-reposit table {
        width: 100%;
        border-collapse: collapse;
        margin: 1.5em 0;
        font-size: 0.9em;
      }

      .prose-reposit th, .prose-reposit td {
        border: 1px solid oklch(90% 0.02 280);
        padding: 0.75em 1em;
        text-align: left;
      }

      [data-theme="dark"] .prose-reposit th,
      [data-theme="dark"] .prose-reposit td {
        border-color: oklch(30% 0.025 280);
      }

      .prose-reposit th {
        background: oklch(96% 0.005 280);
        font-weight: 600;
      }

      [data-theme="dark"] .prose-reposit th {
        background: oklch(24% 0.015 280);
      }
    </style>
    """
  end

  @doc """
  Reusable navigation bar component with desktop and mobile menus.
  """
  attr :current_scope, :map, default: nil
  attr :class, :string, default: ""
  attr :max_width, :string, default: "max-w-6xl"

  def navbar(assigns) do
    ~H"""
    <nav class={"flex items-center justify-between mx-auto #{@max_width} #{@class}"}>
      <a href="/" class="flex items-center gap-3 group">
        <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-[oklch(55%_0.2_280)] to-[oklch(60%_0.22_320)] flex items-center justify-center shadow-lg shadow-[oklch(55%_0.2_280_/_0.25)] group-hover:shadow-[oklch(55%_0.2_280_/_0.4)] transition-shadow">
          <Lucideicons.mic class="w-5 h-5 text-white" />
        </div>
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
          <.icon
            name="menu"
            class="size-5 text-base-content/70"
          />
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
    <.shared_styles />

    <div class="reposit-page min-h-screen flex flex-col">
      <div class="page-bg"></div>

      <header class="relative z-50 px-6 py-5 lg:px-12 border-b border-base-300">
        <.navbar current_scope={@current_scope} />
      </header>

      <main class="relative z-10 flex-1 px-6 py-10 lg:px-12">
        <div class="mx-auto max-w-6xl">
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
      <div class="max-w-6xl mx-auto">
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
            © 2026 Reposit. Open source under MIT license.
          </p>
          <span class="text-sm text-base-content/40">
            Built with Phoenix LiveView
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
