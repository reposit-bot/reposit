defmodule ChorusWeb.DemoLive do
  use ChorusWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-8">
        <h1 class="text-2xl font-bold mb-4">LiveView Demo</h1>
        <div class="card bg-base-200 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Counter: {@count}</h2>
            <div class="card-actions justify-end">
              <button class="btn btn-primary" phx-click="increment">+1</button>
              <button class="btn btn-secondary" phx-click="decrement">-1</button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end
end
