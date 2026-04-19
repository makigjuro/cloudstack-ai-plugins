---
name: generate-tests
description: Generate unit and integration tests for commands, queries, entities, and event handlers. Use when the user wants to add tests, increase coverage, write specs, or test a handler they just created.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__context7__resolve-library-id, mcp__context7__query-docs
user-invocable: true
argument-hint: "{Handler|Entity} [Service]"
---

# Generate Tests

Generate unit and integration tests following project conventions. Analyzes the target code, identifies test scenarios, and scaffolds test classes with proper mocking and assertions.

## Arguments

- `{target}` -- Handler, entity, or class name to test (e.g., `CreateOrderHandler`, `Order`, `OrderEndpoints`)
- `{service}` -- Target microservice (optional, auto-detected from file location)
- `--integration` -- Also generate integration tests with Testcontainers
- `--coverage` -- Generate tests for all untested handlers in a service

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `NAMESPACE` = `project.namespace` (default: detect from `*.sln`)
- `SERVICES` = `backend.services[]` (default: discover from project structure)
- `SOLUTION` = `backend.solutionPath` (default: find `*.sln`)
- `MESSAGING` = `backend.messaging` (default: `wolverinefx`)
- `RESULT_PATTERN` = `backend.resultPattern` (default: `true`)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Process

### Step 1: Locate the target

```bash
# Find the file containing the target class
grep -rl "class {target}" src/ --include="*.cs" | head -5
```

Read the target file completely. Identify:
- Is it a **command handler**? (method returns `Result<T>`, takes a command record)
- Is it a **query handler**? (method returns `Result<T>`, takes a query record)
- Is it an **entity**? (inherits from `Entity<TId>` or `AggregateRoot<TId>`)
- Is it an **event handler**? (handles domain/integration events)
- Is it an **endpoint**? (static class with `MapEndpoints`)

### Step 2: Analyze dependencies

Read the constructor to find injected dependencies:
```bash
grep -A 20 "class {target}" <file> | grep -E "private readonly|ILogger|I[A-Z]"
```

For each dependency, determine:
- Repository interfaces → mock with NSubstitute
- External services → mock with NSubstitute
- ILogger → mock or use NullLogger
- DbContext → use in-memory for unit, Testcontainers for integration

### Step 3: Identify test scenarios

**For command handlers:**
- Happy path (valid input → success result)
- Validation failure (invalid input → validation error)
- Not found (referenced entity doesn't exist → failure result)
- Duplicate (entity already exists → conflict error)
- Domain rule violation (business rule broken → failure result)

**For query handlers:**
- Happy path (entity exists → returns DTO)
- Not found (entity doesn't exist → failure result)
- Pagination (list query → correct page/size)
- Filtering (filtered query → correct subset)

**For entities:**
- Factory method creates valid entity
- Required fields enforced
- Domain events raised on state changes
- Value object equality

**For event handlers:**
- Handler processes event successfully
- Handler is idempotent (processing same event twice)

### Step 4: Determine test project location

```bash
# Find existing test projects for this service
find tests/ -name "*.csproj" | grep -i "{service}"
```

If no test project exists, note it and suggest creating one.

### Step 5: Generate unit tests

Create test file at `tests/{Service}.UnitTests/` or alongside existing tests:

```csharp
namespace {Namespace}.{Service}.UnitTests;

public class {Target}Tests
{
    private readonly I{Repository} _repository;
    private readonly {Target} _sut;

    public {Target}Tests()
    {
        _repository = Substitute.For<I{Repository}>();
        _sut = new {Target}(_repository);
    }

    [Fact]
    public async Task Handle_ValidCommand_ReturnsSuccess()
    {
        // Arrange
        var command = new {Command} { /* valid data */ };
        _repository.GetById(Arg.Any<{Id}>())
            .Returns(/* expected entity */);

        // Act
        var result = await _sut.Handle(command);

        // Assert
        result.IsSuccess.Should().BeTrue();
        await _repository.Received(1).Add(Arg.Any<{Entity}>());
    }

    [Fact]
    public async Task Handle_NotFound_ReturnsFailure()
    {
        // Arrange
        var command = new {Command} { /* data referencing nonexistent entity */ };
        _repository.GetById(Arg.Any<{Id}>())
            .Returns(({Entity}?)null);

        // Act
        var result = await _sut.Handle(command);

        // Assert
        result.IsSuccess.Should().BeFalse();
        result.Error.Code.Should().Be("{ENTITY}_NOT_FOUND");
    }
}
```

Adapt the template based on what the handler actually does — read the real code, don't guess.

### Step 6: Generate integration tests (if --integration)

If using unfamiliar Testcontainers or WireMock patterns, use context7 to look up the current API.

```csharp
namespace {Namespace}.{Service}.IntegrationTests;

public class {Target}IntegrationTests : IClassFixture<IntegrationTestFactory>
{
    private readonly IntegrationTestFactory _factory;

    public {Target}IntegrationTests(IntegrationTestFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task {Endpoint}_ReturnsExpectedResult()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.PostAsJsonAsync("/api/{resource}", new { /* data */ });

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }
}
```

### Step 7: Coverage mode (if --coverage)

If `--coverage` was passed:

```bash
# Find all handlers in the service
grep -rl "class.*Handler" src/{Service}/ --include="*.cs" | sort

# Find existing tests
grep -rl "class.*Tests" tests/ --include="*.cs" | sort

# Diff to find untested handlers
```

Generate tests for each untested handler, one file per handler.

## Output

```markdown
## Generated Tests: {target}

Files created:
- `tests/{Service}.UnitTests/{Target}Tests.cs` ({N} test methods)
- `tests/{Service}.IntegrationTests/{Target}IntegrationTests.cs` ({M} test methods) [if --integration]

Test scenarios covered:
- {list of scenarios}

Run: `dotnet test tests/{Service}.UnitTests --filter {Target}Tests`
```

## Error Handling

- **Target not found:** Search for partial matches and suggest alternatives
- **No test project:** Suggest creating one with `dotnet new xunit`
- **Complex dependencies:** If handler has 5+ dependencies, note which are mocked and suggest reviewing whether the handler has too many responsibilities

## Checklist

- [ ] Uses xUnit `[Fact]` and `[Theory]` attributes
- [ ] Uses NSubstitute for mocking (`Substitute.For<T>()`)
- [ ] Uses FluentAssertions (`.Should().`)
- [ ] Follows Arrange-Act-Assert pattern
- [ ] Test class name matches `{Target}Tests`
- [ ] Integration tests have `[Trait("Category", "Integration")]`
- [ ] No hardcoded GUIDs — use `Guid.NewGuid()` or typed ID `.New()`

## Related Skills

- `/dotnet-architect:add-command` -- Scaffold the handler first, then generate tests
- `/dotnet-architect:add-query` -- Same pattern for query handlers
- `/dev-workflow:run-tests` -- Run the generated tests
