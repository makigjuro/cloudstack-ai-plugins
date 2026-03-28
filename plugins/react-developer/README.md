# react-developer

A Claude Code plugin for React + TypeScript frontend development. Provides skills for scaffolding feature modules, capturing screenshots, smoke testing, and visual verification using Playwright.

## Skills

| Skill | Description |
|-------|-------------|
| `/add-feature` | Scaffold a new frontend feature module with page, components, API service, and route |
| `/screenshot` | Capture a screenshot of a URL or route — supports mobile viewport and auth bypass |
| `/verify-feature` | Auto-detect changed routes, navigate them, take screenshots, check for console/network errors |
| `/smoke-test` | Smoke test the running app by navigating key routes and checking for breakage |

## Rules

| Rule | Scope |
|------|-------|
| `react-frontend` | General React + TypeScript conventions: API client, state management, components, file organization |
| `security-frontend` | Frontend security: XSS prevention, auth token handling, no hardcoded secrets, CORS |

## Configuration

This plugin reads `cloudstack.json` from the project root to adapt to your project's setup. If the file doesn't exist, it falls back to auto-detection from `package.json`.

### Example `cloudstack.json`

```json
{
  "frontend": {
    "path": "web",
    "devPort": 5173,
    "uiLibrary": "shadcn",
    "stateManagement": {
      "server": "tanstack-query",
      "client": "zustand"
    }
  },
  "backend": {
    "devPort": 5000,
    "multiTenancy": false
  },
  "localDev": {
    "orchestrator": "none",
    "orchestratorPort": null,
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

### Configuration Reference

| Key | Default | Description |
|-----|---------|-------------|
| `frontend.path` | `web` | Path to the frontend project root |
| `frontend.devPort` | `5173` | Dev server port |
| `frontend.uiLibrary` | `shadcn` | UI library: `shadcn`, `mui`, `chakra`, `ant` |
| `frontend.stateManagement.server` | `tanstack-query` | Server state: `tanstack-query`, `swr`, `redux-toolkit` |
| `frontend.stateManagement.client` | `zustand` | Client state: `zustand`, `redux`, `jotai` |
| `backend.devPort` | `5000` | API server port |
| `backend.multiTenancy` | `false` | Whether to include tenant scoping in API calls |
| `localDev.orchestrator` | `none` | Dev orchestrator: `aspire`, `docker-compose`, `none` |
| `localDev.orchestratorPort` | `null` | Orchestrator dashboard port |
| `localDev.authConfig` | `null` | Auth config for localStorage injection during dev |

## Prerequisites

- **Playwright MCP server** must be configured for screenshot, verify-feature, and smoke-test skills
- **context7 MCP server** (optional) enables library documentation lookup in add-feature

## Installation

Add the plugin to your Claude Code project configuration. The plugin's skills and rules will be automatically available.
