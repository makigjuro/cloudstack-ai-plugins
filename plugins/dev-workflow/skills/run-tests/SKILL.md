---
name: run-tests
description: Run .NET tests with smart change detection -- auto-detects changed files via git diff and runs only affected test projects. Use whenever the user wants to run tests, verify changes, check if tests pass, run unit tests, integration tests, or test a specific service.
allowed-tools: Bash
user-invocable: true
argument-hint: "[service] [--integration]"
---

# Run Tests -- Smart Change-Aware Test Selection

Run tests based on what changed. Auto-detects affected services from git diff and runs only their test projects instead of the full suite.

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract relevant fields:
- `SOLUTION` = `backend.solutionPath` (default: find `*.sln`)
- `SERVICES` = `backend.services[]` (default: discover from project structure)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## 1. Parse Arguments

Determine from user input:
- **MODE**: `unit` (default), `integration`, or `all`
- **SERVICE**: optional service name or slug
- **Explicit `--all` flag**: runs both unit and integration for all projects

| User says | MODE | SERVICE |
|-----------|------|---------|
| `/run-tests` | unit | (auto-detect) |
| `/run-tests {service}` | unit | {service} |
| `/run-tests --integration` | integration | (auto-detect) |
| `/run-tests --integration {service}` | integration | {service} |
| `/run-tests --all` | all | (auto-detect) |
| `/run-tests --all {service}` | all | {service} |

## 2. Resolve Test Projects

### Auto-detection approach

Use git diff to identify changed files and map them to test projects:

```bash
# Get changed files relative to main
CHANGED_FILES=$(git diff origin/main...HEAD --name-only 2>/dev/null; git diff --name-only 2>/dev/null; git diff --name-only --cached 2>/dev/null)
```

Map changed source paths to their corresponding test projects:
1. For each changed file under a service's source path, find matching test projects by convention (e.g., `{ServicePath}.Tests.Unit`, `{ServicePath}.Tests.Integration`, `{ProjectPrefix}.Tests.*`).
2. If shared/foundational code changed (shared domain, shared infrastructure), fall back to running the full test suite.
3. If only non-source files changed (docs, config, CI), report "No tests affected" and offer to run the full suite.

### Explicit service mode

When a service name is provided, look up its path from `cloudstack.json` and find test projects matching that service's project prefix.

### Fallback

If change detection cannot determine targeted projects, fall back to running the full suite:
```bash
dotnet test {SOLUTION}
```

## 3. Pre-flight: Docker Check (Integration Tests Only)

If MODE is `integration` or `all`:

```bash
docker info > /dev/null 2>&1 || echo "ERROR: Docker is not running. Integration tests require Docker for Testcontainers."
```

If Docker is not running, warn the user and stop. Do not attempt integration tests without Docker.

## 4. Build

Build once before running tests:

```bash
dotnet build {SOLUTION} --no-restore -q
```

If build fails, report the errors and stop.

## 5. Run Tests

**Targeted projects** (when specific projects identified):
```bash
# Run each project individually
for PROJECT in $PROJECTS; do
  dotnet test "$PROJECT" --no-restore --no-build
done
```

**Full suite** (fallback or explicit --all):
```bash
dotnet test {SOLUTION} --no-restore --no-build
```

For debugging failures, add verbosity:
```bash
dotnet test "$PROJECT" --no-restore --no-build --verbosity normal --logger "console;verbosity=detailed"
```

## 6. Report

Use this output format:

```
## Test Results
- Mode: {Unit | Integration | All}
- Scope: {ServiceA, ServiceB (N of M test projects) | Full suite}
- Reason: {auto-detected from git changes | explicit service | shared dependency changed | full suite requested}
- Passed: {count}
- Failed: {count}
- Skipped: {count}
- Duration: {time}

### Failures (if any)
| Test | Expected | Actual | Location |
|------|----------|--------|----------|
| {test name} | {expected} | {actual} | {file:line} |

### Summary: {PASS | FAIL}
```

For failures, suggest fixes if they relate to recent changes.

## Error Handling

- **Docker not running (integration tests):** Warn and suggest starting Docker. Do not attempt integration tests without Docker.
- **Build errors:** Report compilation issues before testing.
- **No integration tests for service:** Report "No integration tests found for {service}" -- this is normal for some services.
- **Test project not found:** Fall back to running the full suite.

## Related Skills

- Use `/check-architecture` to verify architecture rules before running tests
- Use `/lint` to check formatting before creating a PR
