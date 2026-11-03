import { Navigate, type RouteObject } from 'react-router'
import { RootLayout } from './root-layout'
import { RouteError } from './route-error'

/** Route table. Pages are lazy-loaded so each route is its own chunk. */
export const routes: RouteObject[] = [
  {
    path: '/',
    element: <RootLayout />,
    errorElement: <RouteError />,
    children: [
      {
        errorElement: <RouteError />,
        children: [
          { index: true, element: <Navigate to="/orders" replace /> },
          {
            path: 'orders',
            lazy: async () => ({
              Component: (await import('@/features/orders/pages/orders-page')).OrdersPage,
            }),
          },
          {
            path: 'orders/new',
            lazy: async () => ({
              Component: (await import('@/features/orders/pages/order-create-page'))
                .OrderCreatePage,
            }),
          },
          {
            path: 'orders/:id',
            lazy: async () => ({
              Component: (await import('@/features/orders/pages/order-detail-page'))
                .OrderDetailPage,
            }),
          },
          {
            path: 'login',
            lazy: async () => ({
              Component: (await import('@/features/auth/pages/login-page')).LoginPage,
            }),
          },
          { path: '*', element: <RouteError /> },
        ],
      },
    ],
  },
]
