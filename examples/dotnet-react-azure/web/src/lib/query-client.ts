import { QueryClient } from '@tanstack/react-query'
import { isApiError } from '@/api/client'

const NO_RETRY_CODES = new Set([
  'bad_request',
  'unauthorized',
  'forbidden',
  'not_found',
  'conflict',
])

export function createQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30_000,
        refetchOnWindowFocus: false,
        // Client errors will not succeed on retry; only retry network/server failures.
        retry: (failureCount, error) =>
          !(isApiError(error) && NO_RETRY_CODES.has(error.code)) && failureCount < 2,
      },
      mutations: { retry: false },
    },
  })
}
