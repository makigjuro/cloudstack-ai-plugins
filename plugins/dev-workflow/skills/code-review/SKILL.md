---
name: code-review
description: Review code changes for security, architecture, and quality issues. Use for deep PR-level review -- checks OWASP vulnerabilities, hexagonal architecture violations, code smells, and test gaps. For a quick architecture-only check, use /check-architecture instead.
allowed-tools: Bash, Read, Glob, Grep, Agent, Workflow
user-invocable: true
---

# Code Review

Perform a comprehensive code review of changes on the current branch compared to main. This skill runs standalone; `/complete-task` runs the equivalent `dotnet-architect:reviewer` agent instead.

## Arguments

- `--security-only` -- Focus only on security issues
- `--architecture-only` -- Focus only on architecture violations
- `--diff {base}` -- Compare against a specific base (default: origin/main)
- `{files}` -- Review only specific files (space-separated)

## Configuration

Read `cloudstack.json` from the project root if it exists. Extract:
- `SOLUTION` = `backend.solutionPath`
- `SERVICES` = `backend.services[]`
- `VALIDATOR_MCP` = `validators.mcpServer` (optional)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Process

### Step 1: Gather Changes

```bash
# Get list of changed files
git diff origin/main...HEAD --name-only

# Get full diff for analysis
git diff origin/main...HEAD

# Get commit messages for context
git log origin/main..HEAD --oneline
```

### Step 2: Security Review

Check for OWASP Top 10 vulnerabilities:

**Injection**
- SQL: Look for string concatenation in queries, raw SQL without parameters
- Command: Look for `Process.Start`, `Bash` with user input
- Search patterns: `FromSqlRaw`, `ExecuteSqlRaw`, string interpolation in queries

**Broken Authentication**
- Hardcoded credentials, API keys, connection strings
- Missing authorization attributes on endpoints
- Weak password validation

**Sensitive Data Exposure**
- Logging sensitive data (passwords, tokens, PII)
- Returning sensitive fields in API responses
- Missing encryption for sensitive storage

**Security Misconfiguration**
- Debug mode enabled in non-dev code
- Overly permissive CORS
- Missing security headers
- Default credentials

**XSS**
- React: `dangerouslySetInnerHTML` without sanitization
- Unescaped user input in responses

### Step 3: Architecture Review

If `VALIDATOR_MCP` is configured, prefer its structured tools over the bash checks below — they do real dependency analysis (including project references the greps miss) and return JSON in one call:
- `mcp__{VALIDATOR_MCP}__validate_all_layers` replaces the layer-dependency loop
- `mcp__{VALIDATOR_MCP}__check_result_pattern` (per changed handler file) replaces the thrown-exception grep

Fall back to the bash-based checks when no validator MCP is configured, then supplement with manual review.

**Hexagonal Architecture -- validate layer dependencies:**

For each service, check that layer boundaries are respected:
```bash
# Check that Domain layer does not reference Infrastructure or Host
for service_path in $(find src/ -name "*.Application" -type d -maxdepth 3); do
  SERVICE_DIR=$(dirname "$service_path")
  SERVICE_NAME=$(basename "$SERVICE_DIR")

  # Domain should not reference Infrastructure
  grep -r "Infrastructure" "${SERVICE_DIR}/${SERVICE_NAME}.Domain/" --include="*.cs" -l 2>/dev/null && \
    echo "VIOLATION: ${SERVICE_NAME}.Domain references Infrastructure"

  # Application should not reference Host
  grep -r "\.Host" "${SERVICE_DIR}/${SERVICE_NAME}.Application/" --include="*.cs" -l 2>/dev/null && \
    echo "VIOLATION: ${SERVICE_NAME}.Application references Host"
done
```

**Result Pattern -- check handlers return Result<T> instead of throwing:**

For each changed handler file, verify it uses the Result pattern:
```bash
# Find handler files in the diff
HANDLERS=$(git diff origin/main...HEAD --name-only | grep "Handler\.cs$")
for handler in $HANDLERS; do
  # Check for thrown exceptions that should be Result.Failure
  grep -n "throw new.*Exception" "$handler" 2>/dev/null && \
    echo "WARNING: $handler throws exceptions -- consider returning Result.Failure instead"
done
```

**CQRS Violations (manual check):**
- Commands in Query folders or vice versa
- Query handlers calling write repositories
- Command handlers returning data (queries in disguise)

**Domain Rules (manual check):**
- Entities with public setters (should be private/protected)
- Missing factory methods (public constructors on aggregates)
- Domain logic in Infrastructure layer
- Anemic entities (all logic in handlers)

### Step 4: Quality Review

**Code Smells**
- Methods longer than 30 lines
- Classes longer than 300 lines
- Deep nesting (> 3 levels)
- Magic numbers/strings without constants
- Duplicate code blocks (> 5 lines repeated)

**Error Handling**
- Empty catch blocks
- Catching generic `Exception` without re-throwing
- Missing null checks on external data
- Missing validation on API inputs

**Testing Gaps**
- New public methods without corresponding tests
- New handlers without test coverage
- Modified business logic without updated tests

**Naming & Conventions**
- Non-descriptive names (data, info, temp, x)
- Inconsistent naming with existing code
- Missing XML docs on public APIs

### Step 4.5: Adversarial Verification (when the Workflow tool is available)

Before reporting, if the harness exposes the `Workflow` tool and the review produced Critical or Warning findings, verify them adversarially: fan out one skeptic agent per finding, prompted to REFUTE it against the actual diff (schema `{ isReal: boolean, reason: string }`, default to refuted when uncertain). Drop findings that don't survive. This prevents plausible-but-wrong findings from blocking a PR. Skip this step for suggestion-level findings and when the Workflow tool is unavailable.

### Step 5: Generate Report

Output in this format:

```markdown
## Code Review: {branch-name}

**Reviewed:** {file count} files, {addition count} additions, {deletion count} deletions
**Commits:** {commit count}

---

### Critical Issues (Block PR)

These MUST be fixed before merging:

| # | File | Line | Issue | Rule |
|---|------|------|-------|------|
| 1 | {file} | {line} | {description} | {rule violated} |

**Details:**

#### Issue 1: {title}
- **File:** `{path}:{line}`
- **Code:**
  ```csharp
  {offending code snippet}
  ```
- **Problem:** {why this is an issue}
- **Fix:** {how to fix it}

---

### Warnings (Should Fix)

These should be addressed but don't block:

| # | File | Line | Issue | Rule |
|---|------|------|-------|------|
| 1 | {file} | {line} | {description} | {rule} |

---

### Suggestions (Nice to Have)

Improvements that would enhance code quality:

- {suggestion 1}
- {suggestion 2}

---

### Positive Observations

Things done well in this change:

- {positive 1}
- {positive 2}

---

### Summary

| Category | Status | Issues |
|----------|--------|--------|
| Security | {PASS/FAIL} | {count} |
| Architecture | {PASS/FAIL} | {count} |
| Quality | {PASS/WARN/FAIL} | {count} |
| Tests | {PASS/WARN} | {count} |

**Overall: {APPROVED / CHANGES REQUESTED / BLOCKED}**

{If APPROVED: "Ready to merge after addressing warnings (optional)"}
{If CHANGES REQUESTED: "Please address the issues above and re-request review"}
{If BLOCKED: "Critical issues must be resolved before this can proceed"}
```

## Severity Levels

- **Critical (Block):** Security vulnerabilities, data loss risks, architecture violations
- **Warning (Should Fix):** Code smells, missing tests, convention violations
- **Suggestion (Nice to Have):** Style improvements, refactoring opportunities

## Relationship to /check-architecture

`/code-review` and `/check-architecture` have complementary scopes:

| Aspect | `/check-architecture` | `/code-review` |
|--------|----------------------|----------------|
| Speed | Fast (local checks) | Thorough (full diff analysis) |
| Security | No | Yes (OWASP Top 10) |
| Architecture | Layer deps, Result pattern, CQRS, entities, migrations | Same + circular deps, anemic models |
| Quality | No | Yes (code smells, naming, testing gaps) |
| When | During development, quick verification | Before PR, standalone deep review |

Use `/check-architecture` for quick feedback while coding. Use `/code-review` for the final gate before a PR.

## Guidelines

- Don't nitpick -- save style debates for linters
