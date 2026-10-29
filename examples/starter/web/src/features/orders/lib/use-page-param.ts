import { useSearchParams } from 'react-router'

/** Reads/writes a positive integer `?page=` search param (defaults to 1). */
export function usePageParam(): [number, (page: number) => void] {
  const [searchParams, setSearchParams] = useSearchParams()
  const raw = Number(searchParams.get('page'))
  const page = Number.isInteger(raw) && raw > 0 ? raw : 1

  const setPage = (next: number) => {
    setSearchParams((prev) => {
      const params = new URLSearchParams(prev)
      if (next <= 1) params.delete('page')
      else params.set('page', String(next))
      return params
    })
  }

  return [page, setPage]
}
