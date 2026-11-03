import { Link } from 'react-router'
import { EmptyState } from '@/components/empty-state'
import { ErrorState } from '@/components/error-state'
import { LoadingState } from '@/components/loading-state'
import { Pagination } from '@/components/pagination'
import { Button } from '@/components/ui/button'
import { useOrders } from '@/hooks/api/use-orders'
import { getErrorMessage } from '@/lib/error-messages'
import { useUiPrefsStore } from '@/stores/ui-prefs-store'
import { usePageParam } from '../lib/use-page-param'
import { OrdersTable } from './orders-table'
import { PageSizeSelect } from './page-size-select'

export function OrdersOverview() {
  const [page, setPage] = usePageParam()
  const pageSize = useUiPrefsStore((s) => s.ordersPageSize)
  const { data, isPending, isError, error, refetch, isPlaceholderData } = useOrders(page, pageSize)

  if (isPending) return <LoadingState label="Loading orders…" />
  if (isError) {
    return (
      <ErrorState
        title="Could not load orders"
        message={getErrorMessage(error)}
        onRetry={() => void refetch()}
      />
    )
  }

  if (data.totalCount === 0) {
    return (
      <EmptyState
        title="No orders yet"
        description="Orders you create will appear here."
        action={
          <Button asChild>
            <Link to="/orders/new">Create your first order</Link>
          </Button>
        }
      />
    )
  }

  if (data.items.length === 0) {
    return (
      <EmptyState
        title="This page is empty"
        description={`There are only ${data.totalCount} orders.`}
        action={
          <Button
            variant="outline"
            onClick={() => {
              setPage(1)
            }}
          >
            Go to first page
          </Button>
        }
      />
    )
  }

  return (
    <div className="flex flex-col gap-4" aria-busy={isPlaceholderData}>
      <OrdersTable orders={data.items} />
      <div className="flex flex-wrap items-center justify-between gap-4">
        <PageSizeSelect
          onChange={() => {
            setPage(1)
          }}
        />
        <Pagination
          page={data.pageNumber}
          pageSize={data.pageSize}
          totalCount={data.totalCount}
          onPageChange={setPage}
          disabled={isPlaceholderData}
        />
      </div>
    </div>
  )
}
