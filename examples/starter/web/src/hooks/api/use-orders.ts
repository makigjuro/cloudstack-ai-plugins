import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { ordersApi } from '@/api/services/orders.api'
import type { CreateOrderRequest } from '@/features/orders/types'

export const orderKeys = {
  all: ['orders'] as const,
  lists: () => [...orderKeys.all, 'list'] as const,
  list: (page: number, pageSize: number) => [...orderKeys.lists(), { page, pageSize }] as const,
  detail: (id: string) => [...orderKeys.all, 'detail', id] as const,
}

export function useOrders(page: number, pageSize: number) {
  return useQuery({
    queryKey: orderKeys.list(page, pageSize),
    queryFn: ({ signal }) => ordersApi.getAll(page, pageSize, signal),
    placeholderData: keepPreviousData,
    staleTime: 30_000,
  })
}

export function useOrder(id: string) {
  return useQuery({
    queryKey: orderKeys.detail(id),
    queryFn: ({ signal }) => ordersApi.getById(id, signal),
    staleTime: 30_000,
  })
}

export function useCreateOrder() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (request: CreateOrderRequest) => ordersApi.create(request),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: orderKeys.lists() }),
  })
}
