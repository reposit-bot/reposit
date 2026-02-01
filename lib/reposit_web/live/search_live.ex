defmodule RepositWeb.SearchLive do
  @moduledoc """
  LiveView for searching solutions using semantic search.

  Features:
  - Debounced search input (300ms)
  - Tag filters for language, framework, domain, platform
  - Results displayed with relevance scores
  - Loading states during search
  """
  use RepositWeb, :live_view

  alias Reposit.Solutions

  @impl true
  def mount(_params, _session, socket) do
    recent = Solutions.list_solutions(limit: 5, order_by: :inserted_at)

    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:results, [])
     |> assign(:total, 0)
     |> assign(:searching, false)
     |> assign(:searched, false)
     |> assign(:sort, :relevance)
     |> assign(:tag_filters, %{language: [], framework: [], domain: [], platform: []})
     |> assign(:recent_solutions, recent)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    if String.trim(query) == "" do
      recent = Solutions.list_solutions(limit: 5, order_by: :inserted_at)

      {:noreply,
       socket
       |> assign(:query, "")
       |> assign(:results, [])
       |> assign(:total, 0)
       |> assign(:searched, false)
       |> assign(:recent_solutions, recent)}
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
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <!-- Header -->
        <div>
          <h1 class="page-title">Search Solutions</h1>
          <p class="page-subtitle mt-2">Find solutions using semantic search</p>
        </div>
        
    <!-- Search Card -->
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body p-4 sm:p-6">
            <form id="search-form" phx-change="search" phx-submit="search">
              <label class="label">
                <span class="label-text font-medium">Describe your problem</span>
              </label>
              <textarea
                name="query"
                class="textarea textarea-bordered w-full h-28 resize-none"
                placeholder="e.g., How to implement rate limiting in Phoenix..."
                phx-debounce="300"
              >{@query}</textarea>
            </form>

            <div class="divider text-sm text-base-content/60">Filters</div>

            <form
              phx-change="update_filter"
              class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4"
            >
              <div class="form-control">
                <label class="label py-1">
                  <span class="label-text text-xs">Language</span>
                </label>
                <input
                  type="text"
                  name="filter[language]"
                  class="input input-bordered input-sm w-full"
                  placeholder="elixir, python..."
                  value={Enum.join(@tag_filters.language, ", ")}
                />
              </div>

              <div class="form-control">
                <label class="label py-1">
                  <span class="label-text text-xs">Framework</span>
                </label>
                <input
                  type="text"
                  name="filter[framework]"
                  class="input input-bordered input-sm w-full"
                  placeholder="phoenix, django..."
                  value={Enum.join(@tag_filters.framework, ", ")}
                />
              </div>

              <div class="form-control">
                <label class="label py-1">
                  <span class="label-text text-xs">Domain</span>
                </label>
                <input
                  type="text"
                  name="filter[domain]"
                  class="input input-bordered input-sm w-full"
                  placeholder="api, database..."
                  value={Enum.join(@tag_filters.domain, ", ")}
                />
              </div>

              <div class="form-control">
                <label class="label py-1">
                  <span class="label-text text-xs">Platform</span>
                </label>
                <input
                  type="text"
                  name="filter[platform]"
                  class="input input-bordered input-sm w-full"
                  placeholder="aws, docker..."
                  value={Enum.join(@tag_filters.platform, ", ")}
                />
              </div>
            </form>
          </div>
        </div>
        
    <!-- Loading State -->
        <div :if={@searching} class="flex justify-center py-12">
          <div class="flex items-center gap-3 text-primary">
            <span class="loading loading-spinner loading-md"></span>
            <span class="text-sm font-medium">Searching...</span>
          </div>
        </div>
        
    <!-- Results -->
        <div :if={not @searching and @searched}>
          <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 mb-6">
            <p class="text-base-content/60">
              {if @total == 0,
                do: "No results found",
                else: "#{@total} result#{if @total != 1, do: "s"} found"}
            </p>

            <div :if={@total > 0} class="flex items-center gap-2 sm:gap-3">
              <span class="text-xs text-base-content/60 hidden sm:inline">Sort:</span>
              <div role="tablist" class="tabs tabs-boxed tabs-sm">
                <button
                  role="tab"
                  class={"tab #{if @sort == :relevance, do: "tab-active"}"}
                  phx-click="sort"
                  phx-value-sort="relevance"
                >
                  Relevance
                </button>
                <button
                  role="tab"
                  class={"tab #{if @sort == :top_voted, do: "tab-active"}"}
                  phx-click="sort"
                  phx-value-sort="top_voted"
                >
                  Top Voted
                </button>
                <button
                  role="tab"
                  class={"tab #{if @sort == :newest, do: "tab-active"}"}
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
        
    <!-- Empty State / Recent Solutions -->
        <div :if={not @searching and not @searched} class="space-y-6">
          <p class="text-base-content/60">
            Enter a problem description above to search, or browse recent solutions below.
          </p>

          <%= if Enum.empty?(@recent_solutions) do %>
            <div class="card bg-base-100 shadow-lg">
              <div class="card-body items-center text-center py-12">
                <div class="w-16 h-16 mb-2 rounded-2xl bg-primary/10 flex items-center justify-center">
                  <.icon name="search" class="size-8 text-primary" />
                </div>
                <p class="text-lg font-semibold">Enter a problem description to search</p>
                <p class="text-base-content/60">
                  Our semantic search will find similar solutions
                </p>
              </div>
            </div>
          <% else %>
            <div>
              <h2 class="text-lg font-semibold text-base-content mb-4">Recent solutions</h2>
              <div class="space-y-4">
                <.recent_solution_card :for={solution <- @recent_solutions} solution={solution} />
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp recent_solution_card(assigns) do
    score = assigns.solution.upvotes - assigns.solution.downvotes
    assigns = assign(assigns, :score, score)

    ~H"""
    <a
      href={~p"/solutions/#{@solution.id}"}
      class="card card-bordered bg-base-100 block p-4 sm:p-5 hover:border-primary/50 transition-colors"
    >
      <div class="flex flex-col sm:flex-row justify-between items-start gap-3 sm:gap-4">
        <div class="flex-1 min-w-0">
          <h2 class="font-semibold text-base-content line-clamp-2 sm:line-clamp-1">
            {truncate(@solution.problem_description, 100)}
          </h2>
          <p class="text-sm text-base-content/60 mt-2 line-clamp-2">
            {truncate(@solution.solution_pattern, 150)}
          </p>
        </div>

        <div class="flex sm:flex-col items-center sm:items-end gap-2 flex-shrink-0">
          <span class={"mono text-sm font-semibold #{score_color(@score)}"}>
            {if @score >= 0, do: "+", else: ""}{@score}
          </span>
          <span class="badge badge-ghost gap-1 text-xs">
            <.icon name="thumbs-up" class="size-3" />
            {@solution.upvotes}
          </span>
          <span class="badge badge-ghost gap-1 text-xs">
            <.icon name="thumbs-down" class="size-3" />
            {@solution.downvotes}
          </span>
        </div>
      </div>

      <.tags tags={@solution.tags} />
    </a>
    """
  end

  defp no_results(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-lg">
      <div class="card-body items-center text-center py-12">
        <div class="w-16 h-16 mb-2 rounded-2xl bg-base-200 flex items-center justify-center">
          <.icon name="search" class="size-8 text-base-content/40" />
        </div>
        <p class="text-lg font-semibold">No solutions found for "{@query}"</p>
        <p class="text-base-content/60">
          Try different keywords or remove some filters
        </p>
      </div>
    </div>
    """
  end

  defp result_card(assigns) do
    score = assigns.result.upvotes - assigns.result.downvotes
    assigns = assign(assigns, :score, score)

    ~H"""
    <a
      href={~p"/solutions/#{@result.id}"}
      class="card card-bordered bg-base-100 block p-4 sm:p-5 hover:border-primary/50 transition-colors"
    >
      <div class="flex flex-col sm:flex-row justify-between items-start gap-3 sm:gap-4">
        <div class="flex-1 min-w-0">
          <h2 class="font-semibold text-base-content line-clamp-2 sm:line-clamp-1">
            {truncate(@result.problem_description, 100)}
          </h2>
          <p class="text-sm text-base-content/60 mt-2 line-clamp-2">
            {truncate(@result.solution_pattern, 150)}
          </p>
        </div>

        <div class="flex sm:flex-col items-center sm:items-end gap-2 flex-shrink-0">
          <span class="badge badge-sm badge-primary badge-outline">
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
        class={"badge badge-sm font-mono #{tag_color(tag.category)}"}
      >
        {tag.value}
      </span>
      <span :if={length(@all_tags) > 6} class="badge badge-sm font-mono">
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

  defp tag_color("language"), do: "badge-primary badge-outline"
  defp tag_color(:language), do: "badge-primary badge-outline"
  defp tag_color("framework"), do: "badge-secondary badge-outline"
  defp tag_color(:framework), do: "badge-secondary badge-outline"
  defp tag_color("domain"), do: "badge-info badge-outline"
  defp tag_color(:domain), do: "badge-info badge-outline"
  defp tag_color("platform"), do: "badge-accent badge-outline"
  defp tag_color(:platform), do: "badge-accent badge-outline"
  defp tag_color(_), do: "badge-ghost"

  defp score_color(score) when score > 0, do: "text-success"
  defp score_color(score) when score < 0, do: "text-error"
  defp score_color(_), do: "text-base-content/60"

  defp truncate(text, max_length) when is_binary(text) and byte_size(text) > max_length do
    String.slice(text, 0, max_length) <> "..."
  end

  defp truncate(text, _max_length), do: text
end
