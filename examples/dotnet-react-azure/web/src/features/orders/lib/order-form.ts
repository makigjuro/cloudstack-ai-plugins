import type { CreateOrderRequest } from '../types'

export const CUSTOMER_NAME_MAX_LENGTH = 200
export const TOTAL_AMOUNT_MAX = 1_000_000_000

export interface OrderFormValues {
  customerName: string
  totalAmount: string
}

export type OrderFormField = keyof OrderFormValues
export type OrderFormErrors = Partial<Record<OrderFormField, string>>

export const emptyOrderForm: OrderFormValues = { customerName: '', totalAmount: '' }

const AMOUNT_PATTERN = /^\d+(\.\d{1,2})?$/

export function validateOrderField(
  field: OrderFormField,
  values: OrderFormValues,
): string | undefined {
  if (field === 'customerName') {
    const name = values.customerName.trim()
    if (!name) return 'Customer name is required.'
    if (name.length > CUSTOMER_NAME_MAX_LENGTH) {
      return `Customer name must be at most ${CUSTOMER_NAME_MAX_LENGTH} characters.`
    }
    return undefined
  }

  const amount = values.totalAmount.trim()
  if (!amount) return 'Total amount is required.'
  if (!AMOUNT_PATTERN.test(amount)) {
    return 'Enter a positive amount with up to two decimal places.'
  }
  const value = Number(amount)
  if (value <= 0) return 'Total amount must be greater than zero.'
  if (value > TOTAL_AMOUNT_MAX) return 'Total amount is too large.'
  return undefined
}

export function validateOrderForm(values: OrderFormValues): OrderFormErrors {
  const errors: OrderFormErrors = {}
  for (const field of ['customerName', 'totalAmount'] as const) {
    const message = validateOrderField(field, values)
    if (message) errors[field] = message
  }
  return errors
}

export function toCreateOrderRequest(values: OrderFormValues): CreateOrderRequest {
  return {
    customerName: values.customerName.trim(),
    totalAmount: Number(values.totalAmount.trim()),
  }
}
