#!/bin/bash
set -e

echo "🚀 Starting Reposit dev environment..."

# Start Colima if not running
if ! colima status &>/dev/null; then
  echo "Starting Colima..."
  # Force stop first to clear any stale state (e.g., vz driver issues)
  colima stop -f 2>/dev/null || true
  colima start
fi

# Start Postgres container
echo "Starting Postgres..."
docker-compose up -d

# Wait for Postgres to be ready
echo "Waiting for Postgres..."
until docker-compose exec -T db pg_isready -U postgres &>/dev/null; do
  sleep 1
done

echo "✓ Postgres is ready"

# Run setup if needed (creates DB, runs migrations)
if ! mix ecto.migrations 2>/dev/null | grep -q "up"; then
  echo "Running mix setup..."
  mix setup
fi

echo "✓ Dev environment ready. Run: mix phx.server"
