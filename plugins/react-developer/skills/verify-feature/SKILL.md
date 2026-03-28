---
name: verify-feature
description: Auto-detect changed frontend routes, navigate them with Playwright, take screenshots, and check for console/network errors. Use after implementing a frontend feature to verify it works visually — auto-detects routes from git changes or accepts a route argument. Supports --responsive for mobile testing and --interactive for click testing.
allowed-tools: Bash, Read, Glob, Grep, mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_console_messages, mcp__playwright__browser_wait_for, mcp__playwright__browser_network_requests, mcp__playwright__browser_close, mcp__playwright__browser_click, mcp__playwright__browser_fill_form, mcp__playwright__browser_evaluate, mcp__playwright__browser_resize
user-invocable: true
---

# Verify Feature

Post-implementation browser verification for frontend features. Auto-detects changed routes from git history, navigates them, takes screenshots, and checks for console/network errors.

## Arguments

- `{route}` — Route to verify (e.g., `/users`, `/settings`). If omitted, auto-detects from git changes.
- `--responsive` — Also capture mobile viewport screenshots (375x667)
- `--interactive` — Click the first Create/Add button, verify dialog appears, then dismiss

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `FRONTEND_PATH` = `frontend.path` (default: `web`)
- `DEV_PORT` = `frontend.devPort` (default: `5173`)
- `UI_LIBRARY` = `frontend.uiLibrary` (default: `shadcn`)
- `STATE_SERVER` = `frontend.stateManagement.server` (default: `tanstack-query`)
- `STATE_CLIENT` = `frontend.stateManagement.client` (default: `zustand`)
- `MULTI_TENANT` = `backend.multiTenancy` (default: `false`)

If `cloudstack.json` does not exist, auto-detect by checking `package.json` dependencies.

### Auth Configuration

Check `cloudstack.json` for `localDev.authConfig`. If present, use it for localStorage injection. Otherwise, detect the auth store pattern from the codebase (see screenshot skill for details).

## Process

### Step 1: Detect Routes

If a route was provided, use it directly. Otherwise, auto-detect from recent changes:

```bash
# Find changed page files
git diff --name-only HEAD~3 | grep "{FRONTEND_PATH}/src/.*pages/"
```

Map changed page files to routes by finding the router configuration file:

```bash
# Find router config
grep -rl "createBrowserRouter\|RouteObject\|<Route" {FRONTEND_PATH}/src/ 2>/dev/null | head -3
```

Read the router file and match feature/page names to route paths.

If no routes can be detected, ask the user which route to verify.

### Step 2: Pre-flight

```bash
curl -sf http://localhost:{DEV_PORT} > /dev/null 2>&1 && echo "Frontend: UP" || echo "Frontend: DOWN"
```

If frontend is down, STOP and suggest starting the dev server.

### Step 3: Authenticate

Navigate to `http://localhost:{DEV_PORT}` to establish the origin, then inject auth via localStorage using the auth configuration (from `cloudstack.json` or auto-detected from the codebase).

### Step 4: Verify Each Route

For each detected route:

1. **Navigate** — `browser_navigate` to `http://localhost:{DEV_PORT}{route}`
2. **Wait** — `browser_wait_for` for content to load (network idle or 3 seconds)
3. **Snapshot** — `browser_snapshot` to check accessibility tree for meaningful content (not just a loading spinner or error boundary)
4. **Console** — `browser_console_messages` to flag any `error` level messages
5. **Network** — `browser_network_requests` to flag 4xx/5xx responses
6. **Screenshot** — `browser_take_screenshot` (always)

### Step 5: Responsive Check (if --responsive)

For each route:
1. `browser_resize` to `375, 667`
2. `browser_take_screenshot` — mobile viewport
3. `browser_resize` to `1280, 720` — restore desktop

### Step 6: Interactive Check (if --interactive)

For each route:
1. `browser_snapshot` to find clickable Create/Add/New buttons
2. If found: `browser_click` on the first one
3. `browser_wait_for` a dialog or form to appear (2 seconds)
4. `browser_snapshot` to verify the dialog rendered
5. `browser_click` on close/cancel or `browser_evaluate` to press Escape:
   ```javascript
   document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
   ```

### Step 7: Cleanup

`browser_close` to end the session.

## Output Format

```markdown
## Feature Verification: {route(s)}

### Route Checks
| Route | Content | Console | Network | Screenshot |
|-------|---------|---------|---------|------------|
| /users | PASS | PASS (0 errors) | PASS (all 2xx) | captured |
| /users/:id | FAIL | FAIL (1 error) | PASS | captured |

### Console Errors
- `/users/:id`: `TypeError: Cannot read property 'name' of undefined` at user-detail.tsx:28

### Network Issues
- None

### Responsive (if --responsive)
| Route | Mobile Screenshot | Issues |
|-------|-------------------|--------|
| /users | captured | None |

### Interactive (if --interactive)
| Route | Button Found | Dialog Opened | Dialog Closed |
|-------|-------------|---------------|---------------|
| /users | "Create User" | PASS | PASS |

### Summary: {PASS / FAIL}
```

## Error Handling

- **Frontend not running:** STOP and suggest starting the dev server.
- **No routes detected:** Ask the user which route to verify.
- **Auth redirect:** If a page redirects to `/login` after auth injection, retry auth once with a full page reload.
- **Empty content:** If snapshot shows only a loading spinner after 5 seconds, report as FAIL with note.

## Related Skills

- `/screenshot` for a quick single-page capture
- `/smoke-test` for full app smoke testing across all routes
- `/add-feature` scaffolds the feature, then use this to verify it
