defmodule ChorusWeb.SearchLive do
  @moduledoc """
  LiveView for searching solutions using semantic search.

  Features:
  - Debounced search input (300ms)
  - Tag filters for language, framework, domain, platform
  - Results displayed with relevance scores
  - Loading states during search
  """
  use ChorusWeb, :live_view

  alias Chorus.Solutions

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:results, [])
     |> assign(:total, 0)
     |> assign(:searching, false)
     |> assign(:searched, false)
     |> assign(:sort, :relevance)
     |> assign(:tag_filters, %{language: [], framework: [], domain: [], platform: []})}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    if String.trim(query) == "" do
      {:noreply,
       socket
       |> assign(:query, "")
       |> assign(:results, [])
       |> assign(:total, 0)
       |> assign(:searched, false)}
    else
      socket =
        socket
        |> assign(:query, query)
        |> assign(:searching, true)

      send(self(), :do_search)
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter_params}, socket) do
    tag_filters = %{
      language: parse_tags(filter_params["language"]),
      framework: parse_tags(filter_params["framework"]),
      domain: parse_tags(filter_params["domain"]),
      platform: parse_tags(filter_params["platform"])
    }

    socket =
      socket
      |> assign(:tag_filters, tag_filters)
      |> assign(:searching, true)

    socket =
      if socket.assigns.query != "" do
        send(self(), :do_search)
        socket
      else
        assign(socket, :searching, false)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("sort", %{"sort" => sort}, socket) do
    sort_atom = String.to_existing_atom(sort)

    socket =
      socket
      |> assign(:sort, sort_atom)
      |> assign(:searching, true)

    socket =
      if socket.assigns.query != "" do
        send(self(), :do_search)
        socket
      else
        assign(socket, :searching, false)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:do_search, socket) do
    %{query: query, tag_filters: tag_filters, sort: sort} = socket.assigns

    # Build required_tags from non-empty filters
    required_tags =
      tag_filters
      |> Enum.filter(fn {_k, v} -> length(v) > 0 end)
      |> Enum.into(%{})

    opts = [
      limit: 20,
      required_tags: required_tags,
      sort: sort
    ]

    {results, total} =
      case Solutions.search_solutions(query, opts) do
        {:ok, results, total} -> {results, total}
        {:error, _} -> {[], 0}
      end

    {:noreply,
     socket
     |> assign(:results, results)
     |> assign(:total, total)
     |> assign(:searching, false)
     |> assign(:searched, true)}
  end

  defp parse_tags(nil), do: []
  defp parse_tags(""), do: []

  defp parse_tags(str) when is_binary(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-8">
        <!-- Header -->
        <div>
          <h1 class="page-title">Search Solutions</h1>
          <p class="page-subtitle mt-2">Find solutions using semantic search</p>
        </div>
        
    <!-- Search Card -->
        <div class="card-chorus p-6">
          <form id="search-form" phx-change="search" phx-submit="search">
            <label class="block text-sm font-medium text-[oklch(35%_0.02_280)] dark:text-[oklch(85%_0.02_280)] mb-2">
              Describe your problem
            </label>
            <textarea
              name="query"
              class="input-chorus w-full h-28 resize-none"
              placeholder="e.g., How to implement rate limiting in Phoenix..."
              phx-debounce="300"
            >{@query}</textarea>
          </form>

          <div class="flex items-center gap-4 my-6">
            <div class="flex-1 h-px bg-[oklch(90%_0.02_280)] dark:bg-[oklch(30%_0.025_280)]"></div>
            <span class="text-sm text-muted">Filters</span>
            <div class="flex-1 h-px bg-[oklch(90%_0.02_280)] dark:bg-[oklch(30%_0.025_280)]"></div>
          </div>

          <form phx-change="update_filter" class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <label class="block text-xs font-medium text-muted mb-1.5">Language</label>
              <input
                type="text"
                name="filter[language]"
                class="input-chorus w-full text-sm py-2.5"
                placeholder="elixir, python..."
                value={Enum.join(@tag_filters.language, ", ")}
              />
            </div>

            <div>
              <label class="block text-xs font-medium text-muted mb-1.5">Framework</label>
              <input
                type="text"
                name="filter[framework]"
                class="input-chorus w-full text-sm py-2.5"
                placeholder="phoenix, django..."
                value={Enum.join(@tag_filters.framework, ", ")}
              />
            </div>

            <div>
              <label class="block text-xs font-medium text-muted mb-1.5">Domain</label>
              <input
                type="text"
                name="filter[domain]"
                class="input-chorus w-full text-sm py-2.5"
                placeholder="api, database..."
                value={Enum.join(@tag_filters.domain, ", ")}
              />
            </div>

            <div>
              <label class="block text-xs font-medium text-muted mb-1.5">Platform</label>
              <input
                type="text"
                name="filter[platform]"
                class="input-chorus w-full text-sm py-2.5"
                placeholder="aws, docker..."
                value={Enum.join(@tag_filters.platform, ", ")}
              />
            </div>
          </form>
        </div>
        
    <!-- Loading State -->
        <div :if={@searching} class="flex justify-center py-12">
          <div class="flex items-center gap-3 text-[oklch(55%_0.15_280)]">
            <svg class="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
              </circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              >
              </path>
            </svg>
            <span class="text-sm font-medium">Searching...</span>
          </div>
        </div>
        
    <!-- Results -->
        <div :if={not @searching and @searched}>
          <div class="flex justify-between items-center mb-6">
            <p class="text-muted">
              {if @total == 0,
                do: "No results found",
                else: "#{@total} result#{if @total != 1, do: "s"} found"}
            </p>

            <div :if={@total > 0} class="flex items-center gap-3">
              <span class="text-xs text-muted">Sort:</span>
              <div class="flex rounded-full bg-[oklch(96%_0.01_280)] dark:bg-[oklch(22%_0.02_280)] p-1 border border-[oklch(90%_0.02_280)] dark:border-[oklch(30%_0.025_280)]">
                <button
                  class={"px-3 py-1 text-xs font-medium rounded-full transition-all #{if @sort == :relevance, do: "bg-white dark:bg-[oklch(32%_0.03_280)] text-[oklch(35%_0.05_280)] dark:text-[oklch(90%_0.02_280)] shadow-sm", else: "text-muted hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(85%_0.02_280)]"}"}
                  phx-click="sort"
                  phx-value-sort="relevance"
                >
                  Relevance
                </button>
                <button
                  class={"px-3 py-1 text-xs font-medium rounded-full transition-all #{if @sort == :top_voted, do: "bg-white dark:bg-[oklch(32%_0.03_280)] text-[oklch(35%_0.05_280)] dark:text-[oklch(90%_0.02_280)] shadow-sm", else: "text-muted hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(85%_0.02_280)]"}"}
                  phx-click="sort"
                  phx-value-sort="top_voted"
                >
                  Top Voted
                </button>
                <button
                  class={"px-3 py-1 text-xs font-medium rounded-full transition-all #{if @sort == :newest, do: "bg-white dark:bg-[oklch(32%_0.03_280)] text-[oklch(35%_0.05_280)] dark:text-[oklch(90%_0.02_280)] shadow-sm", else: "text-muted hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(85%_0.02_280)]"}"}
                  phx-click="sort"
                  phx-value-sort="newest"
                >
                  Newest
                </button>
              </div>
            </div>
          </div>

          <.no_results :if={@total == 0} query={@query} />

          <div :if={@total > 0} class="space-y-4">
            <.result_card :for={result <- @results} result={result} />
          </div>
        </div>
        
    <!-- Empty State -->
        <div :if={not @searching and not @searched} class="card-chorus p-12 text-center">
          <div class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-[oklch(55%_0.2_280_/_0.1)] to-[oklch(60%_0.22_320_/_0.05)] flex items-center justify-center">
            <.icon name="hero-magnifying-glass" class="size-8 text-[oklch(55%_0.15_280)]" />
          </div>
          <p class="text-lg font-medium text-[oklch(35%_0.02_280)] dark:text-[oklch(85%_0.02_280)]">
            Enter a problem description to search
          </p>
          <p class="text-sm text-muted mt-2">
            Our semantic search will find similar solutions
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp no_results(assigns) do
    ~H"""
    <div class="card-chorus p-12 text-center">
      <div class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-[oklch(94%_0.02_280)] dark:bg-[oklch(28%_0.025_280)] flex items-center justify-center">
        <.icon name="hero-magnifying-glass" class="size-8 text-muted" />
      </div>
      <p class="text-lg font-medium text-[oklch(35%_0.02_280)] dark:text-[oklch(85%_0.02_280)]">
        No solutions found for "{@query}"
      </p>
      <p class="text-sm text-muted mt-2">
        Try different keywords or remove some filters
      </p>
    </div>
    """
  end

  defp result_card(assigns) do
    score = assigns.result.upvotes - assigns.result.downvotes
    assigns = assign(assigns, :score, score)

    ~H"""
    <a
      href={~p"/solutions/#{@result.id}"}
      class="card-chorus block p-5 hover:border-[oklch(60%_0.15_280)] dark:hover:border-[oklch(50%_0.15_280)]"
    >
      <div class="flex justify-between items-start gap-4">
        <div class="flex-1 min-w-0">
          <h2 class="font-semibold text-[oklch(25%_0.02_280)] dark:text-[oklch(92%_0.01_280)] line-clamp-1">
            {truncate(@result.problem_description, 100)}
          </h2>
          <p class="text-sm text-muted mt-2 line-clamp-2">
            {truncate(@result.solution_pattern, 150)}
          </p>
        </div>

        <div class="flex flex-col items-end gap-2 flex-shrink-0">
          <span class="badge-chorus bg-gradient-to-r from-[oklch(55%_0.2_280_/_0.1)] to-[oklch(60%_0.22_320_/_0.1)] text-[oklch(50%_0.15_280)] dark:text-[oklch(75%_0.15_280)]">
            {Float.round(@result.similarity * 100, 1)}% match
          </span>
          <span class={"mono text-sm font-semibold #{score_color(@score)}"}>
            {if @score >= 0, do: "+", else: ""}{@score}
          </span>
        </div>
      </div>

      <.tags tags={@result.tags} />
    </a>
    """
  end

  defp tags(assigns) do
    all_tags = flatten_tags(assigns.tags)
    assigns = assign(assigns, :all_tags, all_tags)

    ~H"""
    <div :if={length(@all_tags) > 0} class="flex flex-wrap gap-1.5 mt-4">
      <span
        :for={tag <- Enum.take(@all_tags, 6)}
        class={"badge-chorus text-[0.7rem] py-1 #{tag_color(tag.category)}"}
      >
        {tag.value}
      </span>
      <span :if={length(@all_tags) > 6} class="badge-chorus text-[0.7rem] py-1">
        +{length(@all_tags) - 6}
      </span>
    </div>
    """
  end

  defp flatten_tags(nil), do: []

  defp flatten_tags(tags) when is_map(tags) do
    Enum.flat_map(tags, fn {category, values} ->
      values = if is_list(values), do: values, else: []
      Enum.map(values, &%{category: category, value: &1})
    end)
  end

  defp tag_color("language"),
    do:
      "bg-[oklch(90%_0.05_280)] dark:bg-[oklch(30%_0.05_280)] text-[oklch(45%_0.1_280)] dark:text-[oklch(80%_0.1_280)]"

  defp tag_color(:language),
    do:
      "bg-[oklch(90%_0.05_280)] dark:bg-[oklch(30%_0.05_280)] text-[oklch(45%_0.1_280)] dark:text-[oklch(80%_0.1_280)]"

  defp tag_color("framework"),
    do:
      "bg-[oklch(90%_0.05_320)] dark:bg-[oklch(30%_0.05_320)] text-[oklch(45%_0.1_320)] dark:text-[oklch(80%_0.1_320)]"

  defp tag_color(:framework),
    do:
      "bg-[oklch(90%_0.05_320)] dark:bg-[oklch(30%_0.05_320)] text-[oklch(45%_0.1_320)] dark:text-[oklch(80%_0.1_320)]"

  defp tag_color("domain"),
    do:
      "bg-[oklch(90%_0.05_200)] dark:bg-[oklch(30%_0.05_200)] text-[oklch(45%_0.1_200)] dark:text-[oklch(80%_0.1_200)]"

  defp tag_color(:domain),
    do:
      "bg-[oklch(90%_0.05_200)] dark:bg-[oklch(30%_0.05_200)] text-[oklch(45%_0.1_200)] dark:text-[oklch(80%_0.1_200)]"

  defp tag_color("platform"),
    do:
      "bg-[oklch(90%_0.05_240)] dark:bg-[oklch(30%_0.05_240)] text-[oklch(45%_0.1_240)] dark:text-[oklch(80%_0.1_240)]"

  defp tag_color(:platform),
    do:
      "bg-[oklch(90%_0.05_240)] dark:bg-[oklch(30%_0.05_240)] text-[oklch(45%_0.1_240)] dark:text-[oklch(80%_0.1_240)]"

  defp tag_color(_), do: ""

  defp score_color(score) when score > 0, do: "text-[oklch(55%_0.15_145)]"
  defp score_color(score) when score < 0, do: "text-[oklch(60%_0.2_25)]"
  defp score_color(_), do: "text-muted"

  defp truncate(text, max_length) when is_binary(text) and byte_size(text) > max_length do
    String.slice(text, 0, max_length) <> "..."
  end

  defp truncate(text, _max_length), do: text
end
