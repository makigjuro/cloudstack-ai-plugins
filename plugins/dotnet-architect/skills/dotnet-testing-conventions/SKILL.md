---
name: dotnet-testing-conventions
description: Testing conventions for .NET — xUnit facts/theories, NSubstitute mocks, integration tests, test organization, and naming. Apply whenever writing or editing tests under tests/.
user-invocable: false
paths:
  - "tests/**/*.cs"
---

# Testing Rules

## Unit Tests
- xUnit v3 (`xunit.v3` package, test csproj has `<OutputType>Exe</OutputType>`) with `[Fact]` for single cases, `[Theory]` with `[InlineData]` for parameterized
- Pass `TestContext.Current.CancellationToken` to async calls that take an optional token (xUnit1051 is an error under `TreatWarningsAsErrors`)
- NSubstitute for mocking: `var repo = Substitute.For<IOrderRepository>();`
- FluentAssertions pinned to 7.x (e.g. 7.2.2) -- 8.x requires a commercial license; do not upgrade it
- `result.Should().BeSuccess()` / `.BeFailure()` are project-local extensions (`ResultAssertions.cs` in the unit test project) -- create them if missing; `result.Value.Should().NotBeNull()`
- Arrange-Act-Assert pattern with clear sections
- Verify calls: `repo.Received(1).AddAsync(Arg.Any<Order>(), Arg.Any<CancellationToken>())`

## Integration Tests
- Custom `WebApplicationFactory<Program>` subclass per service
- Implements `IAsyncLifetime` for setup/teardown (xUnit v3: `ValueTask InitializeAsync()` / `DisposeAsync()`)
- Testcontainers for PostgreSQL (or TimescaleDB if used)
- `CreateAuthenticatedClient()` returns `HttpClient` with default auth headers
- Database reset between tests: `EnsureDeletedAsync()` then `EnsureCreatedAsync()`
- `EnsureCreated` bypasses migrations, so keep one migration test that runs the `--migrate` code path (e.g. `DatabaseMigrator.MigrateAsync`) on an empty database and asserts no pending migrations / `HasPendingModelChanges() == false`
- Use `PostAsJsonAsync()`, `GetAsync()`, `DeleteAsync()` on HttpClient
- Assert on HTTP status codes and deserialized response bodies

## Test Organization
- Unit tests: `tests/{Namespace}.Domain.Tests/`
- Integration tests: `tests/{Namespace}.{Service}.Tests.Integration/` (e.g. `Starter.Orders.Tests.Integration`)
- Integration tests filtered by `Category=Integration`

## Naming
- Test classes: `{ClassUnderTest}Tests`
- Test methods: `{Method}_{Scenario}_{ExpectedResult}` or descriptive sentence
- Example: `Handle_WhenOrderExists_ReturnsConflict`
