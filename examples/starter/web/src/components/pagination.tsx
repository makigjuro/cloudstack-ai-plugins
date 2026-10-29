import { ChevronLeft, ChevronRight } from 'lucide-react'
import { Button } from '@/components/ui/button'

interface PaginationProps {
  page: number
  pageSize: number
  totalCount: number
  onPageChange: (page: number) => void
  disabled?: boolean
}

export function Pagination({
  page,
  pageSize,
  totalCount,
  onPageChange,
  disabled,
}: PaginationProps) {
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize))
  const first = totalCount === 0 ? 0 : (page - 1) * pageSize + 1
  const last = Math.min(page * pageSize, totalCount)

  return (
    <nav aria-label="Pagination" className="flex items-center justify-between gap-4">
      <p className="text-muted-foreground text-sm" aria-live="polite">
        {first}–{last} of {totalCount} · Page {page} of {totalPages}
      </p>
      <div className="flex gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={() => {
            onPageChange(page - 1)
          }}
          disabled={disabled || page <= 1}
        >
          <ChevronLeft aria-hidden="true" />
          Previous
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => {
            onPageChange(page + 1)
          }}
          disabled={disabled || page >= totalPages}
        >
          Next
          <ChevronRight aria-hidden="true" />
        </Button>
      </div>
    </nav>
  )
}
