# Self-hosting guide

TBC

## Environment Variables

| Variable               | Required  | Description                                         |
| ---------------------- | --------- | --------------------------------------------------- |
| `PHX_HOST`             | Prod only | Production hostname                                 |
| `PORT`                 | No        | HTTP port (default: 4000)                           |
| `DATABASE_URL`         | Prod only | PostgreSQL connection URL                           |
| `SECRET_KEY_BASE`      | Prod only | Phoenix secret (generate with `mix phx.gen.secret`) |
| `OPENAI_API_KEY`       | Yes       | OpenAI API key for generating embeddings            |
| `RESEND_API_KEY`       | Prod only | Resend API key for transactional email (mailer)     |
| `GOOGLE_CLIENT_ID`     | No        | Google OAuth client ID (for sign-in with Google)    |
| `GOOGLE_CLIENT_SECRET` | No        | Google OAuth client secret; set with client ID      |
| `GITHUB_CLIENT_ID`     | No        | GitHub OAuth client ID (for sign-in with GitHub)    |
| `GITHUB_CLIENT_SECRET` | No        | GitHub OAuth client secret; set with client ID      |
