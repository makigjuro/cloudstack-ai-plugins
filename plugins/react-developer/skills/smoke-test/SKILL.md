---
name: smoke-test
description: Smoke test the running frontend and API by navigating key routes with Playwright, checking for console errors and broken pages. Use after starting the dev server or to verify the app works before creating a PR.
allowed-tools: Bash, Read, Glob, Grep, mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_console_messages, mcp__playwright__browser_wait_for, mcp__playwright__browser_network_requests, mcp__playwright__browser_close, mcp__playwright__browser_click, mcp__playwright__browser_fill_form, mcp__playwright__browser_evaluate
user-invocable: true
---

# Smoke Test

Navigate key application routes using Playwright and verify they render without errors.

## Arguments

- `--frontend-only` — Only test frontend routes (skip API health checks)
- `--api-only` — Only test API health endpoints
- `--interactive` — Run interactive CRUD flows after route testing (creates test data)
- `--screenshot` — Take screenshots of each page (saved to /tmp/smoke-test/)
- `{url}` — Test a specific URL instead of the default routes

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `FRONTEND_PATH` = `frontend.path` (default: `web`)
- `DEV_PORT` = `frontend.devPort` (default: `5173`)
- `UI_LIBRARY` = `frontend.uiLibrary` (default: `shadcn`)
- `STATE_SERVER` = `frontend.stateManagement.server` (default: `tanstack-query`)
- `STATE_CLIENT` = `frontend.stateManagement.client` (default: `zustand`)
- `MULTI_TENANT` = `backend.multiTenancy` (default: `false`)

Also extract:
- `API_PORT` = `backend.devPort` (default: `5000`)
- `ORCHESTRATOR` = `localDev.orchestrator` (default: `none`) — e.g., `aspire`, `docker-compose`, `none`
- `ORCHESTRATOR_PORT` = `localDev.orchestratorPort` (default: `none`)

If `cloudstack.json` does not exist, auto-detect by checking `package.json` dependencies.

### Auth Configuration

Check `cloudstack.json` for `localDev.authConfig`. If present, use it. Otherwise, detect the auth store pattern from the codebase (see screenshot skill for details).

## Prerequisites

The local environment must be running. If not, suggest starting the dev server first.

## Process

### Step 1: Verify Services Are Up

Check that the expected ports are responding before running browser tests:

```bash
# Check API
curl -sf http://localhost:{API_PORT}/health/live > /dev/null 2>&1 && echo "API: UP" || echo "API: DOWN"

# Check Frontend
curl -sf http://localhost:{DEV_PORT} > /dev/null 2>&1 && echo "Frontend: UP" || echo "Frontend: DOWN"
```

If `ORCHESTRATOR` is set (e.g., `aspire`, `docker-compose`), also check the orchestrator dashboard:
```bash
# Only if ORCHESTRATOR_PORT is configured
curl -sf http://localhost:{ORCHESTRATOR_PORT} -k > /dev/null 2>&1 && echo "Orchestrator: UP" || echo "Orchestrator: DOWN"
```

If services are down, STOP and suggest starting the dev environment.

### Step 2: API Health Checks (unless --frontend-only)

```bash
# Hit each service health endpoint
curl -sf http://localhost:{API_PORT}/health/ready | python3 -m json.tool 2>/dev/null || echo "Health check failed"
```

### Step 2.5: Authenticate (Frontend only)

Before testing frontend routes, attempt login. Try the UI form flow first:

1. `browser_navigate` to `http://localhost:{DEV_PORT}/login`
2. `browser_snapshot` to find the login form
3. If a login form is found, fill it with dev credentials from `localDev.authConfig` or generic test values
4. `browser_wait_for` redirect away from `/login`

If login fails (stays on `/login` after 5 seconds), fall back to localStorage injection using the auth configuration.

### Step 3: Auto-Detect Routes (unless specific URL provided)

Instead of hardcoded routes, detect routes from the project's router configuration:

```bash
# Find router config
grep -rl "createBrowserRouter\|RouteObject\|<Route" {FRONTEND_PATH}/src/ 2>/dev/null | head -3
```

Read the router file and extract all top-level route paths. Always include `/` (root/dashboard).

If route detection fails, fall back to testing just `/` and `/login`.

**For each route:**

1. **Navigate** using `mcp__playwright__browser_navigate`
2. **Wait** for the page to settle using `mcp__playwright__browser_wait_for` (wait for network idle or a known element)
3. **Snapshot** the page using `mcp__playwright__browser_snapshot` to check the accessibility tree for content
4. **Check console** using `mcp__playwright__browser_console_messages` for errors
5. **Screenshot** (if `--screenshot`) using `mcp__playwright__browser_take_screenshot`

### Step 3.5: Interactive CRUD Flows (only when --interactive)

Skip this step unless `--interactive` was passed.

Auto-detect CRUD opportunities from the current page:

1. `browser_snapshot` to find Create/Add/New buttons on the current page
2. If a create button is found:
   a. `browser_click` on the button
   b. `browser_wait_for` the dialog/form to appear
   c. `browser_snapshot` to identify form fields
   d. `browser_fill_form` with generic test data (e.g., name: `smoke-test-{timestamp}`, version: `1.0.0`)
   e. `browser_click` on the submit button
   f. `browser_network_requests` — verify the POST/PUT request returned 2xx
   g. `browser_take_screenshot` to capture the result
   h. `browser_snapshot` to verify the new item appears in the list

3. If list items exist, test the detail flow:
   a. `browser_click` on the first item row/link
   b. `browser_wait_for` the detail page/panel to load
   c. `browser_snapshot` to verify detail content rendered

### Step 4: Check for Problems

Flag issues:
- **Console errors** — any `error` level messages in the browser console
- **Network failures** — check `mcp__playwright__browser_network_requests` for failed requests (4xx/5xx)
- **Empty pages** — snapshot shows no meaningful content
- **Auth redirects** — unexpected redirects to /login

### Step 5: Cleanup

Close the browser session:
```
mcp__playwright__browser_close
```

## Output Format

```markdown
## Smoke Test Results

### API Health
| Endpoint | Status |
|----------|--------|
| /health/live | PASS |
| /health/ready | PASS |

### Frontend Routes
| Route | Status | Console Errors | Notes |
|-------|--------|---------------|-------|
| / | PASS | 0 | Dashboard rendered |
| /users | PASS | 0 | List loaded |
| /settings | FAIL | 2 | "TypeError: Cannot read property..." |

### Interactive Flows (if --interactive)
| Flow | Status | Notes |
|------|--------|-------|
| Create Item | PASS | Created "smoke-test-1710345600", visible in list |
| Item Detail | SKIP | No items in list |

### Console Errors
- `/settings`: `TypeError: Cannot read property 'map' of undefined` at settings-page.tsx:42

### Network Failures
- None

### Summary: {PASS / FAIL}
{N routes tested, M passed, K failed}
```

## Guidelines

- This is a fast smoke test, not a comprehensive E2E suite
- Check for obvious breakage, not pixel-perfect rendering
- Console errors are the most valuable signal
- If auth is required and no credentials are available, note which routes redirected to login
- Don't fail on warnings, only on errors

## Error Handling

- **Services not running:** STOP and suggest starting the dev environment before retrying.
- **Playwright not available:** Suggest installing with `npx playwright install` or skip browser tests and fall back to `curl`-based health checks only.
- **Auth required:** Note which routes redirected to login and report as "SKIPPED (auth required)" rather than "FAIL".

## Related Skills

- `/add-feature` to scaffold the feature, then smoke test it
- `/verify-feature` for targeted verification of specific routes
- `/screenshot` for a quick single-page capture
