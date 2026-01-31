#!/bin/bash
set -e

echo "Starting Reposit dev environment..."

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

echo "Postgres is ready"

# Verify pgvector is available on the host port (what Elixir will connect to)
echo "Checking pgvector extension..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -c "SELECT 1" &>/dev/null || {
  echo "ERROR: Cannot connect to Postgres on localhost:5432"
  exit 1
}

if ! PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -c "CREATE EXTENSION IF NOT EXISTS vector" &>/dev/null; then
  echo ""
  echo "ERROR: pgvector extension is not available on localhost:5432!"
  echo ""
  echo "This usually means a local Postgres is running instead of Docker's."
  echo "Check what's using port 5432:"
  echo ""
  echo "  lsof -i :5432"
  echo "  brew services list | grep postgres"
  echo ""
  echo "To fix, stop your local Postgres:"
  echo ""
  echo "  brew services stop postgresql@16"
  echo ""
  echo "Then re-run this script."
  exit 1
fi

echo "pgvector is available"

# Run setup if needed (creates DB, runs migrations)
if ! mix ecto.migrations 2>/dev/null | grep -q "up"; then
  echo "Running mix setup..."
  mix setup
fi

echo "Dev environment ready. Run: mix phx.server"
