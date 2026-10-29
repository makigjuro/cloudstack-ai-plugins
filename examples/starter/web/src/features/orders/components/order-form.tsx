import { useId, useRef, useState, type ChangeEvent, type FocusEvent, type SubmitEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  CUSTOMER_NAME_MAX_LENGTH,
  emptyOrderForm,
  validateOrderField,
  validateOrderForm,
  type OrderFormErrors,
  type OrderFormField,
  type OrderFormValues,
} from '../lib/order-form'

interface OrderFormProps {
  onSubmit: (values: OrderFormValues) => void
  isSubmitting?: boolean
  /** User-facing error from the last submit attempt. */
  submitError?: string
  onCancel?: () => void
}

export function OrderForm({
  onSubmit,
  isSubmitting = false,
  submitError,
  onCancel,
}: OrderFormProps) {
  const id = useId()
  const [values, setValues] = useState<OrderFormValues>(emptyOrderForm)
  const [errors, setErrors] = useState<OrderFormErrors>({})
  const fieldRefs = useRef<Partial<Record<OrderFormField, HTMLInputElement | null>>>({})

  const fieldId = (field: OrderFormField) => `${id}-${field}`
  const errorId = (field: OrderFormField) => `${id}-${field}-error`

  function handleChange(event: ChangeEvent<HTMLInputElement>) {
    const field = event.target.name as OrderFormField
    const next = { ...values, [field]: event.target.value }
    setValues(next)
    // Clear (or update) an existing error as soon as the user corrects the field.
    if (errors[field]) setErrors({ ...errors, [field]: validateOrderField(field, next) })
  }

  function handleBlur(event: FocusEvent<HTMLInputElement>) {
    const field = event.target.name as OrderFormField
    if (!values[field]) return
    setErrors({ ...errors, [field]: validateOrderField(field, values) })
  }

  function handleSubmit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault()
    const nextErrors = validateOrderForm(values)
    setErrors(nextErrors)
    const firstInvalid = (['customerName', 'totalAmount'] as const).find((f) => nextErrors[f])
    if (firstInvalid) {
      fieldRefs.current[firstInvalid]?.focus()
      return
    }
    onSubmit(values)
  }

  return (
    <form
      noValidate
      onSubmit={handleSubmit}
      className="flex max-w-md flex-col gap-5"
      aria-busy={isSubmitting}
    >
      {submitError && (
        <div
          role="alert"
          className="border-destructive/40 bg-destructive/5 rounded-md border p-3 text-sm"
        >
          {submitError}
        </div>
      )}

      <div className="flex flex-col gap-2">
        <Label htmlFor={fieldId('customerName')}>Customer name</Label>
        <Input
          ref={(el) => {
            fieldRefs.current.customerName = el
          }}
          id={fieldId('customerName')}
          name="customerName"
          autoComplete="name"
          required
          maxLength={CUSTOMER_NAME_MAX_LENGTH}
          value={values.customerName}
          onChange={handleChange}
          onBlur={handleBlur}
          aria-invalid={errors.customerName ? true : undefined}
          aria-describedby={errors.customerName ? errorId('customerName') : undefined}
        />
        {errors.customerName && (
          <p id={errorId('customerName')} className="text-destructive text-sm">
            {errors.customerName}
          </p>
        )}
      </div>

      <div className="flex flex-col gap-2">
        <Label htmlFor={fieldId('totalAmount')}>Total amount</Label>
        <Input
          ref={(el) => {
            fieldRefs.current.totalAmount = el
          }}
          id={fieldId('totalAmount')}
          name="totalAmount"
          inputMode="decimal"
          required
          value={values.totalAmount}
          onChange={handleChange}
          onBlur={handleBlur}
          aria-invalid={errors.totalAmount ? true : undefined}
          aria-describedby={`${id}-totalAmount-hint${errors.totalAmount ? ` ${errorId('totalAmount')}` : ''}`}
        />
        <p id={`${id}-totalAmount-hint`} className="text-muted-foreground text-sm">
          Up to two decimal places, for example 49.90.
        </p>
        {errors.totalAmount && (
          <p id={errorId('totalAmount')} className="text-destructive text-sm">
            {errors.totalAmount}
          </p>
        )}
      </div>

      <div className="flex gap-2">
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Creating…' : 'Create order'}
        </Button>
        {onCancel && (
          <Button type="button" variant="outline" onClick={onCancel} disabled={isSubmitting}>
            Cancel
          </Button>
        )}
      </div>
    </form>
  )
}
