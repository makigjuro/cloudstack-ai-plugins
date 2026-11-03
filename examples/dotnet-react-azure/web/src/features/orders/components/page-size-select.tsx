import { useId, type ChangeEvent } from 'react'
import { Label } from '@/components/ui/label'
import { PAGE_SIZE_OPTIONS, useUiPrefsStore, type PageSize } from '@/stores/ui-prefs-store'

interface PageSizeSelectProps {
  onChange?: (size: PageSize) => void
}

export function PageSizeSelect({ onChange }: PageSizeSelectProps) {
  const id = useId()
  const pageSize = useUiPrefsStore((s) => s.ordersPageSize)
  const setPageSize = useUiPrefsStore((s) => s.setOrdersPageSize)

  function handleChange(event: ChangeEvent<HTMLSelectElement>) {
    const size = PAGE_SIZE_OPTIONS.find((option) => option === Number(event.target.value))
    if (!size) return
    setPageSize(size)
    onChange?.(size)
  }

  return (
    <div className="flex items-center gap-2">
      <Label htmlFor={id}>Rows per page</Label>
      <select
        id={id}
        value={pageSize}
        onChange={handleChange}
        className="border-input bg-background focus-visible:ring-ring/50 h-8 rounded-md border px-2 text-sm outline-none focus-visible:ring-[3px]"
      >
        {PAGE_SIZE_OPTIONS.map((option) => (
          <option key={option} value={option}>
            {option}
          </option>
        ))}
      </select>
    </div>
  )
}
