defmodule RepositWeb.UserLive do
  @moduledoc """
  Public user profile page showing contributor info and their solutions.
  """
  use RepositWeb, :live_view

  alias Reposit.Accounts
  alias Reposit.Solutions

  @per_page 20

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case parse_id(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> redirect(to: ~p"/solutions")}

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            {:ok,
             socket
             |> put_flash(:error, "User not found")
             |> redirect(to: ~p"/solutions")}

          user ->
            solutions =
              Solutions.list_solutions_by_user(user_id, limit: @per_page, order_by: :inserted_at)

            count = Solutions.count_solutions_by_user(user_id)

            {:ok,
             socket
             |> assign(:page_title, display_name(user))
             |> assign(:user, user)
             |> assign(:solutions, solutions)
             |> assign(:solution_count, count)}
        end
    end
  end

  defp parse_id(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> uuid
      :error -> nil
    end
  end

  defp display_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp display_name(_), do: "Contributor"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <a
          href={~p"/solutions"}
          class="inline-flex items-center gap-2 text-sm text-base-content/60 hover:text-base-content transition-colors"
        >
          <.icon name="arrow-left" class="w-4 h-4" /> Back to Solutions
        </a>

        <div class="card card-bordered bg-base-100 p-6 lg:p-8">
          <div class="flex flex-col sm:flex-row items-start sm:items-center gap-4">
            <div :if={@user.avatar_url} class="flex-shrink-0">
              <img
                src={@user.avatar_url}
                alt={display_name(@user)}
                class="w-16 h-16 sm:w-20 sm:h-20 rounded-full object-cover ring-2 ring-base-300"
              />
            </div>
            <div
              :if={!@user.avatar_url}
              class="flex-shrink-0 w-16 h-16 sm:w-20 sm:h-20 rounded-full bg-base-200 flex items-center justify-center"
            >
              <.icon name="user" class="w-8 h-8 sm:w-10 sm:h-10 text-base-content/40" />
            </div>
            <div class="min-w-0">
              <h1 class="page-title text-2xl sm:text-3xl">{display_name(@user)}</h1>
              <p class="text-base-content/60 mt-1">
                {@solution_count} solution{if @solution_count != 1, do: "s"} shared
              </p>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-lg font-semibold text-base-content mb-4">Solutions</h2>
          <div :if={@solution_count == 0} class="card bg-base-100 shadow-lg">
            <div class="card-body items-center text-center py-12">
              <.icon name="lightbulb" class="size-10 text-base-content/40" />
              <p class="text-base-content/60">No solutions yet</p>
            </div>
          </div>
          <div
            :if={@solution_count > 0}
            class="card card-bordered bg-base-100 divide-y divide-base-300"
          >
            <.solution_row
              :for={solution <- @solutions}
              solution={solution}
              show_author={false}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
