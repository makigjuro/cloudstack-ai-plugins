/**
 * Orders API client
 */

import type { CreateOrderRequest, CreateOrderResponse, Order } from '@/features/orders/types'
import { apiRequest } from '../client'
import type { PaginatedResponse } from '../types'

const BASE_PATH = '/api/orders'

export const ordersApi = {
  /**
   * Get paginated list
   */
  async getAll(page = 1, pageSize = 20, signal?: AbortSignal): Promise<PaginatedResponse<Order>> {
    const params = new URLSearchParams()
    params.set('pageNumber', page.toString())
    params.set('pageSize', pageSize.toString())

    return apiRequest({ url: BASE_PATH, params, signal })
  },

  /**
   * Get by ID
   */
  async getById(id: string, signal?: AbortSignal): Promise<Order> {
    return apiRequest({ url: `${BASE_PATH}/${encodeURIComponent(id)}`, signal })
  },

  /**
   * Create an order
   */
  async create(request: CreateOrderRequest): Promise<CreateOrderResponse> {
    return apiRequest({ url: BASE_PATH, method: 'POST', body: request })
  },
}
