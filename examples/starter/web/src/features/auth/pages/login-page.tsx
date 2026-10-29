import { useId, useState, type SubmitEvent } from 'react'
import { useNavigate, useSearchParams } from 'react-router'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAuthStore } from '@/stores/auth-store'
import { safeRedirect } from '../lib/safe-redirect'

/**
 * Placeholder sign-in. Replace with your OIDC / MSAL redirect flow for production.
 * In development only, a token can be pasted; it is kept in memory and never persisted.
 */
export function LoginPage() {
  const id = useId()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const setAccessToken = useAuthStore((s) => s.setAccessToken)
  const [token, setToken] = useState('')
  const redirectTo = safeRedirect(searchParams.get('redirect'))

  function handleSubmit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!token.trim()) return
    setAccessToken(token.trim())
    void navigate(redirectTo, { replace: true })
  }

  return (
    <div className="container mx-auto flex justify-center py-12">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>
            <h1 className="text-xl">Sign in</h1>
          </CardTitle>
          <CardDescription>
            Your session has ended or this action requires authentication.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {import.meta.env.DEV ? (
            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
              <div className="flex flex-col gap-2">
                <Label htmlFor={id}>Development access token</Label>
                <Input
                  id={id}
                  type="password"
                  autoComplete="off"
                  value={token}
                  onChange={(e) => {
                    setToken(e.target.value)
                  }}
                  aria-describedby={`${id}-hint`}
                />
                <p id={`${id}-hint`} className="text-muted-foreground text-sm">
                  Development only. Held in memory and cleared on reload or 401.
                </p>
              </div>
              <Button type="submit" disabled={!token.trim()}>
                Continue
              </Button>
            </form>
          ) : (
            <p className="text-sm">Sign-in is not configured for this deployment.</p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
