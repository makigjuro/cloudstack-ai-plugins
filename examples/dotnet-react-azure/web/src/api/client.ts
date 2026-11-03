/**
 * Central API client. Every HTTP call goes through `apiRequest`, which
 * adds the auth header, parses JSON and normalises failures into `ApiError`.
 */

import { env } from '@/lib/env'
import { useAuthStore } from '@/stores/auth-store'
import type { ProblemDetails } from './types'

export type ApiErrorCode =
  | 'network'
  | 'bad_request'
  | 'unauthorized'
  | 'forbidden'
  | 'not_found'
  | 'conflict'
  | 'server'
  | 'unknown'

export class ApiError extends Error {
  readonly code: ApiErrorCode
  readonly status: number
  readonly details?: ProblemDetails

  constructor(code: ApiErrorCode, status: number, details?: ProblemDetails) {
    super(`API request failed (${code}, HTTP ${status})`)
    this.name = 'ApiError'
    this.code = code
    this.status = status
    this.details = details
  }
}

export function isApiError(error: unknown): error is ApiError {
  return error instanceof ApiError
}

function codeForStatus(status: number): ApiErrorCode {
  if (status === 400 || status === 422) return 'bad_request'
  if (status === 401) return 'unauthorized'
  if (status === 403) return 'forbidden'
  if (status === 404) return 'not_found'
  if (status === 409) return 'conflict'
  if (status >= 500) return 'server'
  return 'unknown'
}

type UnauthorizedHandler = () => void
let unauthorizedHandler: UnauthorizedHandler | null = null

/** Registered by the router so a 401 can redirect to /login without a full reload. */
export function setUnauthorizedHandler(handler: UnauthorizedHandler | null) {
  unauthorizedHandler = handler
}

export interface ApiRequestOptions {
  url: string
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'
  params?: URLSearchParams
  body?: unknown
  signal?: AbortSignal
}

async function readProblem(response: Response): Promise<ProblemDetails | undefined> {
  try {
    return (await response.json()) as ProblemDetails
  } catch {
    return undefined
  }
}

export async function apiRequest<T>({
  url,
  method = 'GET',
  params,
  body,
  signal,
}: ApiRequestOptions): Promise<T> {
  const query = params?.size ? `?${params.toString()}` : ''
  const headers = new Headers({ Accept: 'application/json' })
  if (body !== undefined) headers.set('Content-Type', 'application/json')

  const token = useAuthStore.getState().accessToken
  if (token) headers.set('Authorization', `Bearer ${token}`)

  let response: Response
  try {
    response = await fetch(`${env.apiBaseUrl}${url}${query}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
      signal,
    })
  } catch (cause) {
    if (cause instanceof DOMException && cause.name === 'AbortError') throw cause
    throw new ApiError('network', 0)
  }

  if (!response.ok) {
    const details = await readProblem(response)
    const error = new ApiError(codeForStatus(response.status), response.status, details)
    if (import.meta.env.DEV) {
      // Method, path and status only: never log request headers (they carry the token).
      console.error(`[api] ${method} ${url} -> ${response.status}`, details)
    }
    if (error.code === 'unauthorized') {
      useAuthStore.getState().clearAuth()
      unauthorizedHandler?.()
    }
    throw error
  }

  if (response.status === 204) return undefined as T
  return (await response.json()) as T
}
