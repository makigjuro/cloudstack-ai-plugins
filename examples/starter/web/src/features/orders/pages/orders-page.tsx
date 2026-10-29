import { Plus } from 'lucide-react'
import { Link } from 'react-router'
import { Button } from '@/components/ui/button'
import { OrdersOverview } from '../components/orders-overview'

export function OrdersPage() {
  return (
    <div className="container mx-auto flex flex-col gap-6 py-6">
      <div className="flex items-center justify-between gap-4">
        <h1 className="text-2xl font-bold">Orders</h1>
        <Button asChild>
          <Link to="/orders/new">
            <Plus aria-hidden="true" />
            New order
          </Link>
        </Button>
      </div>
      <OrdersOverview />
    </div>
  )
}
