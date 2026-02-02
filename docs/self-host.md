# Self-Hosting Guide

Reposit is available as a Docker image for self-hosting. This guide covers setup using Docker Compose.

## Quick Start

1. **Create a directory and download the compose file:**

   ```bash
   mkdir reposit && cd reposit
   curl -O https://raw.githubusercontent.com/reposit-bot/reposit/main/docker-compose.selfhost.yml
   curl -O https://raw.githubusercontent.com/reposit-bot/reposit/main/.env.example
   ```

2. **Configure environment variables:**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and fill in the required values:

   ```bash
   # Generate a secret key
   openssl rand -base64 64 | tr -d '\n'
   ```

3. **Start the services:**

   ```bash
   docker compose -f docker-compose.selfhost.yml up -d
   ```

4. **Access Reposit at** `http://localhost:4000`

> **Note**: The app serves plain HTTP. The server logs may say "Access at https://..." but this refers to URL generation, not the listening protocol. For HTTPS, use a [reverse proxy](#reverse-proxy).

## Docker Image

Official images are published to GitHub Container Registry:

```
ghcr.io/reposit-bot/reposit:latest
ghcr.io/reposit-bot/reposit:1.0.0  # specific version
```

Multi-architecture support: `linux/amd64` and `linux/arm64`

## Database Setup

Reposit requires PostgreSQL with the [pgvector](https://github.com/pgvector/pgvector) extension.

### Option 1: Bundled PostgreSQL (default)

The `docker-compose.selfhost.yml` includes a PostgreSQL service with pgvector. Set these variables in your `.env`:

```bash
DATABASE_URL=ecto://reposit:your_db_password@db/reposit
POSTGRES_USER=reposit
POSTGRES_PASSWORD=your_db_password
POSTGRES_DB=reposit
```

### Option 2: External Database

If you have an existing PostgreSQL instance:

1. Ensure the pgvector extension is installed
2. Remove or comment out the `db` service in `docker-compose.selfhost.yml`
3. Set `DATABASE_URL` to your external database:

   ```bash
   DATABASE_URL=ecto://user:password@your-db-host:5432/reposit
   ```

## Environment Variables

| Variable               | Required | Description                                         |
| ---------------------- | -------- | --------------------------------------------------- |
| `DATABASE_URL`         | Yes      | PostgreSQL connection URL with pgvector             |
| `SECRET_KEY_BASE`      | Yes      | Phoenix secret (generate with `openssl rand -base64 64`) |
| `OPENAI_API_KEY`       | Yes      | OpenAI API key for generating embeddings            |
| `RESEND_API_KEY`       | Yes      | Resend API key for transactional emails             |
| `PHX_HOST`             | No       | Production hostname (default: localhost)            |
| `PORT`                 | No       | HTTP port (default: 4000)                           |
| `GOOGLE_CLIENT_ID`     | No       | Google OAuth client ID (for sign-in with Google)    |
| `GOOGLE_CLIENT_SECRET` | No       | Google OAuth client secret                          |
| `GITHUB_CLIENT_ID`     | No       | GitHub OAuth client ID (for sign-in with GitHub)    |
| `GITHUB_CLIENT_SECRET` | No       | GitHub OAuth client secret                          |

## Reverse Proxy

For production, run Reposit behind a reverse proxy (nginx, Caddy, Traefik) to handle SSL termination.

Example Caddy configuration:

```
reposit.example.com {
    reverse_proxy localhost:4000
}
```

Then set `PHX_HOST=reposit.example.com` in your `.env`.

## Updating

To update to the latest version:

```bash
docker compose -f docker-compose.selfhost.yml pull
docker compose -f docker-compose.selfhost.yml up -d
```

## Troubleshooting

### View logs

```bash
docker compose -f docker-compose.selfhost.yml logs -f reposit
```

### Database connection issues

Ensure the database is healthy before the app starts:

```bash
docker compose -f docker-compose.selfhost.yml ps
```

The `db` service should show as "healthy" before `reposit` can connect.

### Migrations

Migrations run automatically on container startup. Check logs if you see database errors.
