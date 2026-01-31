defmodule RepositWeb.SolutionsLive.Index do
  use RepositWeb, :live_view

  alias Reposit.Solutions
  alias Reposit.Solutions.Solution

  @per_page 12

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Browse Solutions")
     |> assign(:page, 1)
     |> assign(:sort, :score)
     |> assign(:per_page, @per_page)
     |> assign(:loading, false)
     |> assign(:end_of_list, false)
     |> stream(:solutions, [])
     |> load_initial_solutions()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    sort = parse_sort(params["sort"])

    # Only reload if sort changed
    if sort != socket.assigns.sort do
      {:noreply,
       socket
       |> assign(:sort, sort)
       |> assign(:page, 1)
       |> assign(:end_of_list, false)
       |> stream(:solutions, [], reset: true)
       |> load_initial_solutions()}
    else
      {:noreply, socket}
    end
  end

  defp parse_sort("newest"), do: :inserted_at
  defp parse_sort("votes"), do: :upvotes
  defp parse_sort("score"), do: :score
  defp parse_sort(_), do: :score

  defp load_initial_solutions(socket) do
    %{sort: sort, per_page: per_page} = socket.assigns

    solutions = Solutions.list_solutions(limit: per_page, offset: 0, order_by: sort)
    total = Solutions.count_solutions()
    end_of_list = length(solutions) < per_page

    socket
    |> stream(:solutions, solutions, reset: true)
    |> assign(:total, total)
    |> assign(:end_of_list, end_of_list)
  end

  @impl true
  def handle_event("sort", %{"sort" => sort}, socket) do
    {:noreply, push_patch(socket, to: ~p"/solutions?sort=#{sort}")}
  end

  @impl true
  def handle_event("load-more", _params, socket) do
    if socket.assigns.loading || socket.assigns.end_of_list do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> assign(:loading, true)
       |> load_more_solutions()}
    end
  end

  defp load_more_solutions(socket) do
    %{page: page, sort: sort, per_page: per_page} = socket.assigns

    next_page = page + 1
    offset = page * per_page

    solutions = Solutions.list_solutions(limit: per_page, offset: offset, order_by: sort)
    end_of_list = length(solutions) < per_page

    socket
    |> stream(:solutions, solutions)
    |> assign(:page, next_page)
    |> assign(:loading, false)
    |> assign(:end_of_list, end_of_list)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-8">
        <!-- Header -->
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div>
            <h1 class="page-title">Solutions</h1>
            <p class="page-subtitle mt-1">
              {@total} solution{if @total != 1, do: "s"} shared by the community
            </p>
          </div>

          <div class="flex items-center gap-3">
            <span class="text-xs text-muted">Sort:</span>
            <div class="flex rounded-full bg-[oklch(96%_0.01_280)] dark:bg-[oklch(22%_0.02_280)] p-1 border border-[oklch(90%_0.02_280)] dark:border-[oklch(30%_0.025_280)]">
              <button
                class={"px-3 py-1.5 text-xs font-medium rounded-full transition-all #{if @sort == :score, do: "bg-white dark:bg-[oklch(32%_0.03_280)] text-[oklch(35%_0.05_280)] dark:text-[oklch(90%_0.02_280)] shadow-sm", else: "text-muted hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(85%_0.02_280)]"}"}
                phx-click="sort"
                phx-value-sort="score"
              >
                Score
              </button>
              <button
                class={"px-3 py-1.5 text-xs font-medium rounded-full transition-all #{if @sort == :upvotes, do: "bg-white dark:bg-[oklch(32%_0.03_280)] text-[oklch(35%_0.05_280)] dark:text-[oklch(90%_0.02_280)] shadow-sm", else: "text-muted hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(85%_0.02_280)]"}"}
                phx-click="sort"
                phx-value-sort="votes"
              >
                Votes
              </button>
              <button
                class={"px-3 py-1.5 text-xs font-medium rounded-full transition-all #{if @sort == :inserted_at, do: "bg-white dark:bg-[oklch(32%_0.03_280)] text-[oklch(35%_0.05_280)] dark:text-[oklch(90%_0.02_280)] shadow-sm", else: "text-muted hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(85%_0.02_280)]"}"}
                phx-click="sort"
                phx-value-sort="newest"
              >
                Newest
              </button>
            </div>
          </div>
        </div>

    <!-- Empty State -->
        <div
          :if={@total == 0}
          class="card-reposit p-16 text-center"
        >
          <div class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-[oklch(94%_0.02_280)] dark:bg-[oklch(28%_0.025_280)] flex items-center justify-center">
            <.icon name="lightbulb" class="size-8 text-muted" />
          </div>
          <p class="text-lg font-medium text-[oklch(35%_0.02_280)] dark:text-[oklch(85%_0.02_280)]">
            No solutions yet
          </p>
          <p class="text-sm text-muted mt-2">Be the first to contribute!</p>
        </div>

    <!-- Solutions List -->
        <div
          :if={@total > 0}
          id="solutions"
          phx-update="stream"
          class="card-reposit divide-y divide-[oklch(92%_0.02_280)] dark:divide-[oklch(28%_0.025_280)]"
        >
          <.solution_row
            :for={{dom_id, solution} <- @streams.solutions}
            id={dom_id}
            solution={solution}
          />
        </div>

    <!-- Infinite scroll sentinel -->
        <div
          :if={not @end_of_list and @total > 0}
          id="infinite-scroll-sentinel"
          phx-hook="InfiniteScroll"
          class="flex justify-center py-8"
        >
          <div :if={@loading} class="flex items-center gap-3 text-[oklch(55%_0.15_280)]">
            <Lucideicons.loader_2 class="animate-spin h-5 w-5" />
            <span class="text-sm font-medium">Loading...</span>
          </div>
          <span :if={not @loading} class="text-muted text-sm">Scroll for more...</span>
        </div>

    <!-- End of list message -->
        <div
          :if={@end_of_list and @total > 0}
          class="text-center py-8 text-muted"
        >
          <p>You've reached the end!</p>
          <p class="text-sm mt-1 mono">{@total} solutions total</p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp solution_row(assigns) do
    score = Solution.score(assigns.solution)
    assigns = assign(assigns, :score, score)

    ~H"""
    <a
      href={~p"/solutions/#{@solution.id}"}
      id={@id}
      class="flex gap-4 p-5 hover:bg-[oklch(97%_0.005_280)] dark:hover:bg-[oklch(24%_0.02_280)] transition-colors block"
    >
      <!-- Vote score on the left -->
      <div class="flex flex-col items-center justify-start min-w-[56px] pt-0.5">
        <span class={"text-lg font-bold mono #{score_color(@score)}"}>
          {if @score >= 0, do: "+", else: ""}{@score}
        </span>
        <span class="text-[0.7rem] text-muted mono">
          {@solution.upvotes}↑ {downvotes(@solution)}↓
        </span>
      </div>

    <!-- Main content -->
      <div class="flex-1 min-w-0">
        <h3 class="font-medium text-[oklch(25%_0.02_280)] dark:text-[oklch(92%_0.01_280)] line-clamp-1">
          {truncate(@solution.problem_description, 100)}
        </h3>
        <p class="text-sm text-muted mt-1.5 line-clamp-2">
          {truncate(@solution.solution_pattern, 180)}
        </p>

        <div class="flex items-center gap-3 mt-3">
          <.inline_tags tags={@solution.tags} />
          <span class="text-xs text-muted">
            {format_date(@solution.inserted_at)}
          </span>
        </div>
      </div>
    </a>
    """
  end

  defp downvotes(solution), do: solution.downvotes

  defp inline_tags(assigns) do
    all_tags = flatten_tags(assigns.tags)
    assigns = assign(assigns, :all_tags, all_tags)

    ~H"""
    <div :if={length(@all_tags) > 0} class="flex flex-wrap gap-1.5">
      <span
        :for={tag <- Enum.take(@all_tags, 3)}
        class={"badge-reposit text-[0.65rem] py-0.5 px-2 #{tag_color(tag.category)}"}
      >
        {tag.value}
      </span>
      <span :if={length(@all_tags) > 3} class="badge-reposit text-[0.65rem] py-0.5 px-2">
        +{length(@all_tags) - 3}
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

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%b %d, %Y")
  end

  defp format_date(_), do: ""
end
