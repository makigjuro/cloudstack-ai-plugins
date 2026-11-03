import { CircleAlert } from 'lucide-react'
import type { ReactNode } from 'react'
import { Button } from '@/components/ui/button'

interface ErrorStateProps {
  title?: string
  message: string
  onRetry?: () => void
  children?: ReactNode
}

export function ErrorState({
  title = 'Something went wrong',
  message,
  onRetry,
  children,
}: ErrorStateProps) {
  return (
    <div
      role="alert"
      className="border-destructive/40 bg-destructive/5 flex flex-col items-start gap-3 rounded-lg border p-4"
    >
      <div className="flex items-center gap-2 font-medium">
        <CircleAlert className="text-destructive size-4" aria-hidden="true" />
        <span>{title}</span>
      </div>
      <p className="text-muted-foreground text-sm">{message}</p>
      <div className="flex gap-2">
        {onRetry && (
          <Button variant="outline" size="sm" onClick={onRetry}>
            Try again
          </Button>
        )}
        {children}
      </div>
    </div>
  )
}
