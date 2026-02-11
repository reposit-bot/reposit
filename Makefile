COMPOSE := $(shell command -v docker-compose 2>/dev/null || echo "docker compose")

.PHONY: help setup server test precommit db db.stop dev dev.server dev.test dev.precommit dev.stop dev.shell

help: ## Show available commands
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Local development (requires Elixir) ---

setup: db ## Install deps, create DB, run migrations
	mix setup

server: ## Start the Phoenix dev server
	iex -S mix phx.server

test: ## Run the test suite
	mix test

precommit: ## Run pre-commit checks (compile, format, sobelow, test)
	mix precommit

# --- Infrastructure ---

db: ## Start Postgres (pgvector) in Docker
	$(COMPOSE) up -d db

db.stop: ## Stop Postgres
	$(COMPOSE) down

# --- Docker development (no Elixir needed) ---

dev: ## Start full stack in Docker and run setup
	$(COMPOSE) --profile full up -d --build
	$(COMPOSE) exec app mix setup
	@echo "\nReady! Run: make dev.server"

dev.server: ## Start Phoenix server in Docker
	$(COMPOSE) exec app iex -S mix phx.server

dev.test: ## Run tests in Docker
	$(COMPOSE) exec app mix test

dev.precommit: ## Run pre-commit checks in Docker
	$(COMPOSE) exec app mix precommit

dev.stop: ## Stop all Docker services
	$(COMPOSE) --profile full down

dev.shell: ## Open a shell in the app container
	$(COMPOSE) exec app bash
