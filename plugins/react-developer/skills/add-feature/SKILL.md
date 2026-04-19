---
name: add-feature
description: Scaffold a new frontend feature module with page, components, API service, and hooks. Use whenever the user wants to add a new page, dashboard section, UI module, or frontend feature to the React app.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__context7__resolve-library-id, mcp__context7__query-docs
user-invocable: true
argument-hint: "{feature-name}"
---

# Add Frontend Feature

Scaffold a new feature module following the project's React + TypeScript conventions.

## Arguments

- `{feature}` — Feature name in kebab-case (e.g., `alerts`, `settings`, `users`)

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `FRONTEND_PATH` = `frontend.path` (default: `web`)
- `DEV_PORT` = `frontend.devPort` (default: `5173`)
- `UI_LIBRARY` = `frontend.uiLibrary` (default: `shadcn`)
- `STATE_SERVER` = `frontend.stateManagement.server` (default: `tanstack-query`)
- `STATE_CLIENT` = `frontend.stateManagement.client` (default: `zustand`)
- `MULTI_TENANT` = `backend.multiTenancy` (default: `false`)

If `cloudstack.json` does not exist, auto-detect by checking `package.json` dependencies.

## Structure

Creates the following structure under `{FRONTEND_PATH}/src/features/{feature}/`:

```
{feature}/
├── pages/
│   └── {feature}-page.tsx
└── components/
    └── {feature}-overview.tsx
```

And adds an API service at `{FRONTEND_PATH}/src/api/services/{feature}.api.ts`.

## 0. Detect Existing Patterns

Before scaffolding, scan the project for existing conventions:

```bash
# Find existing API client
find {FRONTEND_PATH}/src/api -name "client.*" -o -name "http.*" -o -name "axios.*" 2>/dev/null | head -5

# Find existing feature modules for reference
ls -d {FRONTEND_PATH}/src/features/*/pages/ 2>/dev/null | head -3

# Check for multi-tenancy utility
grep -rl "tenantId\|appendTenant\|multiTenant" {FRONTEND_PATH}/src/api/ 2>/dev/null | head -3
```

Read any existing API service file and feature page to match the project's established patterns.

## 1. API Service (`{FRONTEND_PATH}/src/api/services/{feature}.api.ts`)

Adapt the template based on the existing API client pattern detected in step 0.

### If using a custom `apiRequest` wrapper:

```typescript
/**
 * {Feature} API client
 */

import { apiRequest } from '../client'
import type { PaginatedResponse } from '../types'

// Define types inline or in ../types/index.ts
export interface {Entity} {
  id: string
  // fields
}

const BASE_PATH = '/api/{feature}'

export const {feature}Api = {
  /**
   * Get paginated list
   */
  async getAll(page = 1, pageSize = 20): Promise<PaginatedResponse<{Entity}>> {
    const params = new URLSearchParams()
    params.set('pageNumber', page.toString())
    params.set('pageSize', pageSize.toString())

    return apiRequest({ url: BASE_PATH, params })
  },

  /**
   * Get by ID
   */
  async getById(id: string): Promise<{Entity}> {
    return apiRequest({ url: `${BASE_PATH}/${id}` })
  },
}
```

### If `MULTI_TENANT` is true:

Look for the existing tenant utility (e.g., `appendTenantId`, `withTenantParams`, or similar). If found, import it and apply to each API call's query parameters. If no utility exists, add tenant ID from the auth store:

```typescript
// Add to each method that needs tenant scoping:
const params = new URLSearchParams()
appendTenantId(params) // or use whatever pattern the project uses
```

### If using plain axios/fetch:

Match the existing pattern exactly. Do not introduce a new abstraction.

## 2. Page (`{FRONTEND_PATH}/src/features/{feature}/pages/{feature}-page.tsx`)

```tsx
import { {Feature}Overview } from '../components/{feature}-overview'

export function {Feature}Page() {
  return (
    <div className="container mx-auto py-6">
      <{Feature}Overview />
    </div>
  )
}
```

## 3. Overview Component (`{FRONTEND_PATH}/src/features/{feature}/components/{feature}-overview.tsx`)

Adapt based on `STATE_SERVER`:

### If `tanstack-query` (default):

```tsx
import { useQuery } from '@tanstack/react-query'
import { {feature}Api } from '@/api/services/{feature}.api'

export function {Feature}Overview() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['{feature}'],
    queryFn: () => {feature}Api.getAll(),
    staleTime: 30_000,
  })

  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error loading {feature}</div>

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">{Feature}</h1>
      {/* Render data */}
    </div>
  )
}
```

### If `swr`:

```tsx
import useSWR from 'swr'
import { {feature}Api } from '@/api/services/{feature}.api'

export function {Feature}Overview() {
  const { data, error, isLoading } = useSWR('{feature}', () => {feature}Api.getAll())

  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error loading {feature}</div>

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">{Feature}</h1>
      {/* Render data */}
    </div>
  )
}
```

### If `redux-toolkit` (RTK Query):

Follow the project's existing RTK Query slice pattern. Look for `createApi` usage and extend it rather than creating a standalone file.

### UI Library Adaptation

- **shadcn** (default): Use shadcn/ui components with Tailwind CSS classes
- **mui**: Use Material UI `<Box>`, `<Typography>`, `<Stack>` etc.
- **chakra**: Use Chakra UI `<Box>`, `<Heading>`, `<VStack>` etc.
- **ant**: Use Ant Design `<Card>`, `<Table>`, `<Typography.Title>` etc.

Match whichever UI library is detected in the project's `package.json`.

## 4. Add Route

Find the router configuration file and add the route automatically:

```bash
# Find the router file
grep -rl "createBrowserRouter\|RouteObject\|path:" {FRONTEND_PATH}/src/routes/ {FRONTEND_PATH}/src/App.tsx 2>/dev/null | head -1
```

Read the router file, then add the import and route entry:

```tsx
import { {Feature}Page } from '@/features/{feature}/pages/{feature}-page'

// Add to the routes array alongside existing routes:
{ path: '/{feature}', element: <{Feature}Page /> }
```

If the router structure is unclear or uses a pattern you don't recognize, show the user what to add and where instead of guessing.

## Checklist

- [ ] API service follows existing client pattern
- [ ] Multi-tenancy support included if `MULTI_TENANT` is true
- [ ] Types defined as interfaces, no `any`
- [ ] Server state management matches `STATE_SERVER` config
- [ ] UI components match `UI_LIBRARY` config
- [ ] Functional components only
- [ ] Route added to router config

## Guidelines

- Follow existing features in the project as reference
- Keep components small and focused
- Use barrel exports where the project already does
- If using unfamiliar library patterns (infinite queries, optimistic updates, prefetching), use context7 to look up the current API

## Output

After scaffolding, report:
```
## Scaffolded: {Feature} frontend feature

Files created:
- `{FRONTEND_PATH}/src/api/services/{feature}.api.ts`
- `{FRONTEND_PATH}/src/features/{feature}/pages/{feature}-page.tsx`
- `{FRONTEND_PATH}/src/features/{feature}/components/{feature}-overview.tsx`
- Route added to `{router-file}`

Next: Run `cd {FRONTEND_PATH} && npm run dev` to preview, or `/verify-feature /{feature}` to verify.
```

## Error Handling

- **Router file not found:** Show the route snippet and ask the user where to add it.
- **API client pattern not detected:** Check `{FRONTEND_PATH}/src/api/` — if no client exists, create a minimal fetch-based client and note it for the user.
- **Feature directory already exists:** Warn the user and ask whether to overwrite or extend.

## Related Skills

- `/verify-feature` to visually verify the scaffolded feature
- `/screenshot` to capture what the new page looks like
