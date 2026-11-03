import { Link, useParams } from 'react-router'
import { isApiError } from '@/api/client'
import { ErrorState } from '@/components/error-state'
import { LoadingState } from '@/components/loading-state'
import { Button } from '@/components/ui/button'
import { useOrder } from '@/hooks/api/use-orders'
import { getErrorMessage } from '@/lib/error-messages'
import { OrderDetails } from '../components/order-details'

export function OrderDetailPage() {
  const { id = '' } = useParams()
  const { data: order, isPending, isError, error, refetch } = useOrder(id)

  return (
    <div className="container mx-auto flex flex-col gap-6 py-6">
      <Link
        to="/orders"
        className="text-muted-foreground text-sm underline-offset-4 hover:underline"
      >
        ← Back to orders
      </Link>
      <h1 className="text-2xl font-bold">Order details</h1>
      {isPending && <LoadingState label="Loading order…" />}
      {isError &&
        (isApiError(error) && error.code === 'not_found' ? (
          <ErrorState title="Order not found" message="This order does not exist or was removed.">
            <Button asChild variant="outline" size="sm">
              <Link to="/orders">View all orders</Link>
            </Button>
          </ErrorState>
        ) : (
          <ErrorState
            title="Could not load order"
            message={getErrorMessage(error)}
            onRetry={() => void refetch()}
          />
        ))}
      {order && <OrderDetails order={order} />}
    </div>
  )
}
