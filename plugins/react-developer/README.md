# react-developer

**The frontend layer of the [cloudstack reference architecture](../../README.md).** It builds React + TypeScript feature modules on a consistent structure and checks them in a real browser.

```
/plugin install react-developer@cloudstack-ai-plugins
```

## The architecture it follows

- **Feature modules:** each one has its own page, components, API service and hooks.
- **API access:** one central client.
- **State:** server state in your configured library (TanStack Query by default) and shared client state in your store (Zustand by default).
- **Security defaults:** no raw HTML without sanitizing, careful token storage, no secrets in the bundle.

## Skills

| Skill | What it does |
|---|---|
| `/react-developer:add-feature orders` | Scaffolds a feature module with page, components, API service, hooks and route |
| `/react-developer:verify-feature` | Finds routes changed on the branch, opens them, takes screenshots, and checks console and network errors |
| `/react-developer:smoke-test` | Opens the app's key routes and catches broken pages, auth issues and failing API calls |
| `/react-developer:screenshot /orders --mobile` | Screenshots one URL or route |

**Agent:** `react-developer:frontend-reviewer` reviews accessibility, performance, React patterns and security. `/dev-workflow:complete-task` runs it when frontend files change.

**Convention skills:** `react-conventions` and `frontend-security`. Claude applies them automatically to frontend `.ts`/`.tsx` files.

## Configuration

```json
{
  "frontend": {
    "path": "web",
    "devPort": 5173,
    "uiLibrary": "shadcn",
    "stateManagement": { "server": "tanstack-query", "client": "zustand" }
  },
  "localDev": {
    "authConfig": { "storageKey": "auth-storage", "state": { "isAuthenticated": true, "token": "dev-token" } }
  }
}
```

| Key | Default | Options |
|---|---|---|
| `frontend.path` | `web` | path to the frontend root |
| `frontend.devPort` | `5173` | dev server port |
| `frontend.uiLibrary` | `shadcn` | `shadcn`, `mui`, `chakra`, `ant` |
| `frontend.stateManagement.server` | `tanstack-query` | `tanstack-query`, `swr`, `redux-toolkit` |
| `frontend.stateManagement.client` | `zustand` | `zustand`, `redux`, `jotai` |
| `localDev.authConfig` | none | auth state injected into localStorage for browser checks |

**MCP servers:** Playwright (browser checks) and context7 (library docs) are bundled.
