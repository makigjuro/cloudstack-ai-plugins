---
name: run-local
description: Start the local development environment. Supports .NET Aspire AppHost or Docker Compose based on project configuration. Use to spin up all services locally for manual testing.
allowed-tools: Bash
user-invocable: true
---

# Run Local

Start the local development environment using the configured orchestrator.

## Arguments

- `--backend-only` -- Skip the frontend dev server
- `--no-dashboard` -- Skip opening the orchestrator dashboard

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `FRONTEND_PATH` = `frontend.path` (default: `web`)
- `FRONTEND_PORT` = `frontend.devPort` (default: `5173`)

Additionally check for local dev configuration. The skill supports two orchestrators:

**Option A -- .NET Aspire (default if AppHost project exists):**
Look for a project directory matching `*AppHost*` under `src/`. If found:
- `APP_HOST_PATH` = path to the AppHost project
- `DASHBOARD_PORT` = the Aspire dashboard port (typically 15888, check `launchSettings.json`)

**Option B -- Docker Compose:**
If no AppHost project exists, look for `docker-compose.yml` or `docker-compose.yaml` in the repo root or `src/`.

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Process

### Step 1: Pre-flight

```bash
# Verify Docker is running (required for databases, messaging, caches)
docker info > /dev/null 2>&1 || echo "ERROR: Docker is not running. Start Docker first."

# Verify .NET SDK
dotnet --version
```

### Step 2: Start Services

**If using .NET Aspire:**
```bash
cd ${APP_HOST_PATH} && dotnet run
```

The Aspire dashboard will be available at `https://localhost:${DASHBOARD_PORT}`.

**If using Docker Compose:**
```bash
docker compose up -d
```

### Step 3: Start Frontend (unless --backend-only)

In a separate terminal:

```bash
cd ${FRONTEND_PATH} && npm run dev
```

Frontend available at `http://localhost:${FRONTEND_PORT}`.

## Ports

The port table depends on your project configuration. Common defaults:

| Service | Port |
|---------|------|
| Orchestrator Dashboard | Varies (check config) |
| API Gateway | 5000 |
| Frontend (Vite) | ${FRONTEND_PORT} |
| PostgreSQL | 5432 |

Check your app host or docker-compose file for the actual port mappings.

## Troubleshooting

- **Port conflict**: Check for running containers with `docker ps`
- **Build failure**: Run `dotnet build ${SOLUTION}` first to see errors
- **Docker containers stuck**: Run `docker compose down` to clean up

## Post-Launch Verification

After the services start, optionally verify they're working using Playwright:

1. Navigate to the dashboard URL using `mcp__playwright__browser_navigate`
2. Take a snapshot with `mcp__playwright__browser_snapshot` to confirm it loaded
3. Check `mcp__playwright__browser_console_messages` for any errors

This is optional -- only do it if the user asks to verify, or if there were recent issues with the local setup.

## Related Skills

- `/smoke-test` to verify the running app in the browser
- `/run-tests` to run tests after verifying locally
- `/diagnose` if the local environment has issues
