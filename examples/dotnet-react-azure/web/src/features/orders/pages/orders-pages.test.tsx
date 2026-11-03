import { screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { useAuthStore } from '@/stores/auth-store'
import { jsonResponse, mockFetch, renderRoute } from '@/test/render-route'
import type { Order } from '../types'

const order: Order = {
  id: 'a1b2',
  customerName: 'Ada Lovelace',
  totalAmount: 49.9,
  status: 'Confirmed',
  createdAt: '2026-10-01T10:00:00Z',
}

describe('orders list (/orders)', () => {
  it('renders orders from the API with page params and status as text', async () => {
    const fetchMock = mockFetch(() =>
      jsonResponse({ items: [order], pageNumber: 1, pageSize: 20, totalCount: 1 }),
    )

    renderRoute('/orders')

    const table = await screen.findByRole('table')
    expect(within(table).getByRole('link', { name: 'Ada Lovelace' })).toHaveAttribute(
      'href',
      '/orders/a1b2',
    )
    expect(within(table).getByText('Confirmed')).toBeInTheDocument()
    const url = new URL(fetchMock.mock.calls[0]?.[0] as string, 'http://localhost')
    expect(url.pathname).toBe('/api/orders')
    expect(url.searchParams.get('pageNumber')).toBe('1')
    expect(url.searchParams.get('pageSize')).toBe('20')
  })

  it('shows the empty state when there are no orders', async () => {
    mockFetch(() => jsonResponse({ items: [], pageNumber: 1, pageSize: 20, totalCount: 0 }))
    renderRoute('/orders')
    expect(await screen.findByText('No orders yet')).toBeInTheDocument()
  })

  it('shows a friendly error without leaking server details', async () => {
    mockFetch(() => jsonResponse({ title: 'NullReferenceException at Foo.Bar()' }, 500))
    renderRoute('/orders')
    expect(await screen.findByRole('alert')).toHaveTextContent(/server encountered an error/i)
    expect(screen.queryByText(/NullReferenceException/)).not.toBeInTheDocument()
  })

  it('on 401 clears the in-memory token and redirects to /login', async () => {
    useAuthStore.getState().setAccessToken('test-token')
    const fetchMock = mockFetch(() => jsonResponse({}, 401))
    const { router } = renderRoute('/orders?page=2')

    expect(await screen.findByRole('heading', { name: 'Sign in' })).toBeInTheDocument()
    const headers = new Headers(fetchMock.mock.calls[0]?.[1]?.headers)
    expect(headers.get('Authorization')).toBe('Bearer test-token')
    expect(useAuthStore.getState().accessToken).toBeNull()
    expect(router.state.location.search).toBe(`?redirect=${encodeURIComponent('/orders?page=2')}`)
  })
})

describe('create order (/orders/new)', () => {
  it('validates accessibly and does not call the API when invalid', async () => {
    const fetchMock = mockFetch(() => jsonResponse({ id: 'x' }, 201))
    const user = userEvent.setup()
    renderRoute('/orders/new')

    await user.click(await screen.findByRole('button', { name: 'Create order' }))

    const name = screen.getByLabelText('Customer name')
    expect(name).toHaveAttribute('aria-invalid', 'true')
    expect(name).toHaveAccessibleDescription('Customer name is required.')
    expect(name).toHaveFocus()
    expect(screen.getByLabelText('Total amount')).toHaveAttribute('aria-invalid', 'true')
    expect(fetchMock).not.toHaveBeenCalled()
  })

  it('posts the order and navigates to its detail page', async () => {
    const fetchMock = mockFetch((_url, init) =>
      init?.method === 'POST' ? jsonResponse({ id: 'a1b2' }, 201) : jsonResponse(order),
    )
    const user = userEvent.setup()
    const { router } = renderRoute('/orders/new')

    await user.type(await screen.findByLabelText('Customer name'), 'Ada Lovelace')
    await user.type(screen.getByLabelText('Total amount'), '49.90')
    await user.keyboard('{Enter}')

    expect(await screen.findByRole('heading', { name: 'Ada Lovelace' })).toBeInTheDocument()
    expect(router.state.location.pathname).toBe('/orders/a1b2')
    const [, init] = fetchMock.mock.calls[0] ?? []
    expect(init?.method).toBe('POST')
    expect(JSON.parse(init?.body as string)).toEqual({
      customerName: 'Ada Lovelace',
      totalAmount: 49.9,
    })
  })
})

describe('order detail (/orders/:id)', () => {
  it('shows a not-found state on 404', async () => {
    mockFetch(() => jsonResponse({ title: 'Not Found' }, 404))
    renderRoute('/orders/missing')
    expect(await screen.findByText('Order not found')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'View all orders' })).toBeInTheDocument()
  })
})
