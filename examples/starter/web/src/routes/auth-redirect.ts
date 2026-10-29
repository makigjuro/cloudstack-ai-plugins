import { setUnauthorizedHandler } from '@/api/client'

interface NavigableRouter {
  state: { location: { pathname: string; search: string } }
  navigate: (to: string) => Promise<void>
}

/** On 401 the API client clears auth state; send the user to sign in and come back afterwards. */
export function bindUnauthorizedRedirect(router: NavigableRouter) {
  setUnauthorizedHandler(() => {
    const { pathname, search } = router.state.location
    if (pathname === '/login') return
    void router.navigate(`/login?redirect=${encodeURIComponent(pathname + search)}`)
  })
}
