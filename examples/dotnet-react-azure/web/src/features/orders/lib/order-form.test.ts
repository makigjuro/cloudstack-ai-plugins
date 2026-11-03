import { toCreateOrderRequest, validateOrderForm } from './order-form'

describe('validateOrderForm', () => {
  it('requires both fields', () => {
    expect(validateOrderForm({ customerName: '  ', totalAmount: '' })).toEqual({
      customerName: 'Customer name is required.',
      totalAmount: 'Total amount is required.',
    })
  })

  it.each(['0', '-5', 'abc', '1.234', '1e3'])('rejects invalid amount %s', (totalAmount) => {
    expect(validateOrderForm({ customerName: 'Ada', totalAmount }).totalAmount).toBeDefined()
  })

  it('accepts a valid order and trims/coerces the request', () => {
    const values = { customerName: '  Ada Lovelace ', totalAmount: '49.90' }
    expect(validateOrderForm(values)).toEqual({})
    expect(toCreateOrderRequest(values)).toEqual({
      customerName: 'Ada Lovelace',
      totalAmount: 49.9,
    })
  })
})
