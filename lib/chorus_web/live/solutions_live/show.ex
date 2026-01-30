defmodule ChorusWeb.SolutionsLive.Show do
  @moduledoc """
  LiveView for displaying a single solution's details.

  This is a placeholder that will be expanded by chorus-ipk6.
  """
  use ChorusWeb, :live_view

  alias Chorus.Solutions

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Solutions.get_solution(id) do
      {:ok, solution} ->
        {:ok, assign(socket, :solution, solution)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Solution not found")
         |> redirect(to: ~p"/solutions")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="container mx-auto px-4 py-8 max-w-4xl">
        <div class="mb-6">
          <.link navigate={~p"/solutions"} class="btn btn-ghost btn-sm">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">
              <path fill-rule="evenodd" d="M17 10a.75.75 0 0 1-.75.75H5.612l4.158 3.96a.75.75 0 1 1-1.04 1.08l-5.5-5.25a.75.75 0 0 1 0-1.08l5.5-5.25a.75.75 0 1 1 1.04 1.08L5.612 9.25H16.25A.75.75 0 0 1 17 10Z" clip-rule="evenodd" />
            </svg>
            Back to Solutions
          </.link>
        </div>

        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h1 class="card-title text-2xl mb-4">{@solution.problem_description}</h1>

            <div class="prose max-w-none">
              <h3 class="text-lg font-semibold mb-2">Solution</h3>
              <p class="whitespace-pre-wrap">{@solution.solution_pattern}</p>
            </div>

            <.tags tags={@solution.tags} />

            <div class="flex items-center gap-6 mt-6 pt-6 border-t border-base-200">
              <.vote_display solution={@solution} />
              <span class="text-sm text-base-content/50">
                Created {format_date(@solution.inserted_at)}
              </span>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp tags(assigns) do
    all_tags = flatten_tags(assigns.tags)
    assigns = assign(assigns, :all_tags, all_tags)

    ~H"""
    <div :if={length(@all_tags) > 0} class="flex flex-wrap gap-2 mt-4">
      <span
        :for={tag <- @all_tags}
        class={"badge #{tag_color(tag.category)}"}
      >
        {tag.category}: {tag.value}
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
    score = Chorus.Solutions.Solution.score(assigns.solution)
    assigns = assign(assigns, :score, score)

    ~H"""
    <div class="flex items-center gap-4 text-sm">
      <span class="flex items-center gap-1 text-success">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
          <path fill-rule="evenodd" d="M10 17a.75.75 0 0 1-.75-.75V5.612L5.29 9.77a.75.75 0 0 1-1.08-1.04l5.25-5.5a.75.75 0 0 1 1.08 0l5.25 5.5a.75.75 0 1 1-1.08 1.04l-3.96-4.158V16.25A.75.75 0 0 1 10 17Z" clip-rule="evenodd" />
        </svg>
        {@solution.upvotes} upvotes
      </span>
      <span class="flex items-center gap-1 text-error">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
          <path fill-rule="evenodd" d="M10 3a.75.75 0 0 1 .75.75v10.638l3.96-4.158a.75.75 0 1 1 1.08 1.04l-5.25 5.5a.75.75 0 0 1-1.08 0l-5.25-5.5a.75.75 0 1 1 1.08-1.04l3.96 4.158V3.75A.75.75 0 0 1 10 3Z" clip-rule="evenodd" />
        </svg>
        {@solution.downvotes} downvotes
      </span>
      <span class={"font-bold #{score_color(@score)}"}>
        Score: {if @score >= 0, do: "+", else: ""}{@score}
      </span>
    </div>
    """
  end

  defp score_color(score) when score > 0, do: "text-success"
  defp score_color(score) when score < 0, do: "text-error"
  defp score_color(_), do: "text-base-content/70"

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%B %d, %Y at %H:%M")
  end
  defp format_date(_), do: ""
end
