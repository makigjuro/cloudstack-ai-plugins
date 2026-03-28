---
paths:
  - "src/**/*.cs"
---

# Backend Security Rules

Apply these rules while writing code, not just during review.

## Injection Prevention

- **SQL:** Never concatenate user input into queries. Use parameterized queries only.
  - Forbidden: `FromSqlRaw($"SELECT ... WHERE id = '{id}'")`, string interpolation in SQL
  - Required: `FromSqlInterpolated`, `FromSqlRaw` with parameters, or LINQ/EF Core queries
- **Command:** Never pass unsanitized input to `Process.Start`, `ProcessStartInfo`, or shell commands
- **Message subjects:** Never interpolate user input into message broker subject strings without validation

## Secrets & Credentials

- Never hardcode secrets, API keys, connection strings, or tokens in source code
- Use configuration (`IConfiguration`, `IOptions<T>`) or environment variables
- Never log secrets, tokens, passwords, or PII -- use structured logging with explicit fields
- Connection strings go in `appsettings.json` (dev) or Kubernetes Secrets (deployed)
- Check: no `password=`, `apikey=`, `secret=`, `bearer` literals in committed code
- API keys and tokens must be hashed before storage -- never store plaintext

## Endpoint Authentication

Every new endpoint MUST have authentication. Rules:
- Every new endpoint requires auth unless it is a health check, metrics, or explicitly public endpoint
- If an endpoint must be public, annotate with `.AllowAnonymous()` and add a code comment explaining why
- Service-to-service endpoints that use `.AllowAnonymous()` must validate the caller via other means (internal network, service token)
- Never add a new service without authentication middleware
- Path exclusions in middleware (health, metrics) must use exact prefix matching, not contains

**When adding a new microservice:**
1. Add JWT Bearer authentication (`AddAuthentication` + `AddJwtBearer`) in `Program.cs`
2. Add the appropriate API key middleware if applicable
3. Call `UseAuthentication()` and `UseAuthorization()` in the pipeline
4. Add `.RequireAuthorization()` to endpoint groups or individual endpoints

## JWT / OIDC Configuration

- Always validate: issuer, audience, lifetime, and signing key (`ValidateIssuer`, `ValidateAudience`, `ValidateLifetime`, `ValidateIssuerSigningKey`)
- `ClockSkew` maximum: 5 minutes
- `RequireHttpsMetadata` must be `true` in production -- only `false` for local dev
- Never set `ValidateAudience = false` in new services

## API Key Security

- API keys must be hashed (e.g., BCrypt) before storage -- never store plaintext
- Use a prefix for DB lookup, then verify the full key with constant-time comparison or hash verify
- Never compare API keys with `==` -- use constant-time comparison or hash verify

## Input Validation

- Validate all external input at the API boundary (endpoint or command level)
- Use FluentValidation for command/request validation
- Enforce maximum lengths on all string inputs to prevent resource exhaustion
- Validate GUIDs, enums, and numeric ranges before passing to domain logic

## Error Responses

- Never expose stack traces, internal paths, or implementation details in API error responses
- Use the Result pattern error shape: `{ error: "CODE", message: "user-safe message", type: "ErrorType" }`
- Log the full exception server-side, return only the error code to the client

## Dependencies

- Never add packages without checking for known vulnerabilities
- Pin package versions via `Directory.Packages.props` (backend) and `package-lock.json` (frontend)
- Prefer well-maintained packages with active security response
