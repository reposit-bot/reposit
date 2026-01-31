defmodule RepositWeb.SolutionsLive.Show do
  @moduledoc """
  LiveView for displaying a single solution's details.

  Includes full problem description, solution pattern with markdown rendering,
  tags grouped by category, vote breakdown, and recent vote comments.
  """
  use RepositWeb, :live_view

  alias Reposit.Solutions
  alias Reposit.Solutions.Solution

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
    score = Solution.score(assigns.solution)
    assigns = assign(assigns, :score, score)

    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <!-- Back link -->
        <a
          href={~p"/solutions"}
          class="inline-flex items-center gap-2 text-sm text-muted hover:text-[oklch(35%_0.05_280)] dark:hover:text-[oklch(85%_0.02_280)] transition-colors"
        >
          <Lucideicons.arrow_left class="w-4 h-4" /> Back to Solutions
        </a>

    <!-- Main content card -->
        <div class="card-reposit p-6 lg:p-8">
          <!-- Problem section -->
          <div class="mb-8">
            <div class="flex items-center gap-3 mb-3">
              <span class="text-xs font-semibold uppercase tracking-wider text-muted">Problem</span>
              <.inline_tags tags={@solution.tags} />
            </div>
            <p class="text-[oklch(25%_0.02_280)] dark:text-[oklch(90%_0.01_280)] text-lg leading-relaxed">
              {@solution.problem_description}
            </p>
          </div>

    <!-- Vote stats - compact horizontal -->
          <div class="flex flex-wrap items-center gap-4 sm:gap-6 py-4 px-4 sm:px-5 rounded-2xl bg-[oklch(97%_0.005_280)] dark:bg-[oklch(20%_0.015_280)] mb-8">
            <div class="flex items-center gap-2">
              <Lucideicons.arrow_up class="w-4 h-4 sm:w-5 sm:h-5 text-[oklch(55%_0.15_145)]" />
              <span class="mono font-semibold text-[oklch(55%_0.15_145)]">{@solution.upvotes}</span>
              <span class="text-xs text-muted">upvotes</span>
            </div>

            <div class="flex items-center gap-2">
              <Lucideicons.arrow_down class="w-4 h-4 sm:w-5 sm:h-5 text-[oklch(60%_0.2_25)]" />
              <span class="mono font-semibold text-[oklch(60%_0.2_25)]">{@solution.downvotes}</span>
              <span class="text-xs text-muted">downvotes</span>
            </div>

            <div class="hidden sm:block h-6 w-px bg-[oklch(90%_0.02_280)] dark:bg-[oklch(30%_0.025_280)]"></div>

            <div class="flex items-center gap-2">
              <span class={"mono text-lg sm:text-xl font-bold #{score_color(@score)}"}>
                {if @score >= 0, do: "+", else: ""}{@score}
              </span>
              <span class="text-xs text-muted">score</span>
            </div>
          </div>

    <!-- Solution section -->
          <div>
            <span class="text-xs font-semibold uppercase tracking-wider text-muted mb-4 block">
              Solution
            </span>
            <div class="prose prose-slate dark:prose-invert max-w-none prose-headings:font-semibold prose-headings:text-[oklch(25%_0.02_280)] dark:prose-headings:text-[oklch(90%_0.01_280)] prose-p:text-[oklch(35%_0.02_280)] dark:prose-p:text-[oklch(75%_0.02_280)] prose-code:bg-[oklch(95%_0.01_280)] dark:prose-code:bg-[oklch(25%_0.02_280)] prose-code:px-1.5 prose-code:py-0.5 prose-code:rounded-md prose-code:before:content-none prose-code:after:content-none prose-pre:bg-[oklch(20%_0.015_280)] prose-pre:rounded-xl">
              {Phoenix.HTML.raw(@markdown_html)}
            </div>
          </div>

    <!-- Tags by category -->
          <.tags_by_category tags={@solution.tags} />

    <!-- Vote comments -->
          <.vote_comments votes={@solution.votes} />

    <!-- Metadata footer -->
          <div class="mt-8 pt-6 border-t border-[oklch(92%_0.02_280)] dark:border-[oklch(28%_0.025_280)] flex flex-wrap gap-4 text-xs text-muted">
            <span>Created {format_date(@solution.inserted_at)}</span>
            <span :if={@solution.updated_at != @solution.inserted_at}>
              · Updated {format_date(@solution.updated_at)}
            </span>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp inline_tags(assigns) do
    all_tags = flatten_tags(assigns.tags)
    assigns = assign(assigns, :all_tags, Enum.take(all_tags, 4))

    ~H"""
    <div :if={length(@all_tags) > 0} class="flex flex-wrap gap-1.5">
      <span
        :for={tag <- @all_tags}
        class={"badge-reposit text-[0.65rem] py-0.5 px-2 #{tag_color(tag.category)}"}
      >
        {tag.value}
      </span>
    </div>
    """
  end

  defp tags_by_category(assigns) do
    grouped = group_tags(assigns.tags)
    assigns = assign(assigns, :grouped, grouped)

    ~H"""
    <div
      :if={map_size(@grouped) > 0}
      class="mt-8 pt-6 border-t border-[oklch(92%_0.02_280)] dark:border-[oklch(28%_0.025_280)]"
    >
      <span class="text-xs font-semibold uppercase tracking-wider text-muted mb-4 block">Tags</span>
      <div class="flex flex-wrap gap-6">
        <div :for={{category, values} <- @grouped} class="flex flex-col gap-2">
          <span class="text-[0.7rem] font-medium uppercase text-muted">
            {category}
          </span>
          <div class="flex flex-wrap gap-1.5">
            <span
              :for={value <- values}
              class={"badge-reposit text-xs py-1 #{tag_color(category)}"}
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

  defp vote_comments(assigns) do
    # Filter to only votes with comments (downvotes)
    comments = Enum.filter(assigns.votes, &(&1.comment && &1.comment != ""))
    assigns = assign(assigns, :comments, comments)

    ~H"""
    <div
      :if={length(@comments) > 0}
      class="mt-8 pt-6 border-t border-[oklch(92%_0.02_280)] dark:border-[oklch(28%_0.025_280)]"
    >
      <span class="text-xs font-semibold uppercase tracking-wider text-muted mb-4 block">
        Feedback
      </span>
      <div class="space-y-3">
        <div
          :for={vote <- @comments}
          class="p-4 rounded-xl bg-[oklch(97%_0.005_280)] dark:bg-[oklch(20%_0.015_280)] border-l-3 border-[oklch(60%_0.2_25)]"
        >
          <div class="flex items-center gap-2 mb-2">
            <span class="badge-reposit text-[0.65rem] py-0.5 bg-[oklch(92%_0.03_25)] dark:bg-[oklch(30%_0.05_25)] text-[oklch(50%_0.15_25)] dark:text-[oklch(75%_0.12_25)]">
              {reason_label(vote.reason)}
            </span>
            <span class="text-xs text-muted">{format_date(vote.inserted_at)}</span>
          </div>
          <p class="text-sm text-[oklch(35%_0.02_280)] dark:text-[oklch(75%_0.02_280)]">
            {vote.comment}
          </p>
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

  defp score_color(score) when score > 0, do: "text-[oklch(55%_0.15_145)]"
  defp score_color(score) when score < 0, do: "text-[oklch(60%_0.2_25)]"
  defp score_color(_), do: "text-muted"

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%B %d, %Y")
  end

  defp format_date(_), do: ""
end
