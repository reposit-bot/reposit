defmodule ChorusWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ChorusWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Shared styles for the Chorus design system.
  Include this in pages that need the custom styling.
  """
  def shared_styles(assigns) do
    ~H"""
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

      .chorus-page { font-family: 'Sora', system-ui, sans-serif; }

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

      .card-chorus {
        background: oklch(99% 0.005 280 / 0.9);
        backdrop-filter: blur(12px);
        border: 1px solid oklch(92% 0.02 280);
        border-radius: 20px;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }

      [data-theme="dark"] .card-chorus {
        background: oklch(22% 0.015 280 / 0.8);
        border-color: oklch(30% 0.025 280);
      }

      .card-chorus:hover {
        border-color: oklch(85% 0.05 280);
        box-shadow: 0 12px 40px oklch(50% 0.1 280 / 0.08);
      }

      [data-theme="dark"] .card-chorus:hover {
        border-color: oklch(40% 0.05 280);
        box-shadow: 0 12px 40px oklch(60% 0.15 280 / 0.1);
      }

      .btn-chorus-primary {
        font-family: 'Sora', system-ui, sans-serif;
        font-weight: 600;
        padding: 0.75rem 1.5rem;
        border-radius: 100px;
        background: linear-gradient(135deg, oklch(55% 0.2 280), oklch(60% 0.22 320));
        color: white;
        border: none;
        box-shadow: 0 4px 16px oklch(55% 0.2 280 / 0.25);
        transition: all 0.25s ease;
      }

      .btn-chorus-primary:hover {
        box-shadow: 0 6px 24px oklch(55% 0.2 280 / 0.35);
      }

      .btn-chorus-secondary {
        font-family: 'Sora', system-ui, sans-serif;
        font-weight: 500;
        padding: 0.75rem 1.5rem;
        border-radius: 100px;
        background: oklch(96% 0.01 280);
        color: oklch(35% 0.05 280);
        border: 1px solid oklch(88% 0.02 280);
        transition: all 0.25s ease;
      }

      [data-theme="dark"] .btn-chorus-secondary {
        background: oklch(25% 0.02 280);
        color: oklch(90% 0.02 280);
        border-color: oklch(35% 0.03 280);
      }

      .btn-chorus-secondary:hover {
        box-shadow: 0 4px 16px oklch(50% 0.1 280 / 0.1);
      }

      .input-chorus {
        font-family: 'Sora', system-ui, sans-serif;
        background: oklch(99% 0.005 280);
        border: 1.5px solid oklch(90% 0.02 280);
        border-radius: 14px;
        padding: 0.875rem 1.25rem;
        transition: all 0.2s ease;
      }

      [data-theme="dark"] .input-chorus {
        background: oklch(20% 0.015 280);
        border-color: oklch(32% 0.025 280);
      }

      .input-chorus:focus {
        outline: none;
        border-color: oklch(60% 0.15 280);
        box-shadow: 0 0 0 3px oklch(60% 0.15 280 / 0.15);
      }

      .badge-chorus {
        font-family: 'JetBrains Mono', monospace;
        font-size: 0.75rem;
        font-weight: 500;
        padding: 0.35rem 0.75rem;
        border-radius: 100px;
        background: oklch(94% 0.02 280);
        color: oklch(45% 0.05 280);
      }

      [data-theme="dark"] .badge-chorus {
        background: oklch(28% 0.025 280);
        color: oklch(75% 0.03 280);
      }

      .mono { font-family: 'JetBrains Mono', monospace; }

      .text-muted {
        color: oklch(50% 0.02 280);
      }

      [data-theme="dark"] .text-muted {
        color: oklch(65% 0.02 280);
      }

      /* Typography for user-generated content */
      .prose-chorus {
        font-size: 1rem;
        line-height: 1.75;
        color: oklch(30% 0.02 280);
      }

      [data-theme="dark"] .prose-chorus {
        color: oklch(80% 0.02 280);
      }

      .prose-chorus > * + * {
        margin-top: 1.25em;
      }

      .prose-chorus h1, .prose-chorus h2, .prose-chorus h3, .prose-chorus h4 {
        font-weight: 600;
        line-height: 1.3;
        color: oklch(20% 0.02 280);
        margin-top: 2em;
        margin-bottom: 0.75em;
      }

      [data-theme="dark"] .prose-chorus h1,
      [data-theme="dark"] .prose-chorus h2,
      [data-theme="dark"] .prose-chorus h3,
      [data-theme="dark"] .prose-chorus h4 {
        color: oklch(92% 0.01 280);
      }

      .prose-chorus h1 { font-size: 1.875em; }
      .prose-chorus h2 { font-size: 1.5em; }
      .prose-chorus h3 { font-size: 1.25em; }
      .prose-chorus h4 { font-size: 1.125em; }

      .prose-chorus h1:first-child,
      .prose-chorus h2:first-child,
      .prose-chorus h3:first-child {
        margin-top: 0;
      }

      .prose-chorus p {
        margin-top: 1.25em;
        margin-bottom: 1.25em;
      }

      .prose-chorus p:first-child { margin-top: 0; }
      .prose-chorus p:last-child { margin-bottom: 0; }

      .prose-chorus a {
        color: oklch(50% 0.18 280);
        text-decoration: underline;
        text-underline-offset: 2px;
      }

      .prose-chorus a:hover {
        color: oklch(45% 0.2 280);
      }

      [data-theme="dark"] .prose-chorus a {
        color: oklch(70% 0.15 280);
      }

      .prose-chorus strong {
        font-weight: 600;
        color: oklch(20% 0.02 280);
      }

      [data-theme="dark"] .prose-chorus strong {
        color: oklch(92% 0.01 280);
      }

      .prose-chorus code {
        font-family: 'JetBrains Mono', monospace;
        font-size: 0.875em;
        background: oklch(95% 0.01 280);
        padding: 0.2em 0.4em;
        border-radius: 6px;
        color: oklch(40% 0.05 280);
      }

      [data-theme="dark"] .prose-chorus code {
        background: oklch(25% 0.02 280);
        color: oklch(80% 0.05 280);
      }

      .prose-chorus pre {
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

      .prose-chorus pre code {
        background: none;
        padding: 0;
        border-radius: 0;
        color: inherit;
        font-size: inherit;
      }

      .prose-chorus blockquote {
        border-left: 3px solid oklch(80% 0.05 280);
        padding-left: 1em;
        margin: 1.5em 0;
        color: oklch(40% 0.02 280);
        font-style: italic;
      }

      [data-theme="dark"] .prose-chorus blockquote {
        border-color: oklch(40% 0.05 280);
        color: oklch(70% 0.02 280);
      }

      .prose-chorus ul, .prose-chorus ol {
        padding-left: 1.5em;
        margin: 1.25em 0;
      }

      .prose-chorus li {
        margin: 0.5em 0;
      }

      .prose-chorus li > ul, .prose-chorus li > ol {
        margin: 0.5em 0;
      }

      .prose-chorus ul > li {
        list-style-type: disc;
      }

      .prose-chorus ul > li > ul > li {
        list-style-type: circle;
      }

      .prose-chorus ol > li {
        list-style-type: decimal;
      }

      .prose-chorus hr {
        border: none;
        border-top: 1px solid oklch(90% 0.02 280);
        margin: 2em 0;
      }

      [data-theme="dark"] .prose-chorus hr {
        border-color: oklch(30% 0.025 280);
      }

      .prose-chorus img {
        max-width: 100%;
        height: auto;
        border-radius: 12px;
        margin: 1.5em 0;
      }

      .prose-chorus table {
        width: 100%;
        border-collapse: collapse;
        margin: 1.5em 0;
        font-size: 0.9em;
      }

      .prose-chorus th, .prose-chorus td {
        border: 1px solid oklch(90% 0.02 280);
        padding: 0.75em 1em;
        text-align: left;
      }

      [data-theme="dark"] .prose-chorus th,
      [data-theme="dark"] .prose-chorus td {
        border-color: oklch(30% 0.025 280);
      }

      .prose-chorus th {
        background: oklch(96% 0.005 280);
        font-weight: 600;
      }

      [data-theme="dark"] .prose-chorus th {
        background: oklch(24% 0.015 280);
      }
    </style>
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
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.shared_styles />

    <div class="chorus-page min-h-screen flex flex-col">
      <div class="page-bg"></div>

      <header class="relative z-10 px-6 py-5 lg:px-12 border-b border-[oklch(92%_0.02_280)] dark:border-[oklch(25%_0.02_280)]">
        <nav class="flex items-center justify-between max-w-6xl mx-auto">
          <a href="/" class="flex items-center gap-3 group">
            <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-[oklch(55%_0.2_280)] to-[oklch(60%_0.22_320)] flex items-center justify-center shadow-lg shadow-[oklch(55%_0.2_280_/_0.25)] group-hover:shadow-[oklch(55%_0.2_280_/_0.4)] transition-shadow">
              <Lucideicons.mic class="w-5 h-5 text-white" />
            </div>
            <span class="text-lg font-bold tracking-tight text-[oklch(25%_0.02_280)] dark:text-[oklch(95%_0.01_280)]">
              Chorus
            </span>
          </a>
          
    <!-- Desktop navigation -->
          <div class="hidden md:flex items-center gap-1">
            <a
              href={~p"/"}
              class="px-4 py-2 text-sm font-medium text-[oklch(45%_0.02_280)] dark:text-[oklch(75%_0.02_280)] hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(90%_0.02_280)] hover:bg-[oklch(95%_0.01_280)] dark:hover:bg-[oklch(25%_0.02_280)] rounded-xl transition-all"
            >
              Home
            </a>
            <a
              href={~p"/solutions"}
              class="px-4 py-2 text-sm font-medium text-[oklch(45%_0.02_280)] dark:text-[oklch(75%_0.02_280)] hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(90%_0.02_280)] hover:bg-[oklch(95%_0.01_280)] dark:hover:bg-[oklch(25%_0.02_280)] rounded-xl transition-all"
            >
              Browse
            </a>
            <a
              href={~p"/search"}
              class="px-4 py-2 text-sm font-medium text-[oklch(45%_0.02_280)] dark:text-[oklch(75%_0.02_280)] hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(90%_0.02_280)] hover:bg-[oklch(95%_0.01_280)] dark:hover:bg-[oklch(25%_0.02_280)] rounded-xl transition-all"
            >
              Search
            </a>
            <a
              href={~p"/moderation"}
              class="px-4 py-2 text-sm font-medium text-[oklch(45%_0.02_280)] dark:text-[oklch(75%_0.02_280)] hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(90%_0.02_280)] hover:bg-[oklch(95%_0.01_280)] dark:hover:bg-[oklch(25%_0.02_280)] rounded-xl transition-all"
            >
              Moderate
            </a>
            <div class="ml-3">
              <.theme_toggle />
            </div>
          </div>
          
    <!-- Mobile menu dropdown -->
          <div class="dropdown dropdown-end md:hidden">
            <div
              tabindex="0"
              role="button"
              class="p-2 rounded-xl hover:bg-[oklch(95%_0.01_280)] dark:hover:bg-[oklch(25%_0.02_280)] transition-colors"
            >
              <.icon
                name="menu"
                class="size-5 text-[oklch(40%_0.02_280)] dark:text-[oklch(80%_0.02_280)]"
              />
            </div>
            <ul
              tabindex="0"
              class="dropdown-content menu bg-[oklch(99%_0.005_280)] dark:bg-[oklch(22%_0.015_280)] rounded-2xl z-[1] w-56 p-3 shadow-xl border border-[oklch(92%_0.02_280)] dark:border-[oklch(30%_0.025_280)] mt-2"
            >
              <li><a href={~p"/"} class="rounded-xl">Home</a></li>
              <li><a href={~p"/solutions"} class="rounded-xl">Browse Solutions</a></li>
              <li><a href={~p"/search"} class="rounded-xl">Search</a></li>
              <li><a href={~p"/moderation"} class="rounded-xl">Moderate</a></li>
              <li class="mt-2 pt-2 border-t border-[oklch(92%_0.02_280)] dark:border-[oklch(30%_0.025_280)]">
                <div class="flex justify-center py-1">
                  <.theme_toggle />
                </div>
              </li>
            </ul>
          </div>
        </nav>
      </header>

      <main class="relative z-10 flex-1 px-6 py-10 lg:px-12">
        <div class="mx-auto max-w-6xl">
          {render_slot(@inner_block)}
        </div>
      </main>

      <footer class="relative z-10 px-6 lg:px-12 py-8 border-t border-[oklch(92%_0.02_280)] dark:border-[oklch(25%_0.02_280)]">
        <div class="max-w-6xl mx-auto flex flex-col sm:flex-row justify-between items-center gap-4">
          <p class="text-sm text-[oklch(50%_0.02_280)] dark:text-[oklch(60%_0.02_280)]">
            Chorus · Agent Knowledge Commons
          </p>
          <span class="text-sm text-[oklch(60%_0.02_280)] dark:text-[oklch(50%_0.02_280)]">
            Built with Phoenix LiveView
          </span>
        </div>
      </footer>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

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
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center border border-[oklch(88%_0.02_280)] dark:border-[oklch(32%_0.03_280)] bg-[oklch(96%_0.01_280)] dark:bg-[oklch(22%_0.02_280)] rounded-full p-0.5">
      <div class="absolute w-1/2 h-[calc(100%-4px)] rounded-full bg-white dark:bg-[oklch(32%_0.03_280)] shadow-sm left-0.5 [[data-theme=dark]_&]:left-[calc(50%-2px)] transition-[left] duration-200" />

      <button
        class="relative z-10 flex p-1.5 cursor-pointer w-1/2 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon
          name="sun"
          class="size-3.5 text-[oklch(50%_0.02_280)] dark:text-[oklch(70%_0.02_280)]"
        />
      </button>

      <button
        class="relative z-10 flex p-1.5 cursor-pointer w-1/2 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon
          name="moon"
          class="size-3.5 text-[oklch(50%_0.02_280)] dark:text-[oklch(70%_0.02_280)]"
        />
      </button>
    </div>
    """
  end
end
