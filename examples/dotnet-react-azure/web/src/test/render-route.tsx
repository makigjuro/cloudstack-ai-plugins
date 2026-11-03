import { QueryClientProvider } from '@tanstack/react-query'
import { render } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { createQueryClient } from '@/lib/query-client'
import { bindUnauthorizedRedirect } from '@/routes/auth-redirect'
import { routes } from '@/routes/routes'

/** Renders the real route table at `path` with a fresh, retry-free query client. */
export function renderRoute(path: string) {
  const queryClient = createQueryClient()
  queryClient.setDefaultOptions({ queries: { retry: false, staleTime: 0 } })
  const router = createMemoryRouter(routes, { initialEntries: [path] })
  bindUnauthorizedRedirect(router)
  const utils = render(
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>,
  )
  return { ...utils, router }
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

export function mockFetch(handler: (url: URL, init?: RequestInit) => Response | Promise<Response>) {
  const fn = vi.fn((input: RequestInfo | URL, init?: RequestInit) => {
    const raw = input instanceof Request ? input.url : input.toString()
    return Promise.resolve(handler(new URL(raw, 'http://localhost'), init))
  })
  vi.stubGlobal('fetch', fn)
  return fn
}
