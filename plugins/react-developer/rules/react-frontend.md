---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "web/src/**/*.ts"
  - "web/src/**/*.tsx"
---

# React Frontend Rules

These rules apply to React + TypeScript frontend code. Adapt paths based on the project's `cloudstack.json` `frontend.path` setting (default: `web`).

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
- Pagination via standard params (e.g., `pageNumber` and `pageSize` or `page` and `limit`)
- Response mapping functions to convert API shapes to frontend types when needed
- If the project uses multi-tenancy, apply tenant scoping consistently across all API calls

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

- Auth store: stores user info, tokens, authentication state
- Persist to localStorage with selective field storage (don't persist sensitive data unnecessarily)
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
- Hooks in `hooks/` or co-located with features
- Types in `types/` or co-located with the code that uses them
