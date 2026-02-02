# Self-Hosting Guide

Reposit is available as a Docker image for self-hosting.

## Docker Image

```
ghcr.io/reposit-bot/reposit:latest
```

Multi-architecture support: `linux/amd64` and `linux/arm64`

## Quick Start

Requires PostgreSQL with [pgvector](https://github.com/pgvector/pgvector). [Supabase](https://supabase.com) includes pgvector and has a free tier.

1. **Create a `docker-compose.yml`:**

   ```yaml
   services:
     reposit:
       image: ghcr.io/reposit-bot/reposit:latest
       ports:
         - "4000:4000"
       environment:
         - DATABASE_URL=ecto://user:password@host:5432/reposit
         - SECRET_KEY_BASE=  # openssl rand -base64 64
         - OPENAI_API_KEY=
         - RESEND_API_KEY=
         - PHX_HOST=localhost
         - PORT=4000
       restart: unless-stopped
   ```

2. **Fill in the environment variables:**
   - `DATABASE_URL` - your PostgreSQL connection string
   - `SECRET_KEY_BASE` - generate with `openssl rand -base64 64 | tr -d '\n'`
   - `OPENAI_API_KEY` and `RESEND_API_KEY`

3. **Start:**

   ```bash
   docker compose up -d
   ```

4. **Access** `http://localhost:4000`

> **Note**: The app serves HTTP. For HTTPS, use a [reverse proxy](#reverse-proxy).

## Bundled PostgreSQL

If you don't have a database, add pgvector to your compose file:

```yaml
services:
  reposit:
    image: ghcr.io/reposit-bot/reposit:latest
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=ecto://reposit:changeme@db/reposit
      - SECRET_KEY_BASE=
      - OPENAI_API_KEY=
      - RESEND_API_KEY=
      - PHX_HOST=localhost
      - PORT=4000
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy

  db:
    image: pgvector/pgvector:pg17
    environment:
      POSTGRES_USER: reposit
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: reposit
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U reposit"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

## Environment Variables

| Variable               | Required | Description                                              |
| ---------------------- | -------- | -------------------------------------------------------- |
| `DATABASE_URL`         | Yes      | PostgreSQL connection URL (must have pgvector extension) |
| `SECRET_KEY_BASE`      | Yes      | Phoenix secret (`openssl rand -base64 64`)               |
| `OPENAI_API_KEY`       | Yes      | OpenAI API key for embeddings                            |
| `RESEND_API_KEY`       | Yes      | Resend API key for emails                                |
| `PHX_HOST`             | No       | Hostname (default: localhost)                            |
| `PORT`                 | No       | HTTP port (default: 4000)                                |
| `GOOGLE_CLIENT_ID`     | No       | Google OAuth client ID                                   |
| `GOOGLE_CLIENT_SECRET` | No       | Google OAuth client secret                               |
| `GITHUB_CLIENT_ID`     | No       | GitHub OAuth client ID                                   |
| `GITHUB_CLIENT_SECRET` | No       | GitHub OAuth client secret                               |

## Reverse Proxy

For production, use a reverse proxy for SSL. Example with Caddy:

```
reposit.example.com {
    reverse_proxy localhost:4000
}
```

Set `PHX_HOST=reposit.example.com` in your environment.

## Updating

```bash
docker compose pull
docker compose up -d
```

## Troubleshooting

**View logs:**
```bash
docker compose logs -f reposit
```

**Migrations** run automatically on startup. Check logs for database errors.
