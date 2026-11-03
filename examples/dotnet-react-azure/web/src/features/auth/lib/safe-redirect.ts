/** Only allow same-origin relative paths, preventing open redirects via ?redirect=. */
export function safeRedirect(target: string | null, fallback = '/orders'): string {
  if (!target?.startsWith('/') || target.startsWith('//') || target.startsWith('/\\')) {
    return fallback
  }
  return target
}
