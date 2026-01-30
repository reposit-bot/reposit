defmodule ChorusWeb.SolutionsLive.Index do
  use ChorusWeb, :live_view

  alias Chorus.Solutions
  alias Chorus.Solutions.Solution

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

  defp sort_to_param(:inserted_at), do: "newest"
  defp sort_to_param(:upvotes), do: "votes"
  defp sort_to_param(:score), do: "score"

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
      <div class="container mx-auto px-4 py-8 max-w-6xl">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
          <div>
            <h1 class="text-3xl font-bold">Solutions</h1>
            <p class="text-base-content/70 mt-1">
              {@total} solution{if @total != 1, do: "s"} shared by the community
            </p>
          </div>

          <div class="flex items-center gap-2">
            <span class="text-sm text-base-content/70">Sort by:</span>
            <div class="join">
              <button
                class={"join-item btn btn-sm #{if @sort == :score, do: "btn-primary", else: "btn-ghost"}"}
                phx-click="sort"
                phx-value-sort="score"
              >
                Score
              </button>
              <button
                class={"join-item btn btn-sm #{if @sort == :upvotes, do: "btn-primary", else: "btn-ghost"}"}
                phx-click="sort"
                phx-value-sort="votes"
              >
                Votes
              </button>
              <button
                class={"join-item btn btn-sm #{if @sort == :inserted_at, do: "btn-primary", else: "btn-ghost"}"}
                phx-click="sort"
                phx-value-sort="newest"
              >
                Newest
              </button>
            </div>
          </div>
        </div>

        <div
          :if={@total == 0}
          class="text-center py-16 bg-base-200 rounded-lg"
        >
          <p class="text-xl text-base-content/70">No solutions yet</p>
          <p class="text-sm text-base-content/50 mt-2">Be the first to contribute!</p>
        </div>

        <div
          id="solutions"
          phx-update="stream"
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          <.solution_card :for={{dom_id, solution} <- @streams.solutions} id={dom_id} solution={solution} />
        </div>

        <!-- Infinite scroll sentinel -->
        <div
          :if={not @end_of_list and @total > 0}
          id="infinite-scroll-sentinel"
          phx-hook="InfiniteScroll"
          class="flex justify-center py-8"
        >
          <span :if={@loading} class="loading loading-spinner loading-lg text-primary"></span>
          <span :if={not @loading} class="text-base-content/50 text-sm">Scroll for more...</span>
        </div>

        <!-- End of list message -->
        <div
          :if={@end_of_list and @total > 0}
          class="text-center py-8 text-base-content/50"
        >
          <p>You've reached the end!</p>
          <p class="text-sm mt-1">{@total} solutions total</p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp solution_card(assigns) do
    ~H"""
    <div id={@id} class="card bg-base-100 shadow-md hover:shadow-lg transition-shadow">
      <div class="card-body">
        <h2 class="card-title text-base line-clamp-2">
          <.link navigate={~p"/solutions/#{@solution.id}"} class="hover:text-primary">
            {truncate(@solution.problem_description, 80)}
          </.link>
        </h2>

        <p class="text-sm text-base-content/70 line-clamp-3 flex-grow">
          {truncate(@solution.solution_pattern, 120)}
        </p>

        <.tags tags={@solution.tags} />

        <div class="card-actions justify-between items-center mt-4 pt-4 border-t border-base-200">
          <.vote_display solution={@solution} />
          <span class="text-xs text-base-content/50">
            {format_date(@solution.inserted_at)}
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp tags(assigns) do
    all_tags = flatten_tags(assigns.tags)
    assigns = assign(assigns, :all_tags, all_tags)

    ~H"""
    <div :if={length(@all_tags) > 0} class="flex flex-wrap gap-1 mt-2">
      <span
        :for={tag <- Enum.take(@all_tags, 5)}
        class={"badge badge-sm #{tag_color(tag.category)}"}
      >
        {tag.value}
      </span>
      <span :if={length(@all_tags) > 5} class="badge badge-sm badge-ghost">
        +{length(@all_tags) - 5}
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

  defp vote_display(assigns) do
    score = Solution.score(assigns.solution)
    assigns = assign(assigns, :score, score)

    ~H"""
    <div class="flex items-center gap-3 text-sm">
      <span class="flex items-center gap-1 text-success">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">
          <path fill-rule="evenodd" d="M10 17a.75.75 0 0 1-.75-.75V5.612L5.29 9.77a.75.75 0 0 1-1.08-1.04l5.25-5.5a.75.75 0 0 1 1.08 0l5.25 5.5a.75.75 0 1 1-1.08 1.04l-3.96-4.158V16.25A.75.75 0 0 1 10 17Z" clip-rule="evenodd" />
        </svg>
        {@solution.upvotes}
      </span>
      <span class="flex items-center gap-1 text-error">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">
          <path fill-rule="evenodd" d="M10 3a.75.75 0 0 1 .75.75v10.638l3.96-4.158a.75.75 0 1 1 1.08 1.04l-5.25 5.5a.75.75 0 0 1-1.08 0l-5.25-5.5a.75.75 0 1 1 1.08-1.04l3.96 4.158V3.75A.75.75 0 0 1 10 3Z" clip-rule="evenodd" />
        </svg>
        {@solution.downvotes}
      </span>
      <span class={"font-semibold #{score_color(@score)}"}>
        ({if @score >= 0, do: "+", else: ""}{@score})
      </span>
    </div>
    """
  end

  defp score_color(score) when score > 0, do: "text-success"
  defp score_color(score) when score < 0, do: "text-error"
  defp score_color(_), do: "text-base-content/70"

  defp truncate(text, max_length) when is_binary(text) and byte_size(text) > max_length do
    String.slice(text, 0, max_length) <> "..."
  end
  defp truncate(text, _max_length), do: text

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%b %d, %Y")
  end
  defp format_date(_), do: ""
end
