import { Badge } from '@/components/ui/badge'
import type { OrderStatus } from '../types'

const VARIANT: Record<OrderStatus, 'secondary' | 'default' | 'destructive'> = {
  Pending: 'secondary',
  Confirmed: 'default',
  Cancelled: 'destructive',
}

interface OrderStatusBadgeProps {
  status: OrderStatus
}

/** Status is always rendered as text; color is only a secondary cue. */
export function OrderStatusBadge({ status }: OrderStatusBadgeProps) {
  return <Badge variant={VARIANT[status]}>{status}</Badge>
}
