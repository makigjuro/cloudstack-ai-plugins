import { Suspense } from 'react'
import { NavLink, Outlet } from 'react-router'
import { LoadingState } from '@/components/loading-state'
import { cn } from '@/lib/utils'

function navClass({ isActive }: { isActive: boolean }) {
  return cn(
    'rounded-md px-3 py-1.5 text-sm font-medium underline-offset-4 hover:underline',
    isActive && 'bg-accent text-accent-foreground',
  )
}

export function RootLayout() {
  return (
    <div className="min-h-dvh">
      <a
        href="#main"
        className="focus:bg-background sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:rounded-md focus:p-2"
      >
        Skip to content
      </a>
      <header className="border-b">
        <div className="container mx-auto flex h-14 items-center gap-6 px-4">
          <span className="font-semibold">Starter</span>
          <nav aria-label="Main">
            <ul className="flex gap-1">
              <li>
                <NavLink to="/orders" end className={navClass}>
                  Orders
                </NavLink>
              </li>
              <li>
                <NavLink to="/orders/new" className={navClass}>
                  New order
                </NavLink>
              </li>
            </ul>
          </nav>
        </div>
      </header>
      <main id="main" className="px-4">
        <Suspense fallback={<LoadingState />}>
          <Outlet />
        </Suspense>
      </main>
    </div>
  )
}
