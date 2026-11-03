import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { formatAmount, formatDate } from '../lib/format'
import type { Order } from '../types'
import { OrderStatusBadge } from './order-status-badge'

interface OrderDetailsProps {
  order: Order
}

export function OrderDetails({ order }: OrderDetailsProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>
          <h2>{order.customerName}</h2>
        </CardTitle>
        <CardDescription>Order {order.id}</CardDescription>
      </CardHeader>
      <CardContent>
        <dl className="grid grid-cols-[max-content_1fr] gap-x-6 gap-y-3 text-sm">
          <dt className="text-muted-foreground">Status</dt>
          <dd>
            <OrderStatusBadge status={order.status} />
          </dd>
          <dt className="text-muted-foreground">Total amount</dt>
          <dd className="tabular-nums">{formatAmount(order.totalAmount)}</dd>
          <dt className="text-muted-foreground">Created</dt>
          <dd>
            <time dateTime={order.createdAt}>{formatDate(order.createdAt)}</time>
          </dd>
        </dl>
      </CardContent>
    </Card>
  )
}
