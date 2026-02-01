defmodule RepositWeb.SolutionsLive.Index do
  use RepositWeb, :live_view

  alias Reposit.Solutions

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
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <!-- Header -->
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div>
            <h1 class="page-title">Solutions</h1>
            <p class="page-subtitle mt-1">
              {@total} solution{if @total != 1, do: "s"} shared by the community
            </p>
          </div>

          <div class="flex items-center gap-2 sm:gap-3">
            <span class="text-xs text-base-content/60 hidden sm:inline">Sort:</span>
            <div role="tablist" class="tabs tabs-boxed tabs-sm">
              <button
                role="tab"
                class={"tab #{if @sort == :score, do: "tab-active"}"}
                phx-click="sort"
                phx-value-sort="score"
              >
                Score
              </button>
              <button
                role="tab"
                class={"tab #{if @sort == :upvotes, do: "tab-active"}"}
                phx-click="sort"
                phx-value-sort="votes"
              >
                Votes
              </button>
              <button
                role="tab"
                class={"tab #{if @sort == :inserted_at, do: "tab-active"}"}
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
          class="card bg-base-100 shadow-lg"
        >
          <div class="card-body items-center text-center py-16">
            <div class="w-16 h-16 mb-2 rounded-2xl bg-base-200 flex items-center justify-center">
              <.icon name="lightbulb" class="size-8 text-base-content/40" />
            </div>
            <p class="text-lg font-semibold">No solutions yet</p>
            <p class="text-base-content/60">Be the first to contribute!</p>
          </div>
        </div>
        
    <!-- Solutions List -->
        <div
          :if={@total > 0}
          id="solutions"
          phx-update="stream"
          class="card card-bordered bg-base-100 divide-y divide-base-300"
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
          <div :if={@loading} class="flex items-center gap-3 text-primary">
            <span class="loading loading-spinner loading-sm"></span>
            <span class="text-sm font-medium">Loading...</span>
          </div>
          <span :if={not @loading} class="text-base-content/60 text-sm">Scroll for more...</span>
        </div>
        
    <!-- End of list message -->
        <div
          :if={@end_of_list and @total > 0}
          class="text-center py-8 text-base-content/60"
        >
          <p>You've reached the end!</p>
          <p class="text-sm mt-1 mono">{@total} solutions total</p>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
