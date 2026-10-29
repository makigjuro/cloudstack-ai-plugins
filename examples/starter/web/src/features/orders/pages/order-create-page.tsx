import { Link, useNavigate } from 'react-router'
import { useCreateOrder } from '@/hooks/api/use-orders'
import { getErrorMessage } from '@/lib/error-messages'
import { OrderForm } from '../components/order-form'
import { toCreateOrderRequest, type OrderFormValues } from '../lib/order-form'

export function OrderCreatePage() {
  const navigate = useNavigate()
  const createOrder = useCreateOrder()

  function handleSubmit(values: OrderFormValues) {
    createOrder.mutate(toCreateOrderRequest(values), {
      onSuccess: ({ id }) => void navigate(`/orders/${encodeURIComponent(id)}`),
    })
  }

  return (
    <div className="container mx-auto flex flex-col gap-6 py-6">
      <Link
        to="/orders"
        className="text-muted-foreground text-sm underline-offset-4 hover:underline"
      >
        ← Back to orders
      </Link>
      <h1 className="text-2xl font-bold">New order</h1>
      <OrderForm
        onSubmit={handleSubmit}
        isSubmitting={createOrder.isPending}
        submitError={createOrder.isError ? getErrorMessage(createOrder.error) : undefined}
        onCancel={() => void navigate('/orders')}
      />
    </div>
  )
}
