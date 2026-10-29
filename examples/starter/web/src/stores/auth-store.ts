import { create } from 'zustand'

interface AuthState {
  /** Bearer token held in memory only; it is never written to browser storage. */
  accessToken: string | null
  setAccessToken: (token: string) => void
  clearAuth: () => void
}

/**
 * Auth state. In production the token comes from the auth library (OIDC / MSAL),
 * which owns storage and silent renewal; this store only hands it to the API client.
 */
export const useAuthStore = create<AuthState>()((set) => ({
  accessToken: null,
  setAccessToken: (token) => {
    set({ accessToken: token })
  },
  clearAuth: () => {
    set({ accessToken: null })
  },
}))
