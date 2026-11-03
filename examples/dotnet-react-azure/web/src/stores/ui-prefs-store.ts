import { create } from 'zustand'
import { createJSONStorage, persist } from 'zustand/middleware'

export const PAGE_SIZE_OPTIONS = [10, 20, 50] as const
export type PageSize = (typeof PAGE_SIZE_OPTIONS)[number]

interface UiPrefsState {
  ordersPageSize: PageSize
  setOrdersPageSize: (size: PageSize) => void
}

/** Non-sensitive UI preferences, persisted to localStorage. */
export const useUiPrefsStore = create<UiPrefsState>()(
  persist(
    (set) => ({
      ordersPageSize: 20,
      setOrdersPageSize: (size) => {
        set({ ordersPageSize: size })
      },
    }),
    {
      name: 'starter-ui-prefs',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({ ordersPageSize: state.ordersPageSize }),
    },
  ),
)
