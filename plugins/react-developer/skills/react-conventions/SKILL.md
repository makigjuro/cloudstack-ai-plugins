---
name: react-conventions
description: React + TypeScript frontend conventions — centralized API client, API services, state management, components, and file organization. Apply whenever writing or editing frontend .ts/.tsx code.
user-invocable: false
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "web/src/**/*.ts"
  - "web/src/**/*.tsx"
---

# React Frontend Rules

These rules apply to React + TypeScript frontend code. Adapt paths based on the project's `blueprint.json` `frontend.path` setting (default: `web`).

## API Client

- Centralize HTTP calls through a single API client (Axios instance, fetch wrapper, or similar)
- Request interceptor adds auth: JWT Bearer token or API key header from auth store
- Response interceptor handles 401 -> redirect to login
- All API calls should be typed — `Promise<T>` return types, no implicit `any`
- Define an error class or type with code, status, and details fields for consistent error handling

## API Services

- Organize by domain: one file per resource (e.g., `users.api.ts`, `orders.api.ts`, `products.api.ts`)
- Functions return typed `Promise<T>`
- Use `URLSearchParams` for query parameters
- Pagination via `pageNumber` and `pageSize` query params; list responses are `{ items, totalCount, pageNumber, pageSize }` (matches the .NET `{Name}ListResponse`)
- Response mapping functions to convert API shapes to frontend types when needed
- If the project uses multi-tenancy, the backend derives the tenant from the token claim -- do not send a tenant ID unless the existing API explicitly expects one

## State Management

### Server State

Use TanStack Query (React Query), SWR, or RTK Query — whichever the project uses:

- **TanStack Query:**
  - One hook per query/mutation: `useUsers()`, `useCreateUser()`
  - Query hooks: `useQuery({ queryKey: [...], queryFn: ... })`
  - Mutation hooks: `useMutation({ mutationFn: ..., onSuccess: ... })`
  - Invalidate queries on mutations: `queryClient.invalidateQueries({ queryKey: [...] })`
  - Stale time: 30-60 seconds, refetch intervals: 60 seconds for live data

- **SWR:**
  - Use `useSWR` for reads, `useSWRMutation` for writes
  - Use `mutate` for cache invalidation

- **RTK Query:**
  - Define endpoints in API slices with `createApi`
  - Use generated hooks (`useGetUsersQuery`, `useCreateUserMutation`)

### Client State

Use Zustand, Redux, Jotai, or whatever the project uses:

- Auth store: holds the access token in memory only (never written to browser storage) plus auth state; the auth library (OIDC/MSAL) owns token storage and silent renewal, the store just hands the token to the API client
- Persist only non-sensitive UI preferences (e.g. page size) to localStorage, with `persist` + `partialize`
- Keep client state minimal — prefer server state for anything fetched from APIs

## Components

- TypeScript strict mode, no `any` types
- Props defined as interfaces
- Functional components only
- Use the project's UI library consistently (shadcn/ui, MUI, Chakra UI, Ant Design, etc.)
- Keep components small and focused — one responsibility per component
- Co-locate component-specific types with the component file

## File Organization

- Feature-based structure: `features/{name}/pages/`, `features/{name}/components/`
- Shared components in `components/` at the root level
- API services in `api/services/`
- Server-state hooks in `hooks/api/use-{feature}.ts` (query-key factory + `use{Feature}s`, `use{Feature}`, `useCreate{Feature}`); components import the hooks, not `useQuery` directly
- Types in `types/` or co-located with the code that uses them
