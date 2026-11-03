import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'
import { useAuthStore } from '@/stores/auth-store'

afterEach(() => {
  cleanup()
  useAuthStore.getState().clearAuth()
  localStorage.clear()
})
