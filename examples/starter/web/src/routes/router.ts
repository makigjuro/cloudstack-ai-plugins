import { createBrowserRouter } from 'react-router'
import { bindUnauthorizedRedirect } from './auth-redirect'
import { routes } from './routes'

export const router = createBrowserRouter(routes)
bindUnauthorizedRedirect(router)
