/** Orders API contract (mirrors the Orders service endpoints). */

export type OrderStatus = 'Pending' | 'Confirmed' | 'Cancelled'

export interface Order {
  id: string
  customerName: string
  totalAmount: number
  status: OrderStatus
  /** ISO 8601 timestamp */
  createdAt: string
}

export interface CreateOrderRequest {
  customerName: string
  totalAmount: number
}

export interface CreateOrderResponse {
  id: string
}
