/** Shared API contract types. */

export interface PaginatedResponse<T> {
  items: T[]
  pageNumber: number
  pageSize: number
  totalCount: number
}

/** RFC 7807 problem details, as returned by the .NET services. */
export interface ProblemDetails {
  type?: string
  title?: string
  status?: number
  detail?: string
  errors?: Record<string, string[]>
  /** Entity-specific error code, e.g. `ORDER_NOT_FOUND`. */
  error?: string
  /** Human-readable message for the error code. */
  message?: string
  /** Error category: `Validation`, `NotFound`, `Conflict`, … */
  errorType?: string
}
