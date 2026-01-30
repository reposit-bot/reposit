defmodule ChorusWeb.SolutionsLive.Show do
  @moduledoc """
  LiveView for displaying a single solution's details.

  Includes full problem description, solution pattern with markdown rendering,
  tags grouped by category, vote breakdown, and recent vote comments.
  """
  use ChorusWeb, :live_view

  alias Chorus.Solutions
  alias Chorus.Solutions.Solution

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Solutions.get_solution_with_votes(id, votes_limit: 10) do
      {:ok, solution} ->
        {:ok,
         socket
         |> assign(:solution, solution)
         |> assign(:markdown_html, render_markdown(solution.solution_pattern))}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Solution not found")
         |> redirect(to: ~p"/solutions")}
    end
  end

  defp render_markdown(nil), do: ""
  defp render_markdown(text) do
    case MDEx.to_html(text, extension: [autolink: true, strikethrough: true]) do
      {:ok, html} -> html
      {:error, _} -> text
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="container mx-auto px-4 py-8 max-w-4xl">
        <div class="mb-6">
          <.link navigate={~p"/solutions"} class="btn btn-ghost btn-sm gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">
              <path fill-rule="evenodd" d="M17 10a.75.75 0 0 1-.75.75H5.612l4.158 3.96a.75.75 0 1 1-1.04 1.08l-5.5-5.25a.75.75 0 0 1 0-1.08l5.5-5.25a.75.75 0 1 1 1.04 1.08L5.612 9.25H16.25A.75.75 0 0 1 17 10Z" clip-rule="evenodd" />
            </svg>
            Back to Solutions
          </.link>
        </div>

        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h1 class="card-title text-2xl mb-4">{@solution.problem_description}</h1>

            <.vote_stats solution={@solution} />

            <div class="divider">Solution</div>

            <div class="prose max-w-none">
              {Phoenix.HTML.raw(@markdown_html)}
            </div>

            <.tags_by_category tags={@solution.tags} />

            <.vote_comments votes={@solution.votes} />

            <div class="mt-6 pt-6 border-t border-base-200 flex justify-between items-center text-sm text-base-content/50">
              <span>Created {format_date(@solution.inserted_at)}</span>
              <span :if={@solution.updated_at != @solution.inserted_at}>
                Updated {format_date(@solution.updated_at)}
              </span>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp vote_stats(assigns) do
    score = Solution.score(assigns.solution)
    total_votes = assigns.solution.upvotes + assigns.solution.downvotes
    upvote_percent = if total_votes > 0, do: round(assigns.solution.upvotes / total_votes * 100), else: 0

    assigns =
      assigns
      |> assign(:score, score)
      |> assign(:total_votes, total_votes)
      |> assign(:upvote_percent, upvote_percent)

    ~H"""
    <div class="stats shadow bg-base-200 w-full">
      <div class="stat">
        <div class="stat-figure text-success">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-8 h-8">
            <path fill-rule="evenodd" d="M12 20.25a.75.75 0 0 1-.75-.75V6.31l-5.47 5.47a.75.75 0 0 1-1.06-1.06l6.75-6.75a.75.75 0 0 1 1.06 0l6.75 6.75a.75.75 0 1 1-1.06 1.06l-5.47-5.47V19.5a.75.75 0 0 1-.75.75Z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="stat-title">Upvotes</div>
        <div class="stat-value text-success">{@solution.upvotes}</div>
      </div>

      <div class="stat">
        <div class="stat-figure text-error">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-8 h-8">
            <path fill-rule="evenodd" d="M12 3.75a.75.75 0 0 1 .75.75v13.19l5.47-5.47a.75.75 0 1 1 1.06 1.06l-6.75 6.75a.75.75 0 0 1-1.06 0l-6.75-6.75a.75.75 0 1 1 1.06-1.06l5.47 5.47V4.5a.75.75 0 0 1 .75-.75Z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="stat-title">Downvotes</div>
        <div class="stat-value text-error">{@solution.downvotes}</div>
      </div>

      <div class="stat">
        <div class="stat-figure text-primary">
          <div class="radial-progress text-primary" style={"--value:#{@upvote_percent}; --size:3.5rem;"} role="progressbar">
            {@upvote_percent}%
          </div>
        </div>
        <div class="stat-title">Score</div>
        <div class={"stat-value #{score_color(@score)}"}>
          {if @score >= 0, do: "+", else: ""}{@score}
        </div>
        <div class="stat-desc">{@total_votes} total votes</div>
      </div>
    </div>
    """
  end

  defp tags_by_category(assigns) do
    grouped = group_tags(assigns.tags)
    assigns = assign(assigns, :grouped, grouped)

    ~H"""
    <div :if={map_size(@grouped) > 0} class="mt-6">
      <div class="divider">Tags</div>
      <div class="flex flex-wrap gap-4">
        <div :for={{category, values} <- @grouped} class="flex flex-col gap-1">
          <span class="text-xs font-semibold uppercase text-base-content/50">
            {category}
          </span>
          <div class="flex flex-wrap gap-1">
            <span
              :for={value <- values}
              class={"badge #{tag_color(category)}"}
            >
              {value}
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp group_tags(nil), do: %{}
  defp group_tags(tags) when is_map(tags) do
    tags
    |> Enum.filter(fn {_k, v} -> is_list(v) and length(v) > 0 end)
    |> Enum.into(%{})
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

  defp vote_comments(assigns) do
    # Filter to only votes with comments (downvotes)
    comments = Enum.filter(assigns.votes, &(&1.comment && &1.comment != ""))
    assigns = assign(assigns, :comments, comments)

    ~H"""
    <div :if={length(@comments) > 0} class="mt-6">
      <div class="divider">Recent Feedback</div>
      <div class="space-y-4">
        <div :for={vote <- @comments} class="chat chat-start">
          <div class="chat-bubble chat-bubble-error">
            <div class="flex items-center gap-2 mb-1">
              <span class="badge badge-sm">{reason_label(vote.reason)}</span>
              <span class="text-xs opacity-70">{format_date(vote.inserted_at)}</span>
            </div>
            <p>{vote.comment}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp reason_label(:incorrect), do: "Incorrect"
  defp reason_label(:outdated), do: "Outdated"
  defp reason_label(:incomplete), do: "Incomplete"
  defp reason_label(:harmful), do: "Harmful"
  defp reason_label(:duplicate), do: "Duplicate"
  defp reason_label(:other), do: "Other"
  defp reason_label(_), do: "Feedback"

  defp score_color(score) when score > 0, do: "text-success"
  defp score_color(score) when score < 0, do: "text-error"
  defp score_color(_), do: "text-base-content"

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%B %d, %Y")
  end
  defp format_date(_), do: ""
end
