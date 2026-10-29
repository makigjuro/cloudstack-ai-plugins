/**
 * Typed access to build-time environment variables.
 * VITE_* values are embedded in the bundle: never put secrets here.
 */
export const env = {
  /** Empty string = same origin (the Vite dev proxy forwards /api in development). */
  apiBaseUrl: (import.meta.env.VITE_API_BASE_URL ?? '').replace(/\/+$/, ''),
}
