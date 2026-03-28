---
name: screenshot
description: Capture a screenshot of a URL or route with one command. Use whenever the user wants to take a screenshot, capture a page, see what a route looks like, or visually verify a page. Supports mobile viewport with --mobile and unauthenticated mode with --no-auth.
allowed-tools: mcp__playwright__browser_navigate, mcp__playwright__browser_wait_for, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_evaluate, mcp__playwright__browser_close, mcp__playwright__browser_resize
user-invocable: true
---

# Screenshot

Capture a screenshot of a URL or route. Nothing else — no tables, no analysis, just the image.

## Arguments

- `{url-or-route}` — URL or route path (default: `/`). If starts with `/`, prepends `http://localhost:{DEV_PORT}`.
- `--mobile` — Resize viewport to 375x667 (iPhone SE) before capturing
- `--no-auth` — Skip authentication (use for login page or public pages)

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

Check `cloudstack.json` for `localDev.authConfig`:

```json
{
  "localDev": {
    "authConfig": {
      "storageKey": "auth-storage",
      "state": {
        "isAuthenticated": true,
        "token": "dev-token"
      }
    }
  }
}
```

If `localDev.authConfig` is not present, use a generic dev auth pattern:
1. Check for an auth store file (e.g., `auth-store.ts`, `useAuthStore.ts`) to find the localStorage key and expected shape
2. Fall back to injecting: `localStorage.setItem('auth-storage', JSON.stringify({ state: { isAuthenticated: true }, version: 0 }))`

## Process

### Step 1: Resolve URL

If the argument starts with `/`, prepend `http://localhost:{DEV_PORT}`. Otherwise use the full URL as-is.

### Step 2: Authenticate (unless --no-auth)

Skip this step if `--no-auth` is passed or the URL is not on `localhost:{DEV_PORT}`.

Navigate to `http://localhost:{DEV_PORT}` first to establish the origin, then inject auth via localStorage.

If `localDev.authConfig` is defined in `cloudstack.json`, use that directly:
```javascript
localStorage.setItem('{storageKey}', JSON.stringify({authConfig.state}))
```

Otherwise, detect the auth store pattern from the codebase:
```bash
# Find auth store to determine localStorage key and shape
grep -rl "persist\|localStorage\|auth" {FRONTEND_PATH}/src/store/ {FRONTEND_PATH}/src/stores/ {FRONTEND_PATH}/src/hooks/ 2>/dev/null | head -3
```

Read the auth store file, extract the `name` (localStorage key) and expected state shape, then inject appropriate values.

### Step 3: Resize (if --mobile)

If `--mobile` is passed, resize the browser to `375, 667`.

### Step 4: Navigate and Capture

1. `browser_navigate` to the resolved URL
2. `browser_wait_for` network idle or 3 seconds
3. `browser_take_screenshot`

### Step 5: Cleanup

Close the browser session with `browser_close`.

## Output

Just show the screenshot. No markdown tables, no analysis, no status reports.

If the page shows an error or blank content, mention it briefly alongside the screenshot.

## Error Handling

- **Frontend not running:** Report that `localhost:{DEV_PORT}` isn't responding and suggest starting the dev server.
- **Auth redirect:** If not using `--no-auth` and the page redirects to `/login`, the auth injection may have failed. Retry once with a page reload.

## Related Skills

- `/smoke-test` for testing multiple routes with console/network checks
- `/verify-feature` for post-implementation browser verification
