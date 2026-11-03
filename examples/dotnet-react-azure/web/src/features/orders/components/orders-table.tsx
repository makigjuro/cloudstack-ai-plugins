import { Link } from 'react-router'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { formatAmount, formatDate } from '../lib/format'
import type { Order } from '../types'
import { OrderStatusBadge } from './order-status-badge'

interface OrdersTableProps {
  orders: Order[]
}

export function OrdersTable({ orders }: OrdersTableProps) {
  return (
    <Table>
      <caption className="sr-only">Orders</caption>
      <TableHeader>
        <TableRow>
          <TableHead scope="col">Customer</TableHead>
          <TableHead scope="col">Status</TableHead>
          <TableHead scope="col" className="text-right">
            Total
          </TableHead>
          <TableHead scope="col">Created</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {orders.map((order) => (
          <TableRow key={order.id}>
            <TableCell>
              <Link
                to={`/orders/${encodeURIComponent(order.id)}`}
                className="font-medium underline-offset-4 hover:underline focus-visible:underline"
              >
                {order.customerName}
              </Link>
            </TableCell>
            <TableCell>
              <OrderStatusBadge status={order.status} />
            </TableCell>
            <TableCell className="text-right tabular-nums">
              {formatAmount(order.totalAmount)}
            </TableCell>
            <TableCell>
              <time dateTime={order.createdAt}>{formatDate(order.createdAt)}</time>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}
