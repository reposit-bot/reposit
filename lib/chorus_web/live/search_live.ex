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
      <div class="container mx-auto px-4 py-8 max-w-4xl">
        <h1 class="text-3xl font-bold mb-6">Search Solutions</h1>

        <div class="card bg-base-100 shadow-xl mb-8">
          <div class="card-body">
            <form id="search-form" phx-change="search" phx-submit="search">
              <div class="form-control">
                <label class="label">
                  <span class="label-text font-semibold">Describe your problem</span>
                </label>
                <textarea
                  name="query"
                  class="textarea textarea-bordered h-24"
                  placeholder="e.g., How to implement rate limiting in Phoenix..."
                  phx-debounce="300"
                >{@query}</textarea>
              </div>
            </form>

            <div class="divider">Filters</div>

            <form phx-change="update_filter" class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text text-sm">Language</span>
                </label>
                <input
                  type="text"
                  name="filter[language]"
                  class="input input-bordered input-sm"
                  placeholder="elixir, python..."
                  value={Enum.join(@tag_filters.language, ", ")}
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text text-sm">Framework</span>
                </label>
                <input
                  type="text"
                  name="filter[framework]"
                  class="input input-bordered input-sm"
                  placeholder="phoenix, django..."
                  value={Enum.join(@tag_filters.framework, ", ")}
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text text-sm">Domain</span>
                </label>
                <input
                  type="text"
                  name="filter[domain]"
                  class="input input-bordered input-sm"
                  placeholder="api, database..."
                  value={Enum.join(@tag_filters.domain, ", ")}
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text text-sm">Platform</span>
                </label>
                <input
                  type="text"
                  name="filter[platform]"
                  class="input input-bordered input-sm"
                  placeholder="aws, docker..."
                  value={Enum.join(@tag_filters.platform, ", ")}
                />
              </div>
            </form>
          </div>
        </div>

        <div :if={@searching} class="flex justify-center py-8">
          <span class="loading loading-spinner loading-lg text-primary"></span>
        </div>

        <div :if={not @searching and @searched}>
          <div class="flex justify-between items-center mb-4">
            <p class="text-base-content/70">
              {if @total == 0, do: "No results found", else: "#{@total} result#{if @total != 1, do: "s"} found"}
            </p>

            <div :if={@total > 0} class="flex items-center gap-2">
              <span class="text-sm text-base-content/70">Sort:</span>
              <div class="join">
                <button
                  class={"join-item btn btn-xs #{if @sort == :relevance, do: "btn-primary", else: "btn-ghost"}"}
                  phx-click="sort"
                  phx-value-sort="relevance"
                >
                  Relevance
                </button>
                <button
                  class={"join-item btn btn-xs #{if @sort == :top_voted, do: "btn-primary", else: "btn-ghost"}"}
                  phx-click="sort"
                  phx-value-sort="top_voted"
                >
                  Top Voted
                </button>
                <button
                  class={"join-item btn btn-xs #{if @sort == :newest, do: "btn-primary", else: "btn-ghost"}"}
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

        <div :if={not @searching and not @searched} class="text-center py-16 bg-base-200 rounded-lg">
          <p class="text-xl text-base-content/70">Enter a problem description to search</p>
          <p class="text-sm text-base-content/50 mt-2">
            Our semantic search will find similar solutions
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp no_results(assigns) do
    ~H"""
    <div class="text-center py-12 bg-base-200 rounded-lg">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-16 h-16 mx-auto text-base-content/30 mb-4">
        <path fill-rule="evenodd" d="M10.5 3.75a6.75 6.75 0 1 0 0 13.5 6.75 6.75 0 0 0 0-13.5ZM2.25 10.5a8.25 8.25 0 1 1 14.59 5.28l4.69 4.69a.75.75 0 1 1-1.06 1.06l-4.69-4.69A8.25 8.25 0 0 1 2.25 10.5Z" clip-rule="evenodd" />
      </svg>
      <p class="text-lg text-base-content/70">No solutions found for "{@query}"</p>
      <p class="text-sm text-base-content/50 mt-2">
        Try different keywords or remove some filters
      </p>
    </div>
    """
  end

  defp result_card(assigns) do
    score = assigns.result.upvotes - assigns.result.downvotes
    assigns = assign(assigns, :score, score)

    ~H"""
    <div class="card bg-base-100 shadow-md hover:shadow-lg transition-shadow">
      <div class="card-body">
        <div class="flex justify-between items-start gap-4">
          <div class="flex-1">
            <h2 class="card-title text-lg">
              <.link navigate={~p"/solutions/#{@result.id}"} class="hover:text-primary">
                {truncate(@result.problem_description, 100)}
              </.link>
            </h2>
            <p class="text-sm text-base-content/70 mt-2 line-clamp-2">
              {truncate(@result.solution_pattern, 150)}
            </p>
          </div>

          <div class="flex flex-col items-end gap-2">
            <div class="badge badge-primary badge-outline">
              {Float.round(@result.similarity * 100, 1)}% match
            </div>
            <div class={"text-sm font-semibold #{score_color(@score)}"}>
              {if @score >= 0, do: "+", else: ""}{@score}
            </div>
          </div>
        </div>

        <.tags tags={@result.tags} />
      </div>
    </div>
    """
  end

  defp tags(assigns) do
    all_tags = flatten_tags(assigns.tags)
    assigns = assign(assigns, :all_tags, all_tags)

    ~H"""
    <div :if={length(@all_tags) > 0} class="flex flex-wrap gap-1 mt-3">
      <span
        :for={tag <- Enum.take(@all_tags, 6)}
        class={"badge badge-sm #{tag_color(tag.category)}"}
      >
        {tag.value}
      </span>
      <span :if={length(@all_tags) > 6} class="badge badge-sm badge-ghost">
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

  defp tag_color("language"), do: "badge-primary"
  defp tag_color(:language), do: "badge-primary"
  defp tag_color("framework"), do: "badge-secondary"
  defp tag_color(:framework), do: "badge-secondary"
  defp tag_color("domain"), do: "badge-accent"
  defp tag_color(:domain), do: "badge-accent"
  defp tag_color("platform"), do: "badge-info"
  defp tag_color(:platform), do: "badge-info"
  defp tag_color(_), do: "badge-ghost"

  defp score_color(score) when score > 0, do: "text-success"
  defp score_color(score) when score < 0, do: "text-error"
  defp score_color(_), do: "text-base-content/70"

  defp truncate(text, max_length) when is_binary(text) and byte_size(text) > max_length do
    String.slice(text, 0, max_length) <> "..."
  end
  defp truncate(text, _max_length), do: text
end
