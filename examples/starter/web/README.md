# Starter web

React 19 + TypeScript frontend for the starter app: Vite, React Router, TanStack Query (server state), Zustand (client state), Tailwind CSS v4 and shadcn/ui.

## Run

```bash
npm install
npm run dev        # http://localhost:5173
```

The dev server proxies `/api/*` to the API gateway at `http://localhost:5080` (start it with docker-compose from `examples/starter`).

## Scripts

| Script                      | What it does                                                      |
| --------------------------- | ----------------------------------------------------------------- |
| `npm run dev`               | Vite dev server on port 5173                                      |
| `npm run build`             | Type-check and build to `dist/`                                   |
| `npm run preview`           | Serve the production build locally                                |
| `npm run lint` / `lint:fix` | ESLint + Prettier check / auto-fix                                |
| `npm run type-check`        | TypeScript (strict), no emit                                      |
| `npm test`                  | Vitest + Testing Library (watch mode; `npm test -- --run` for CI) |

## Environment variables

Copy `.env.example` to `.env.local` to override.

| Variable            | Default             | Purpose                                                                                                    |
| ------------------- | ------------------- | ---------------------------------------------------------------------------------------------------------- |
| `VITE_API_BASE_URL` | empty (same origin) | Base URL of the API gateway, e.g. `https://api.example.com`. Leave empty in dev so the Vite proxy is used. |

`VITE_*` values are embedded in the browser bundle: never put secrets in them.

## Layout

```
src/
├── api/            client.ts (fetch wrapper, auth header, 401 handling), types/, services/*.api.ts
├── features/       orders/ (pages, components, lib, types.ts), auth/ (login placeholder)
├── hooks/api/      TanStack Query hooks
├── stores/         Zustand stores (in-memory auth token, persisted UI prefs)
├── routes/         route table (lazy pages), layout, error boundary
├── components/     shared components; components/ui = generated shadcn/ui
└── lib/            env, query client, error-message mapping, utils
```

## Auth

The access token lives in memory only (`stores/auth-store.ts`) and is attached as `Authorization: Bearer <token>`. A 401 clears it and redirects to `/login?redirect=…`. The login page is a placeholder: in development you can paste a token; for production wire in your OIDC/MSAL library, which owns token storage and silent renewal.

## Deploying to Azure Static Web Apps

`staticwebapp.config.json` adds the SPA fallback and security headers. Set `app_location: examples/starter/web`, `output_location: dist`. If the API is on a different origin, replace the `https://api.example.com` placeholder in the CSP `connect-src` with your API origin (JSON has no comments, so the placeholder is documented here) and set `VITE_API_BASE_URL` at build time.
