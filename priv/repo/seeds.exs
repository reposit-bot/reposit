# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Reposit.Repo.insert!(%Reposit.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query
alias Reposit.Repo
alias Reposit.Solutions.Solution
alias Reposit.Votes.Vote
alias Reposit.Accounts
alias Reposit.Accounts.Scope
alias Reposit.Solutions
alias Reposit.Votes

# Use stub embeddings in seeds to avoid calling OpenAI API
Application.put_env(:reposit, :embeddings_stub, true)

# Reset existing seed users/solutions/votes so re-running seeds is idempotent
# (optional: comment out to accumulate data)
for email <- ["alice@example.com", "bob@example.com", "carol@example.com"] do
  case Accounts.get_user_by_email(email) do
    nil ->
      :ok

    user ->
      solution_ids = Repo.all(from s in Solution, where: s.user_id == ^user.id, select: s.id)
      Repo.delete_all(from v in Vote, where: v.solution_id in ^solution_ids)
      Repo.delete_all(from s in Solution, where: s.user_id == ^user.id)
      Repo.delete(user)
  end
end

# Create seed users
{:ok, alice} =
  Accounts.register_user(%{email: "alice@example.com"})

{:ok, bob} =
  Accounts.register_user(%{email: "bob@example.com"})

{:ok, carol} =
  Accounts.register_user(%{email: "carol@example.com"})

# Seed solutions: ~100 varied problem/solution pairs
# Each entry has problem (min 20), solution (min 50), optional context_requirements, tags
defmodule SeedData do
  def solution_attrs do
    [
      # LiveView & Web
      solution(
        "How do I implement pagination for a list of items in Phoenix LiveView without loading everything into memory?",
        "Use LiveView streams with cursor-based pagination. Store the cursor (e.g. last id or inserted_at) in the socket, fetch the next page with a limit when the user scrolls near the bottom, and stream_insert the new items. Use phx-update=\"stream\" on the container and a hook or phx-click to load more.",
        %{
          language: ["elixir"],
          framework: ["phoenix", "liveview"],
          domain: ["web"],
          platform: ["backend"]
        }
      ),
      solution(
        "How do I handle file uploads in Phoenix LiveView and store them in S3 or local disk?",
        "Use Phoenix.LiveView.allow_upload/3 with :writer option pointing to a custom writer (e.g. S3). Validate file types and size in accept. On form submit, consume the uploads with consume_uploaded_entries and move to final storage. Use Phoenix.LiveView.HTMLEngine for progress.",
        %{
          language: ["elixir"],
          framework: ["phoenix", "liveview"],
          domain: ["web", "storage"],
          platform: ["backend"]
        }
      ),
      solution(
        "What is the recommended way to broadcast real-time updates to connected LiveView clients?",
        "Use Phoenix.PubSub.subscribe/3 in mount and broadcast from the server with broadcast_from or broadcast. In the LiveView handle_info for the topic message, update socket assigns and push an event or re-render. Use a dedicated topic per resource or channel.",
        %{
          language: ["elixir"],
          framework: ["phoenix", "liveview"],
          domain: ["realtime"],
          platform: ["backend"]
        }
      ),
      solution(
        "How do I debounce user input in a LiveView search box to avoid sending too many events?",
        "Use phx-debounce attribute on the input (e.g. phx-debounce=\"300ms\") so the change event is sent only after the user stops typing. Alternatively use a JS hook with setTimeout to push the event after a delay.",
        %{
          language: ["elixir"],
          framework: ["phoenix", "liveview"],
          domain: ["web"],
          platform: ["frontend"]
        }
      ),
      solution(
        "How can I show a loading state or skeleton while a LiveView is loading data in mount?",
        "Assign a loading flag in mount before the async work, render a skeleton in the template when loading is true. Use send(self(), :load) and in handle_info load data and assign loading: false. For async assign use assign_async/3.",
        %{
          language: ["elixir"],
          framework: ["phoenix", "liveview"],
          domain: ["web"],
          platform: ["frontend"]
        }
      ),
      # Concurrency & OTP
      solution(
        "What is the best way to run async tasks in Elixir without blocking the main process and handle back-pressure?",
        "Use Task.async_stream/3 with a finite concurrency option (e.g. max_concurrency: 5) and a timeout. It returns a stream so you can Enum.take or process lazily. For infinite streams use a GenStage or Broadway pipeline.",
        %{language: ["elixir"], framework: [], domain: ["concurrency"], platform: ["backend"]}
      ),
      solution(
        "How do I implement a simple cache with TTL in Elixir using ETS?",
        "Create a named ETS table with :public and read_concurrency: true. Store keys with a tuple like {key, value, expiry_ts}. On read, check expiry and delete if expired; optionally run a periodic cleanup GenServer to sweep expired entries.",
        %{language: ["elixir"], framework: [], domain: ["caching"], platform: ["backend"]}
      ),
      solution(
        "How do I supervise a dynamic set of worker processes that can be added at runtime?",
        "Use DynamicSupervisor. Start it with start_link and name. Call DynamicSupervisor.start_child(sup, child_spec) to add workers. Use a Registry if you need to look up workers by id. Terminate with DynamicSupervisor.terminate_child.",
        %{language: ["elixir"], framework: [], domain: ["otp"], platform: ["backend"]}
      ),
      solution(
        "What is the right way to limit concurrency when calling an external API from many processes?",
        "Use a single GenServer or a pool (e.g. poolboy) that queues requests and only allows N in-flight. Alternatively use Task.async_stream with max_concurrency: N so only N tasks run at once. Add backoff on rate limit responses.",
        %{
          language: ["elixir"],
          framework: [],
          domain: ["concurrency", "api"],
          platform: ["backend"]
        }
      ),
      solution(
        "How do I run a one-off task on application startup in Elixir?",
        "Use Application.start_phase or add a worker that in init/1 sends a message to self() and in handle_info runs the task then stops. Prefer start_phase for migrations or one-time setup so it blocks release boot until done.",
        %{language: ["elixir"], framework: [], domain: ["otp"], platform: ["backend"]}
      ),
      # Ecto & DB
      solution(
        "How can I add full-text or semantic search over my content using embeddings and PostgreSQL?",
        "Use pgvector extension for vector similarity. Store embeddings (e.g. from OpenAI text-embedding-3-small) in a vector column, create an HNSW or IVFFlat index. At query time embed the query and use <=> for cosine distance.",
        %{
          language: ["sql", "elixir"],
          framework: ["ecto"],
          domain: ["search", "ml"],
          platform: ["backend", "database"]
        }
      ),
      solution(
        "What is a clean pattern to validate and normalize user input before saving to the database in Ecto?",
        "Use Ecto.Changeset with cast/3 for permitted fields, validate_required/2, and custom validators via validate_change/3. For normalization use put_change or prepare_changes/2. Context functions call schema.changeset(struct, attrs) then Repo.insert/update.",
        %{
          language: ["elixir"],
          framework: ["ecto"],
          domain: ["validation"],
          platform: ["backend"]
        }
      ),
      solution(
        "How do I run database migrations in a release (e.g. Fly.io or Docker) without a separate migrate step?",
        "Use a release task that runs Ecto.Migrator.run(Repo, path, :up, all: true). Start the repo before migrating. Run migrations explicitly at deploy time so failures are visible and rollback is possible.",
        %{
          language: ["elixir"],
          framework: ["ecto"],
          domain: ["devops", "deploy"],
          platform: ["backend"]
        }
      ),
      solution(
        "How do I soft-delete records in Ecto (hide from queries but keep in DB)?",
        "Add a deleted_at column (nullable utc_datetime). In the schema default_scope or in queries, add where: is_nil(as.deleted_at). To soft-delete, update the record setting deleted_at to now. Exclude deleted_at in unique indexes or use partial unique indexes.",
        %{language: ["elixir"], framework: ["ecto"], domain: ["database"], platform: ["backend"]}
      ),
      solution(
        "What is the best way to bulk-insert thousands of rows in Ecto without loading all into memory?",
        "Use Ecto.Repo.insert_all/3 with batches (e.g. 1000 rows per batch). Build lists of maps or keyword lists from a stream. Avoid Repo.insert in a loop. For upserts use insert_all with conflict_target and on_conflict.",
        %{language: ["elixir"], framework: ["ecto"], domain: ["database"], platform: ["backend"]}
      ),
      solution(
        "How do I use Ecto multi to run several operations in one transaction and rollback on error?",
        "Use Ecto.Multi.new() |> Multi.insert(:user, user_changeset) |> Multi.insert(:profile, profile_changeset) |> Multi.run(:link, fn _ -> ... end) then Repo.transaction(multi). On any step returning {:error, _}, the transaction rolls back.",
        %{language: ["elixir"], framework: ["ecto"], domain: ["database"], platform: ["backend"]}
      ),
      solution(
        "How can I query with a dynamic list of conditions (e.g. optional filters) in Ecto?",
        "Reduce over the list of filters and pipe into Ecto.Query.where/3. Use dynamic/2 to build a dynamic expression and then where(query, [q], ^dynamic in q.field). Alternatively use Enum.reduce with Query.where for each filter.",
        %{language: ["elixir"], framework: ["ecto"], domain: ["database"], platform: ["backend"]}
      ),
      solution(
        "How do I preload nested associations in Ecto without N+1 queries?",
        "Use Repo.preload/3 with a list of atom or nested preloads, e.g. preload([:user, comments: :user]). Ecto runs one query per association (or a single join). Use preload in the same query that loads the parent.",
        %{language: ["elixir"], framework: ["ecto"], domain: ["database"], platform: ["backend"]}
      ),
      # API & Auth
      solution(
        "How do I rate-limit API requests per user or per IP in a Phoenix application?",
        "Use a plug that checks a key (user_id or IP) against a store (e.g. Hammer with ETS or Redis). Call Hammer.check_rate(key, scale_ms, limit); if {:allow, _} continue, else return 429. Put the plug in the API pipeline.",
        %{
          language: ["elixir"],
          framework: ["phoenix"],
          domain: ["api", "security"],
          platform: ["backend"]
        }
      ),
      solution(
        "How do I implement API token authentication for a Phoenix JSON API?",
        "Store a hashed token (e.g. SHA256) on the user. In a plug, read Authorization header or query param, look up user by token hash. Use Plug.Conn.assign current_user and require it in protected pipelines.",
        %{
          language: ["elixir"],
          framework: ["phoenix"],
          domain: ["api", "auth"],
          platform: ["backend"]
        }
      ),
      solution(
        "What is a good way to version a JSON API (e.g. /api/v1/ and /api/v2/) in Phoenix?",
        "Use scoped routes: scope \"/api/v1\", Api.V1 do ... end and a separate scope for v2. Share plugs and helpers; keep controllers and serializers per version. Use a plug to set API version from path or header if needed.",
        %{language: ["elixir"], framework: ["phoenix"], domain: ["api"], platform: ["backend"]}
      ),
      solution(
        "How do I return consistent JSON error responses (404, 422, 500) from a Phoenix API?",
        "Use a fallback controller with call(conn, {:error, :not_found}) that put_status and json. In actions return {:error, _} and let the fallback handle it. Use a shared error view or a single format like %{errors: [%{code: \"not_found\", detail: \"...\"}]}.",
        %{language: ["elixir"], framework: ["phoenix"], domain: ["api"], platform: ["backend"]}
      ),
      solution(
        "How can I allow CORS for my Phoenix API so a frontend on another origin can call it?",
        "Use the Corsica plug or add CORS headers in a plug: put_resp_header(\"access-control-allow-origin\", origin). Validate origin against a whitelist. Put the plug before the router in endpoint or in the API pipeline.",
        %{
          language: ["elixir"],
          framework: ["phoenix"],
          domain: ["api", "web"],
          platform: ["backend"]
        }
      ),
      # Testing & CI
      solution(
        "How do I test a Phoenix LiveView that loads data asynchronously in mount?",
        "Use Phoenix.LiveViewTest.render_hook or render_async to wait for assign_async. Alternatively send :load in mount and assert on the final rendered output after the message is processed. Use render to get the latest HTML.",
        %{
          language: ["elixir"],
          framework: ["phoenix", "liveview"],
          domain: ["testing"],
          platform: ["backend"]
        }
      ),
      solution(
        "What is the best way to test code that calls an external HTTP API without hitting the real API?",
        "Use Req.Test or Bypass to stub HTTP. In config/test.exs set the API base URL to the stub. Alternatively use Mox to define a behaviour and inject a mock implementation in tests.",
        %{language: ["elixir"], framework: [], domain: ["testing"], platform: ["backend"]}
      ),
      solution(
        "How do I run Ecto migrations in CI (e.g. GitHub Actions) for a Phoenix app?",
        "Start a Postgres service container or use a hosted DB. Set DATABASE_URL or separate env vars. Run mix ecto.create && mix ecto.migrate before mix test. Use a dedicated test database; some CIs provide Postgres as a service.",
        %{
          language: ["elixir"],
          framework: ["ecto"],
          domain: ["ci", "devops"],
          platform: ["backend"]
        }
      ),
      solution(
        "How do I seed the database in tests without running the full seeds file?",
        "Use fixtures in test/support: define a function that inserts the needed data (e.g. user_fixture, solution_fixture) and call them in your test or in setup. Use Repo.insert! or context create functions. Isolate tests with Ecto.Adapters.SQL.Sandbox.",
        %{language: ["elixir"], framework: ["ecto"], domain: ["testing"], platform: ["backend"]}
      ),
      solution(
        "How can I test that a GenServer handles a specific message correctly?",
        "Start the GenServer under the test supervisor with start_supervised. Send the message with send(pid, msg). Assert on state with :sys.get_state(pid) or on side effects (e.g. GenServer.call for a result). Use assert_receive for async replies.",
        %{language: ["elixir"], framework: [], domain: ["testing", "otp"], platform: ["backend"]}
      ),
      # Deployment & Config
      solution(
        "How do I use environment variables or runtime config in a Phoenix app without compile-time config?",
        "Use Config.config_source and release env, or Application.get_env at runtime. For releases use env.sh.eex and REPLACE_OS_VARS or Config.Reader to read from file. Prefer runtime config for secrets and URLs.",
        %{
          language: ["elixir"],
          framework: ["phoenix"],
          domain: ["config", "deploy"],
          platform: ["backend"]
        }
      ),
      solution(
        "How do I run a Phoenix app in Docker and connect to a database on the host?",
        "Use host.docker.internal (Docker Desktop) or the host gateway IP as DB host. Set DATABASE_URL or ECTO host to that. Ensure the DB allows connections from the Docker network. For Linux use --add-host=host.docker.internal:host-gateway.",
        %{
          language: ["elixir"],
          framework: ["phoenix"],
          domain: ["deploy", "docker"],
          platform: ["backend"]
        }
      ),
      solution(
        "What is the recommended way to run periodic jobs (e.g. every hour) in Elixir?",
        "Use Quantum library or a simple GenServer that schedules the next run with Process.send_after(self(), :tick, interval_ms). In handle_info :tick run the job and schedule the next. For cron-like syntax use Quantum.",
        %{language: ["elixir"], framework: [], domain: ["scheduling"], platform: ["backend"]}
      ),
      solution(
        "How do I deploy a Phoenix app to Fly.io with zero-downtime?",
        "Use fly deploy. Configure health checks and min_machines_running. Fly runs a new VM and then stops the old one. Run migrations in a release command or before deploy. Use secrets for DATABASE_URL and other env.",
        %{language: ["elixir"], framework: ["phoenix"], domain: ["deploy"], platform: ["backend"]}
      ),
      solution(
        "How do I structure a Phoenix project with multiple contexts and avoid circular dependencies?",
        "Keep contexts as a single public API; contexts may use other contexts only by calling their public functions. Avoid schema modules in one context referencing another context's schema in the same file. Use shared types in a separate module if needed.",
        %{
          language: ["elixir"],
          framework: ["phoenix"],
          domain: ["architecture"],
          platform: ["backend"]
        }
      )
    ]
  end

  defp solution(problem, pattern, tags),
    do: %{
      problem: problem,
      solution: pattern,
      context_requirements: %{},
      tags: tags
    }

  # Generate more entries by varying topics so we reach ~100
  def more_solutions do
    topics = [
      {"How do I parse and validate JSON request body in Phoenix controller?",
       "Use Phoenix.Controller.get_req_header and Jason.decode!. Validate the result or use a changeset. Put the plug early in the pipeline. Return 422 with error details if invalid.",
       %{language: ["elixir"], framework: ["phoenix"], domain: ["api"], platform: ["backend"]}},
      {"How can I use Phoenix channels for real-time notifications to a specific user?",
       "Subscribe the socket to a topic like \"user:USER_ID\". From the server use Endpoint.broadcast(\"user:USER_ID\", \"event\", payload). The client joins the topic on connect.",
       %{
         language: ["elixir"],
         framework: ["phoenix"],
         domain: ["realtime"],
         platform: ["backend"]
       }},
      {"What is the right way to handle long-running HTTP requests without blocking the connection?",
       "Offload work to a Task or GenServer and return 202 Accepted with a job id. Provide a status endpoint. Alternatively use Server-Sent Events or WebSockets to stream progress.",
       %{language: ["elixir"], framework: ["phoenix"], domain: ["api"], platform: ["backend"]}},
      {"How do I implement retries with exponential backoff for an external API call in Elixir?",
       "Use a loop with retry count: on failure wait with Process.sleep(backoff_ms) and retry. Backoff can be 2^retry_count * base_ms. Cap max retries. Use libraries like Retry or implement in a GenServer.",
       %{
         language: ["elixir"],
         framework: [],
         domain: ["api", "resilience"],
         platform: ["backend"]
       }},
      {"How do I log request id or correlation id across the stack in Phoenix?",
       "Use Logger.metadata and set request_id in a plug from get_req_header or generate one. Put the plug early. Use metadata in formatter so logs include request_id. Pass the id in headers for downstream services.",
       %{
         language: ["elixir"],
         framework: ["phoenix"],
         domain: ["observability"],
         platform: ["backend"]
       }},
      {"How can I use Ecto enum type for a string column with a fixed set of values?",
       "Use Ecto.Enum in the schema: field :status, Ecto.Enum, values: [:pending, :active, :archived]. In migration use Ecto.Migration.execute to create the enum type and add the column. Cast and validate in changeset.",
       %{language: ["elixir"], framework: ["ecto"], domain: ["database"], platform: ["backend"]}},
      {"How do I implement cursor-based pagination for an API that returns a list of items?",
       "Return next_cursor (opaque token, e.g. base64 of last id or timestamp) in the response. Client sends cursor in the next request. Query with where id > ^decoded_cursor order by id limit n. Encode the last id as next_cursor.",
       %{language: ["elixir"], framework: ["ecto"], domain: ["api"], platform: ["backend"]}},
      {"What is a good pattern to invalidate or refresh a cache when data changes in Ecto?",
       "Use Ecto.Multi or after_insert/after_update callbacks to call a cache module that deletes or updates the key. Alternatively use PubSub: broadcast a \"cache_invalidate\" event and have subscribers delete their local cache.",
       %{language: ["elixir"], framework: ["ecto"], domain: ["caching"], platform: ["backend"]}},
      {"How do I run Elixir tests in parallel and still use the Ecto sandbox?",
       "Use ExUnit with async: true. In your Case module use Ecto.Adapters.SQL.Sandbox mode :per_process (or :shared). Allow the repo from the test process. Each test gets its own connection. Avoid sharing state across tests.",
       %{language: ["elixir"], framework: ["ecto"], domain: ["testing"], platform: ["backend"]}},
      {"How can I generate a signed URL for temporary access to a private S3 object?",
       "Use ExAws.S3.presigned_url/4 with expiry (e.g. 1 hour). Sign with your credentials. Return the URL to the client; they can GET the object without your app proxying. Revocation requires bucket policy or short expiry.",
       %{
         language: ["elixir"],
         framework: [],
         domain: ["storage", "security"],
         platform: ["backend"]
       }},
      {"How do I handle timezone-aware datetime in Ecto and display in user's timezone?",
       "Store in UTC in the database (utc_datetime). In the app use DateTime or Calendar.strftime. For user display convert with DateTime.shift_zone(utc, user_tz) or a library. Pass user timezone from frontend or profile.",
       %{language: ["elixir"], framework: ["ecto"], domain: ["database"], platform: ["backend"]}},
      {"What is the best way to schedule a job to run at a specific time (e.g. tomorrow at 9am)?",
       "Compute the target datetime and use Process.send_after(self(), :run, ms_until_target). Alternatively use Quantum with a cron expression or Oban with schedule_at. For one-off use send_after; for recurring use Quantum/Oban.",
       %{language: ["elixir"], framework: [], domain: ["scheduling"], platform: ["backend"]}},
      {"How do I implement idempotency for a Phoenix API that creates a resource?",
       "Accept an Idempotency-Key header. Before creating, look up by key; if found return the existing resource and 200. Otherwise create and store the key with the resource. Use a unique index on (user_id, idempotency_key).",
       %{language: ["elixir"], framework: ["phoenix"], domain: ["api"], platform: ["backend"]}},
      {"How can I use Mox to stub an external service in Elixir tests?",
       "Define a behaviour with the client functions. Define a Mock module with use Mox.defmock. In config/test.exs set config :my_app, :client, MyApp.Mock. In tests use expect/4 or stub_with. Start the app or set the implementation before the test.",
       %{language: ["elixir"], framework: [], domain: ["testing"], platform: ["backend"]}},
      {"How do I add Prometheus metrics to a Phoenix application?",
       "Use the prometheus_ex or prometheus_phx libraries. Add a plug that records request duration and count by path/method. Expose /metrics endpoint (or use a separate port). Configure Prometheus to scrape the target.",
       %{
         language: ["elixir"],
         framework: ["phoenix"],
         domain: ["observability"],
         platform: ["backend"]
       }},
      {"How do I implement a GenServer that processes a queue of jobs with a max concurrency?",
       "Keep a queue (list or :queue) and a count of active jobs. On add, if count < max start a Task and increment; else enqueue. When a job finishes, receive in handle_info and decrement; if queue non-empty pop and start next.",
       %{
         language: ["elixir"],
         framework: [],
         domain: ["concurrency", "otp"],
         platform: ["backend"]
       }},
      {"How can I use Phoenix.Presence to show who is online in a LiveView app?",
       "Add Presence to your Endpoint and track the channel. In the LiveView mount subscribe to the presence topic and handle_diff to update assigns with the list of present users. Render the list in the template. Use Presence.track for join.",
       %{
         language: ["elixir"],
         framework: ["phoenix", "liveview"],
         domain: ["realtime"],
         platform: ["backend"]
       }},
      {"How do I secure a Phoenix API with HTTPS and HSTS in production?",
       "Terminate SSL at the reverse proxy (e.g. Fly, nginx). Set force_ssl in the endpoint. Add HSTS header in a plug or at the proxy. Use secure cookies. In Phoenix set url host and scheme from config.",
       %{
         language: ["elixir"],
         framework: ["phoenix"],
         domain: ["security"],
         platform: ["backend"]
       }},
      {"What is a clean way to pass the current user from a plug to the LiveView?",
       "Assign current_user in the plug (e.g. from session or token). In the router live_session pass the assign to the LiveView. The LiveView receives it in mount from the socket. Use assign(socket, :current_user, conn.assigns.current_user) in the live_session on_mount.",
       %{
         language: ["elixir"],
         framework: ["phoenix", "liveview"],
         domain: ["auth", "web"],
         platform: ["backend"]
       }},
      {"How do I use Oban for background job processing with retries and scheduling?",
       "Add Oban to your supervision tree. Define workers with perform(args). Enqueue with Oban.insert(job). Use queue: and priority:. Configure retries and backoff in config. Use schedule_in or scheduled_at for delayed jobs.",
       %{language: ["elixir"], framework: [], domain: ["background jobs"], platform: ["backend"]}}
    ]

    for {problem, pattern, tags} <- topics, _ <- 1..2 do
      solution(problem, pattern, tags)
    end
  end
end

# Combine base solutions with more (duplicated with variation) to reach ~100
base_attrs = SeedData.solution_attrs()
more_attrs = SeedData.more_solutions()
all_attrs = base_attrs ++ more_attrs
# Trim or pad to 100
solutions_attrs =
  if length(all_attrs) >= 100 do
    Enum.take(all_attrs, 100)
  else
    # Repeat from start to reach 100
    Stream.cycle(all_attrs) |> Enum.take(100)
  end

users_cycle = Stream.cycle([alice, bob, carol])

solutions =
  for {attrs, user} <- Enum.zip(solutions_attrs, users_cycle) do
    scope = Scope.for_user(user)
    {:ok, solution} = Solutions.create_solution(scope, attrs)
    solution
  end

# Votes: each user upvotes a random subset of solutions, a few downvotes
# Deterministic so seeds are reproducible
rng = :rand.seed_s(:exsss, {1, 2, 3})
{_, rng} = :rand.uniform_s(rng)
vote_attrs = []

vote_attrs =
  Enum.reduce(solutions, {vote_attrs, rng}, fn solution, {acc, rng} ->
    # Each of alice, bob, carol has ~25% chance to vote on this solution
    {votes_for_solution, rng} =
      Enum.reduce([alice, bob, carol], {[], rng}, fn user, {v_acc, r} ->
        {u, r} = :rand.uniform_s(r)

        if u < 0.25 do
          # Upvote or occasional downvote
          {u2, r2} = :rand.uniform_s(r)
          type = if u2 < 0.9, do: :up, else: :down

          comment =
            if type == :down, do: "Seed downvote: could be more detailed or updated.", else: nil

          reason = if type == :down, do: :other, else: nil
          {[{user, solution, type, comment, reason} | v_acc], r2}
        else
          {v_acc, r}
        end
      end)

    {Enum.reverse(votes_for_solution) ++ acc, rng}
  end)
  |> then(fn {list, _} -> list end)

for {user, solution, vote_type, comment, reason} <- vote_attrs do
  scope = Scope.for_user(user)
  attrs = %{solution_id: solution.id, vote_type: vote_type}

  attrs =
    if vote_type == :down, do: Map.merge(attrs, %{comment: comment, reason: reason}), else: attrs

  case Votes.create_vote(scope, attrs) do
    {:ok, _vote} -> :ok
    {:error, changeset} -> raise "Seed vote failed: #{inspect(changeset.errors)}"
  end
end

IO.puts("Seeds finished: 3 users, #{length(solutions)} solutions, #{length(vote_attrs)} votes.")
