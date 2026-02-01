defmodule RepositWeb.ModerationLive do
  @moduledoc """
  LiveView for the moderation queue.

  Allows moderators to review flagged solutions (high downvote ratios)
  and take action: approve (keep) or archive (soft delete).
  """
  use RepositWeb, :live_view

  alias Reposit.Solutions
  alias Reposit.Votes.Vote

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:reason_filter, nil)
     |> load_flagged_solutions()}
  end

  @impl true
  def handle_event("filter_reason", %{"reason" => ""}, socket) do
    {:noreply,
     socket
     |> assign(:reason_filter, nil)
     |> load_flagged_solutions()}
  end

  @impl true
  def handle_event("filter_reason", %{"reason" => reason}, socket) do
    reason_atom = String.to_existing_atom(reason)

    {:noreply,
     socket
     |> assign(:reason_filter, reason_atom)
     |> load_flagged_solutions()}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    case Solutions.approve_solution(id) do
      {:ok, _solution} ->
        {:noreply,
         socket
         |> put_flash(:info, "Solution approved")
         |> load_flagged_solutions()}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Solution not found")}
    end
  end

  @impl true
  def handle_event("archive", %{"id" => id}, socket) do
    case Solutions.archive_solution(id) do
      {:ok, _solution} ->
        {:noreply,
         socket
         |> put_flash(:info, "Solution archived")
         |> load_flagged_solutions()}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Solution not found")}
    end
  end

  defp load_flagged_solutions(socket) do
    opts =
      case socket.assigns.reason_filter do
        nil -> []
        reason -> [reason: reason]
      end

    solutions = Solutions.list_flagged_solutions(opts)
    assign(socket, :solutions, solutions)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto px-4 py-8 max-w-6xl">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
          <div>
            <h1 class="text-3xl font-bold">Moderation Queue</h1>
            <p class="text-base-content/70 mt-1">
              {length(@solutions)} solution{if length(@solutions) != 1, do: "s"} flagged for review
            </p>
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text">Filter by reason:</span>
            </label>
            <select
              class="select select-bordered select-sm"
              phx-change="filter_reason"
              name="reason"
            >
              <option value="">All reasons</option>
              <%= for reason <- Vote.downvote_reasons() do %>
                <option value={reason} selected={@reason_filter == reason}>
                  {reason_label(reason)}
                </option>
              <% end %>
            </select>
          </div>
        </div>

        <div :if={length(@solutions) == 0} class="text-center py-16 bg-base-200 rounded-lg">
          <Lucideicons.check_circle class="w-16 h-16 mx-auto text-success mb-4" />
          <p class="text-xl text-base-content/70">No flagged solutions</p>
          <p class="text-sm text-base-content/50 mt-2">
            All solutions are looking good!
          </p>
        </div>
        
    <!-- Mobile: Card layout -->
        <div :if={length(@solutions) > 0} class="space-y-4 md:hidden">
          <div :for={solution <- @solutions} class="card bg-base-200">
            <div class="card-body p-4">
              <.link
                navigate={~p"/solutions/#{solution.id}"}
                class="card-title text-base hover:text-primary"
              >
                {truncate(solution.problem, 80)}
              </.link>
              <.solution_tags tags={solution.tags} limit={3} class="mt-1" />

              <div class="flex items-center gap-4 mt-2">
                <div class="flex items-center gap-2">
                  <span class="text-success font-medium">+{solution.upvotes}</span>
                  <span class="text-error font-medium">-{solution.downvotes}</span>
                </div>
                <.feedback_list votes={solution.votes} />
              </div>

              <div class="card-actions justify-end mt-3">
                <button
                  class="btn btn-sm btn-success"
                  phx-click="approve"
                  phx-value-id={solution.id}
                >
                  Approve
                </button>
                <button
                  class="btn btn-sm btn-error"
                  phx-click="archive"
                  phx-value-id={solution.id}
                >
                  Archive
                </button>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Desktop: Table layout -->
        <div :if={length(@solutions) > 0} class="hidden md:block overflow-x-auto">
          <table class="table table-zebra">
            <thead>
              <tr>
                <th>Problem</th>
                <th class="text-center">Votes</th>
                <th>Feedback</th>
                <th class="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={solution <- @solutions}>
                <td class="max-w-md">
                  <.link
                    navigate={~p"/solutions/#{solution.id}"}
                    class="hover:text-primary font-medium"
                  >
                    {truncate(solution.problem, 60)}
                  </.link>
                  <.solution_tags tags={solution.tags} limit={3} class="mt-1" />
                </td>
                <td class="text-center">
                  <div class="flex flex-col items-center gap-1">
                    <span class="text-success">+{solution.upvotes}</span>
                    <span class="text-error">-{solution.downvotes}</span>
                  </div>
                </td>
                <td>
                  <.feedback_list votes={solution.votes} />
                </td>
                <td class="text-right">
                  <div class="join">
                    <button
                      class="btn btn-sm btn-success join-item"
                      phx-click="approve"
                      phx-value-id={solution.id}
                    >
                      Approve
                    </button>
                    <button
                      class="btn btn-sm btn-error join-item"
                      phx-click="archive"
                      phx-value-id={solution.id}
                    >
                      Archive
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp feedback_list(assigns) do
    # Get unique reasons from votes
    reasons =
      assigns.votes
      |> Enum.filter(& &1.reason)
      |> Enum.map(& &1.reason)
      |> Enum.frequencies()

    # Get first comment
    first_comment =
      assigns.votes
      |> Enum.find(& &1.comment)

    assigns =
      assigns
      |> assign(:reasons, reasons)
      |> assign(:first_comment, first_comment)

    ~H"""
    <div class="space-y-2">
      <div class="flex flex-wrap gap-1">
        <span
          :for={{reason, count} <- @reasons}
          class="badge badge-sm badge-outline"
        >
          {reason_label(reason)} ({count})
        </span>
      </div>
      <p :if={@first_comment} class="text-sm text-base-content/70 line-clamp-2">
        "{@first_comment.comment}"
      </p>
    </div>
    """
  end

  defp reason_label(:incorrect), do: "Incorrect"
  defp reason_label(:outdated), do: "Outdated"
  defp reason_label(:incomplete), do: "Incomplete"
  defp reason_label(:harmful), do: "Harmful"
  defp reason_label(:duplicate), do: "Duplicate"
  defp reason_label(:other), do: "Other"
  defp reason_label(_), do: "Unknown"

  defp truncate(text, max_length) when is_binary(text) and byte_size(text) > max_length do
    String.slice(text, 0, max_length) <> "..."
  end

  defp truncate(text, _max_length), do: text
end
