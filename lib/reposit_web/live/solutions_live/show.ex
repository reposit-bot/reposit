defmodule RepositWeb.SolutionsLive.Show do
  @moduledoc """
  LiveView for displaying a single solution's details.

  Includes full problem description, solution pattern with markdown rendering,
  tags grouped by category, vote breakdown, and recent vote comments.
  """
  use RepositWeb, :live_view

  alias Reposit.Solutions
  alias Reposit.Solutions.Solution
  alias Reposit.Votes

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Solutions.get_solution_with_votes(id, votes_limit: 10) do
      {:ok, solution} ->
        # Get user's existing vote if logged in
        user_vote = get_user_vote(socket, solution.id)

        {:ok,
         socket
         |> assign(:solution, solution)
         |> assign(:markdown_html, render_markdown(solution.solution))
         |> assign(:user_vote, user_vote)
         |> assign(:voting, false)
         |> assign(:show_downvote_form, false)
         |> assign(:downvote_comment, "")
         |> assign(:downvote_reason, nil)
         |> assign(:show_delete_confirm, false)
         |> assign(:editing, false)
         |> assign(:form, nil)
         |> assign(:saving, false)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Solution not found")
         |> redirect(to: ~p"/solutions")}
    end
  end

  defp logged_in?(nil), do: false
  defp logged_in?(%{user: nil}), do: false
  defp logged_in?(%{user: _}), do: true

  defp is_author?(nil, _solution), do: false
  defp is_author?(%{user: nil}, _solution), do: false

  defp is_author?(%{user: %{id: user_id}}, %{user_id: solution_user_id}),
    do: user_id == solution_user_id

  defp can_vote?(scope, solution), do: logged_in?(scope) and not is_author?(scope, solution)

  defp can_edit?(scope, solution) do
    is_author?(scope, solution) and
      DateTime.diff(DateTime.utc_now(), solution.inserted_at, :second) <= 3600
  end

  defp author_display_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp author_display_name(_), do: "Contributor"

  defp get_user_vote(socket, solution_id) do
    case socket.assigns[:current_scope] do
      %{user: %{id: user_id}} ->
        case Votes.get_vote(solution_id, user_id) do
          nil -> nil
          vote -> vote.vote_type
        end

      _ ->
        nil
    end
  end

  defp render_markdown(nil), do: ""

  defp render_markdown(text) do
    opts = [
      extension: [autolink: true, strikethrough: true],
      sanitize: sanitize_options()
    ]

    case MDEx.to_html(text, opts) do
      {:ok, html} -> safe_user_content_links(html)
      {:error, _} -> text
    end
  end

  defp sanitize_options do
    MDEx.Document.default_sanitize_options()
    |> Keyword.put(:url_schemes, ["http", "https"])
  end

  # Add rel and target to links in user-submitted HTML:
  # - nofollow, ugc: tell Google not to pass link equity (ugc = user-generated content)
  # - noopener, noreferrer: security when opening in new tab
  defp safe_user_content_links(html) when is_binary(html) do
    Regex.replace(
      ~r/<a\s+/i,
      html,
      ~s|<a rel="nofollow ugc noopener noreferrer" target="_blank" |
    )
  end

  @impl true
  def render(assigns) do
    score = Solution.score(assigns.solution)
    assigns = assign(assigns, :score, score)

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <!-- Back link -->
        <a
          href={~p"/solutions"}
          class="inline-flex items-center gap-2 text-sm text-base-content/60 hover:text-base-content transition-colors"
        >
          <Lucideicons.arrow_left class="w-4 h-4" /> Back to Solutions
        </a>
        
    <!-- Main content card -->
        <div class="card card-bordered bg-base-100 p-6 lg:p-8">
          <%= if @editing do %>
            <.form
              for={@form}
              id="solution-edit-form"
              phx-change="validate"
              phx-submit="save"
              class="space-y-6"
            >
              <div>
                <label class="label">
                  <span class="label-text font-medium">Problem</span>
                </label>
                <.input
                  field={@form[:problem]}
                  type="textarea"
                  class="textarea textarea-bordered w-full min-h-24"
                />
              </div>
              <div>
                <label class="label">
                  <span class="label-text font-medium">Solution</span>
                </label>
                <.input
                  field={@form[:solution]}
                  type="textarea"
                  class="textarea textarea-bordered w-full min-h-48"
                />
              </div>
              <div class="flex gap-3">
                <button type="button" phx-click="cancel-edit" class="btn btn-ghost">
                  Cancel
                </button>
                <button type="submit" class="btn btn-primary" disabled={@saving}>
                  {if @saving, do: "Saving...", else: "Save"}
                </button>
              </div>
            </.form>
          <% else %>
            <!-- Problem section -->
            <div class="mb-8">
              <span class="text-xs font-semibold uppercase tracking-wider text-base-content/60 mb-3 block">
                Problem
              </span>
              <p class="text-base-content text-lg leading-relaxed">
                {@solution.problem}
              </p>
              <div :if={@solution.user} class="mt-3 flex items-center gap-2">
                <span class="text-sm text-base-content/60">Shared by</span>
                <.link
                  href={~p"/u/#{@solution.user.id}"}
                  class="inline-flex items-center gap-1.5 text-sm font-medium text-primary hover:underline"
                >
                  <img
                    :if={@solution.user.avatar_url}
                    src={@solution.user.avatar_url}
                    alt=""
                    class="w-5 h-5 rounded-full object-cover"
                  />
                  <span>{author_display_name(@solution.user)}</span>
                </.link>
              </div>
            </div>
            
    <!-- Vote stats with interactive buttons -->
            <div class="flex flex-wrap items-center gap-4 sm:gap-6 py-4 px-4 sm:px-5 rounded-2xl bg-base-200 mb-8">
              <!-- Upvote button -->
              <button
                :if={can_vote?(@current_scope, @solution)}
                phx-click="upvote"
                disabled={@voting}
                class={"flex items-center gap-2 px-3 py-1.5 rounded-lg transition-all #{if @user_vote == :up, do: "bg-success/15 ring-2 ring-success", else: "hover:bg-success/10"}"}
              >
                <Lucideicons.arrow_up class={"w-5 h-5 #{if @user_vote == :up, do: "text-success", else: "text-success/70"}"} />
                <span class="mono font-semibold text-success">{@solution.upvotes}</span>
              </button>
              <!-- Static upvote display for logged out users or authors -->
              <div :if={!can_vote?(@current_scope, @solution)} class="flex items-center gap-2">
                <Lucideicons.arrow_up class="w-4 h-4 sm:w-5 sm:h-5 text-success" />
                <span class="mono font-semibold text-success">{@solution.upvotes}</span>
                <span class="text-xs text-base-content/60">upvotes</span>
              </div>
              
    <!-- Downvote button -->
              <button
                :if={can_vote?(@current_scope, @solution)}
                phx-click="show-downvote-form"
                disabled={@voting}
                class={"flex items-center gap-2 px-3 py-1.5 rounded-lg transition-all #{if @user_vote == :down, do: "bg-error/15 ring-2 ring-error", else: "hover:bg-error/10"}"}
              >
                <Lucideicons.arrow_down class={"w-5 h-5 #{if @user_vote == :down, do: "text-error", else: "text-error/70"}"} />
                <span class="mono font-semibold text-error">{@solution.downvotes}</span>
              </button>
              <!-- Static downvote display for logged out users or authors -->
              <div :if={!can_vote?(@current_scope, @solution)} class="flex items-center gap-2">
                <Lucideicons.arrow_down class="w-4 h-4 sm:w-5 sm:h-5 text-error" />
                <span class="mono font-semibold text-error">{@solution.downvotes}</span>
                <span class="text-xs text-base-content/60">downvotes</span>
              </div>

              <div class="hidden sm:block h-6 w-px bg-base-300"></div>

              <div class="flex items-center gap-2">
                <span class={"mono text-lg sm:text-xl font-bold #{score_color(@score)}"}>
                  {if @score >= 0, do: "+", else: ""}{@score}
                </span>
                <span class="text-xs text-base-content/60">score</span>
              </div>
              
    <!-- Login prompt for guests -->
              <div :if={!logged_in?(@current_scope)} class="text-xs text-base-content/60">
                <a href={~p"/users/log-in"} class="text-primary hover:underline">Log in</a> to vote
              </div>
              
    <!-- Remove vote button -->
              <button
                :if={can_vote?(@current_scope, @solution) && @user_vote}
                phx-click="remove-vote"
                disabled={@voting}
                class="text-xs text-base-content/60 hover:text-error transition-colors"
              >
                Remove vote
              </button>
            </div>
            
    <!-- Downvote form modal -->
            <div
              :if={@show_downvote_form}
              class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50"
              phx-click="cancel-downvote"
            >
              <div
                class="bg-base-100 rounded-2xl p-6 w-full max-w-md mx-4 shadow-xl"
                phx-click-away="cancel-downvote"
                phx-click={%JS{}}
              >
                <h3 class="text-lg font-semibold mb-4">Why are you downvoting?</h3>
                <form phx-submit="downvote" class="space-y-4">
                  <div>
                    <label class="label">
                      <span class="label-text">Reason</span>
                    </label>
                    <select
                      name="reason"
                      class="select select-bordered w-full"
                      required
                    >
                      <option value="">Select a reason...</option>
                      <option value="incorrect">Incorrect - Contains errors</option>
                      <option value="outdated">Outdated - No longer relevant</option>
                      <option value="incomplete">Incomplete - Missing key info</option>
                      <option value="harmful">Harmful - Could cause issues</option>
                      <option value="duplicate">Duplicate - Already exists</option>
                      <option value="other">Other</option>
                    </select>
                  </div>
                  <div>
                    <label class="label">
                      <span class="label-text">Comment (min 10 characters)</span>
                    </label>
                    <textarea
                      name="comment"
                      class="textarea textarea-bordered w-full h-24"
                      placeholder="Explain why this solution should be downvoted..."
                      required
                      minlength="10"
                    ></textarea>
                  </div>
                  <div class="flex gap-3 justify-end">
                    <button type="button" phx-click="cancel-downvote" class="btn btn-ghost">
                      Cancel
                    </button>
                    <button type="submit" class="btn btn-error" disabled={@voting}>
                      {if @voting, do: "Submitting...", else: "Submit Downvote"}
                    </button>
                  </div>
                </form>
              </div>
            </div>
            
    <!-- Solution section -->
            <div>
              <span class="text-xs font-semibold uppercase tracking-wider text-base-content/60 mb-4 block">
                Solution
              </span>
              <div class="prose max-w-none">
                {Phoenix.HTML.raw(@markdown_html)}
              </div>
            </div>
          <% end %>
          
    <!-- Tags by category -->
          <.tags_by_category tags={@solution.tags} />
          
    <!-- Vote comments -->
          <.vote_comments votes={@solution.votes} />
          
    <!-- Metadata footer -->
          <div class="mt-8 pt-6 border-t border-base-300 flex flex-wrap items-center gap-1 text-xs text-base-content/60">
            <span>Created {format_date(@solution.inserted_at)}</span>
            <span :if={@solution.updated_at != @solution.inserted_at} class="">
              · Updated {format_date(@solution.updated_at)}
            </span>
            <div class="ml-auto flex items-center gap-2">
              <button
                :if={can_edit?(@current_scope, @solution) && !@editing}
                phx-click="edit-solution"
                type="button"
                class="btn btn-ghost btn-xs"
              >
                <.icon name="pencil" class="w-4 h-4" /> Edit
              </button>
              <button
                :if={is_author?(@current_scope, @solution)}
                phx-click="show-delete-confirm"
                class="btn btn-ghost btn-xs text-error hover:bg-error/10"
              >
                <Lucideicons.trash_2 class="w-4 h-4" /> Delete
              </button>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Delete confirmation modal -->
      <div
        :if={@show_delete_confirm}
        class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50"
        phx-click="cancel-delete"
      >
        <div
          class="bg-base-100 rounded-2xl p-6 w-full max-w-md mx-4 shadow-xl"
          phx-click-away="cancel-delete"
          phx-click={%JS{}}
        >
          <h3 class="text-lg font-semibold mb-2">Delete this solution?</h3>
          <p class="text-sm text-base-content/60 mb-6">
            This action cannot be undone. All votes on this solution will also be deleted.
          </p>
          <div class="flex gap-3 justify-end">
            <button phx-click="cancel-delete" class="btn btn-ghost">
              Cancel
            </button>
            <button phx-click="delete-solution" class="btn btn-error">
              Delete
            </button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("upvote", _params, socket) do
    scope = socket.assigns.current_scope
    solution = socket.assigns.solution

    socket = assign(socket, :voting, true)

    case Votes.create_vote(scope, %{
           solution_id: solution.id,
           vote_type: :up
         }) do
      {:ok, _vote} ->
        # Reload solution to get updated counts
        {:ok, updated_solution} = Solutions.get_solution_with_votes(solution.id, votes_limit: 10)

        {:noreply,
         socket
         |> assign(:solution, updated_solution)
         |> assign(:user_vote, :up)
         |> assign(:voting, false)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to vote")
         |> assign(:voting, false)}
    end
  end

  def handle_event("show-downvote-form", _params, socket) do
    {:noreply, assign(socket, :show_downvote_form, true)}
  end

  def handle_event("cancel-downvote", _params, socket) do
    {:noreply, assign(socket, :show_downvote_form, false)}
  end

  def handle_event("show-delete-confirm", _params, socket) do
    {:noreply, assign(socket, :show_delete_confirm, true)}
  end

  def handle_event("cancel-delete", _params, socket) do
    {:noreply, assign(socket, :show_delete_confirm, false)}
  end

  def handle_event("edit-solution", _params, socket) do
    solution = socket.assigns.solution

    changeset =
      Solution.update_changeset(solution, %{
        problem: solution.problem,
        solution: solution.solution,
        tags: solution.tags || %{}
      })

    {:noreply,
     socket
     |> assign(:editing, true)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("cancel-edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing, false)
     |> assign(:form, nil)}
  end

  def handle_event("validate", %{"solution" => params}, socket) do
    solution = socket.assigns.solution
    changeset = Solution.update_changeset(solution, params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("save", %{"solution" => params}, socket) do
    scope = socket.assigns.current_scope
    solution = socket.assigns.solution

    socket = assign(socket, :saving, true)

    case Solutions.update_solution(scope, solution.id, params) do
      {:ok, _updated_solution} ->
        {:ok, updated_solution} = Solutions.get_solution_with_votes(solution.id, votes_limit: 10)

        {:noreply,
         socket
         |> assign(:solution, updated_solution)
         |> assign(:markdown_html, render_markdown(updated_solution.solution))
         |> assign(:editing, false)
         |> assign(:form, nil)
         |> assign(:saving, false)
         |> put_flash(:info, "Solution updated.")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You can only edit your own solutions.")
         |> assign(:editing, false)
         |> assign(:form, nil)
         |> assign(:saving, false)}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Solution not found.")
         |> assign(:editing, false)
         |> assign(:form, nil)
         |> assign(:saving, false)}

      {:error, :edit_window_expired} ->
        {:noreply,
         socket
         |> put_flash(:error, "Editing is only allowed within 1 hour of creation.")
         |> assign(:editing, false)
         |> assign(:form, nil)
         |> assign(:saving, false)}

      {:error, :content_unsafe} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Content contains potentially unsafe patterns. Please revise and try again."
         )
         |> assign(:saving, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> assign(:saving, false)}
    end
  end

  def handle_event("remove-vote", _params, socket) do
    scope = socket.assigns.current_scope
    solution = socket.assigns.solution

    socket = assign(socket, :voting, true)

    case Votes.delete_vote(scope, solution.id) do
      {:ok, _} ->
        # Reload solution to get updated counts
        {:ok, updated_solution} = Solutions.get_solution_with_votes(solution.id, votes_limit: 10)

        {:noreply,
         socket
         |> assign(:solution, updated_solution)
         |> assign(:user_vote, nil)
         |> assign(:voting, false)}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "No vote found to remove")
         |> assign(:voting, false)}
    end
  end

  def handle_event("delete-solution", _params, socket) do
    scope = socket.assigns.current_scope
    solution = socket.assigns.solution

    case Solutions.delete_solution(scope, solution.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Solution deleted successfully")
         |> redirect(to: ~p"/solutions")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You can only delete your own solutions")
         |> assign(:show_delete_confirm, false)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete solution")
         |> assign(:show_delete_confirm, false)}
    end
  end

  def handle_event("downvote", %{"comment" => comment, "reason" => reason}, socket) do
    scope = socket.assigns.current_scope
    solution = socket.assigns.solution

    socket = assign(socket, :voting, true)

    case Votes.create_vote(scope, %{
           solution_id: solution.id,
           vote_type: :down,
           comment: comment,
           reason: String.to_existing_atom(reason)
         }) do
      {:ok, _vote} ->
        # Reload solution to get updated counts
        {:ok, updated_solution} = Solutions.get_solution_with_votes(solution.id, votes_limit: 10)

        {:noreply,
         socket
         |> assign(:solution, updated_solution)
         |> assign(:user_vote, :down)
         |> assign(:voting, false)
         |> assign(:show_downvote_form, false)}

      {:error, :content_unsafe} ->
        {:noreply,
         socket
         |> put_flash(:error, "Comment contains unsafe content")
         |> assign(:voting, false)}

      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
        error_msg = errors |> Map.values() |> List.flatten() |> Enum.join(", ")

        {:noreply,
         socket
         |> put_flash(:error, "Validation error: #{error_msg}")
         |> assign(:voting, false)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to vote")
         |> assign(:voting, false)}
    end
  end

  defp tags_by_category(assigns) do
    grouped = group_tags(assigns.tags)
    assigns = assign(assigns, :grouped, grouped)

    ~H"""
    <div
      :if={map_size(@grouped) > 0}
      class="mt-8 pt-6 border-t border-base-300"
    >
      <span class="text-xs font-semibold uppercase tracking-wider text-base-content/60 mb-4 block">
        Tags
      </span>
      <div class="flex flex-wrap gap-6">
        <div :for={{category, values} <- @grouped} class="flex flex-col gap-2">
          <span class="text-[0.7rem] font-medium uppercase text-base-content/60">
            {category}
          </span>
          <div class="flex flex-wrap gap-1.5">
            <.solution_tag :for={value <- values} value={value} />
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

  defp vote_comments(assigns) do
    # Filter to only votes with comments (downvotes)
    comments = Enum.filter(assigns.votes, &(&1.comment && &1.comment != ""))
    assigns = assign(assigns, :comments, comments)

    ~H"""
    <div
      :if={length(@comments) > 0}
      class="mt-8 pt-6 border-t border-base-300"
    >
      <span class="text-xs font-semibold uppercase tracking-wider text-base-content/60 mb-4 block">
        Feedback
      </span>
      <div class="space-y-3">
        <div
          :for={vote <- @comments}
          class="p-4 rounded-xl bg-base-200 border-l-3 border-warning"
        >
          <div class="flex flex-wrap items-center gap-2 mb-2">
            <span class="badge badge-sm badge-warning badge-outline font-mono">
              {reason_label(vote.reason)}
            </span>
            <span :if={vote.user} class="text-xs text-base-content/60">
              by
              <.link href={~p"/u/#{vote.user.id}"} class="font-medium text-primary hover:underline">
                {vote_author_name(vote.user)}
              </.link>
            </span>
            <span class="text-xs text-base-content/60">{format_date(vote.inserted_at)}</span>
          </div>
          <p class="text-sm text-base-content/80">
            {vote.comment}
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp vote_author_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp vote_author_name(_), do: "Contributor"

  defp reason_label(:incorrect), do: "Incorrect"
  defp reason_label(:outdated), do: "Outdated"
  defp reason_label(:incomplete), do: "Incomplete"
  defp reason_label(:harmful), do: "Harmful"
  defp reason_label(:duplicate), do: "Duplicate"
  defp reason_label(:other), do: "Other"
  defp reason_label(_), do: "Feedback"

  defp score_color(score) when score > 0, do: "text-success"
  defp score_color(score) when score < 0, do: "text-error"
  defp score_color(_), do: "text-base-content/60"

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%B %d, %Y")
  end

  defp format_date(_), do: ""
end
