---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "web/src/**/*.ts"
  - "web/src/**/*.tsx"
---

# Frontend Security Rules

Apply these rules while writing frontend code, not just during review.

## XSS Prevention

- Never use `dangerouslySetInnerHTML` without DOMPurify sanitization
- Sanitize any user-generated content before rendering: `DOMPurify.sanitize(userContent)`
- Avoid injecting raw HTML from API responses — parse and render structured data instead
- When rendering markdown, use a library that sanitizes by default (e.g., `react-markdown` with `rehype-sanitize`)

## Authentication & Token Handling

- Never hardcode API keys, tokens, secrets, or credentials in frontend source code
- Auth tokens should be managed by the auth library (OIDC client, MSAL, etc.) with automatic silent renewal
- API key mode is acceptable for local development only — production must use a proper auth flow (OIDC, OAuth2)
- On 401 response from the API: clear auth state and redirect to `/login?redirect={currentPath}`
- On 403 response: show an access denied message, do not retry or redirect to login

## localStorage / sessionStorage

- Only store auth tokens and user preferences in localStorage — never store sensitive PII, full user profiles, or secrets
- Use `sessionStorage` for data that should not persist across tabs (if applicable)
- When using Zustand `persist` middleware (or similar), use `partialize` to explicitly select which fields are stored
- Clear auth storage on logout — call `localStorage.removeItem()` for all auth-related keys

## No Hardcoded Secrets

- Never commit `.env` files with real API keys or secrets
- Use `.env.example` with placeholder values for documentation
- Environment variables exposed to the frontend (e.g., `VITE_API_URL`) must never contain secrets — they are visible in the browser bundle
- Validate: no string literals matching patterns like `sk_`, `pk_`, `api_key_`, `bearer`, `password=` in committed code

## CORS Configuration

- Only allow specific origins in production CORS configuration, never `Access-Control-Allow-Origin: *`
- CORS is a server-side concern, but frontend developers should be aware of it when configuring API clients
- If hitting CORS errors locally, fix the server CORS config rather than using a proxy that masks the issue in dev

## API Error Handling

- Never display raw API error messages or stack traces to users
- Map error codes to user-friendly messages
- Log detailed error information to the browser console (development) or error tracking service (production)
- Never include request headers (especially auth headers) in error logs or error boundaries

## Content Security

- Avoid `eval()`, `new Function()`, and other dynamic code execution
- When using iframes, apply `sandbox` attribute with minimal permissions
- Use `rel="noopener noreferrer"` on external links with `target="_blank"`

## Dependencies

- Review new frontend dependencies before adding — check for known vulnerabilities
- Keep `package-lock.json` (or equivalent) committed for reproducible builds
- Run `npm audit` periodically and address critical/high vulnerabilities
- Prefer well-maintained packages with active security response
