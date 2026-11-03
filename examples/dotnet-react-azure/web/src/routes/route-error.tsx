import { isRouteErrorResponse, Link, useRouteError } from 'react-router'
import { ErrorState } from '@/components/error-state'
import { Button } from '@/components/ui/button'

/** Route-level error boundary. Never renders raw error details to users. */
export function RouteError() {
  const error = useRouteError()
  const notFound = isRouteErrorResponse(error) && error.status === 404

  if (import.meta.env.DEV && !notFound) console.error(error)

  return (
    <div className="container mx-auto flex flex-col gap-6 px-4 py-6">
      <h1 className="text-2xl font-bold">{notFound ? 'Page not found' : 'Unexpected error'}</h1>
      <ErrorState
        title={notFound ? 'Nothing here' : 'Something went wrong'}
        message={
          notFound
            ? 'The page you are looking for does not exist.'
            : 'An unexpected error occurred. Please reload the page.'
        }
      >
        <Button asChild variant="outline" size="sm">
          <Link to="/orders">Go to orders</Link>
        </Button>
      </ErrorState>
    </div>
  )
}
