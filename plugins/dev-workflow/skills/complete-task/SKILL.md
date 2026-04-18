---
name: complete-task
description: Complete current task with all quality gates, code review, QA check, and submit PR. Use when implementation is done and you want to run the full verification pipeline (build, lint, tests, review, QA) and create the pull request.
allowed-tools: Bash, Read, Glob, Grep, Task, Skill
user-invocable: true
argument-hint: "[issue-number] [--skip-integration] [--auto-fix]"
---

# Complete Task

Finalize the current feature branch by running all quality gates and creating a PR. This skill orchestrates multiple verification steps with parallel execution where possible, and dynamically composes review agents based on what changed.

## Prerequisites

- You must be on a feature branch (not main)
- All implementation work should be complete
- Working tree should be clean (all changes committed)

## Arguments

- `{issue}` -- GitHub issue number (optional). If not provided, extract from branch name.
- `--skip-integration` -- Skip integration tests (faster, for WIP checks)
- `--auto-fix` -- Automatically fix lint issues before proceeding

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `SOLUTION` = `backend.solutionPath` (default: find `*.sln` in `src/`)
- `FRONTEND_PATH` = `frontend.path` (default: `web`)
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)
- `TERRAFORM_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `SERVICES` = `backend.services[]` (default: discover from `src/*/` directories containing `.Application/` subfolders)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Scripts

| Tool | Type | Purpose |
|------|------|---------|
| `preflight.sh` | Bash (`${CLAUDE_PLUGIN_ROOT}/scripts/`) | Branch check, clean tree, issue extraction |

## State Machine

```
[start] -> pre-flight + detect-changes
    |
  parallel-build (backend || frontend)
    |
  pending-migrations (if HAS_BACKEND)
    |
  parallel-lint+tests (backend || frontend || infra)
    |
  integration-tests -> browser-verify
    |
  parallel-agents (reviewer || verifier || doc-checker? || infra-reviewer?)
    |
  [issues?] -> scoped-fix -> [restart affected tracks]
    |
  create-pr -> [done]
```

CRITICAL: Do not skip states. Do not proceed if a gate fails. Maximum 3 fix iterations before stopping.

## Process

### Phase 0: Pre-flight + Change Detection

Run the shared pre-flight script:

```bash
source ${CLAUDE_PLUGIN_ROOT}/scripts/preflight.sh
```

If pre-flight fails, STOP and report the issue.

**Change Detection -- run immediately after pre-flight:**

Detect what changed using git diff against the base branch. The change detection flags should use paths from cloudstack.json when available.

```bash
CHANGED=$(git diff origin/main...HEAD --name-only)

# Use paths from cloudstack.json -- these are the defaults
SRC_PATH="src/"           # directory containing backend code
FRONTEND_PATH="web/"      # from frontend.path
INFRA_PATH="infra/"       # from infrastructure.terraformPath parent
CHARTS_PATH="deploy/"     # from infrastructure.chartsPath parent

HAS_BACKEND=$(echo "$CHANGED" | grep -q "^${SRC_PATH}" && echo true || echo false)
HAS_FRONTEND=$(echo "$CHANGED" | grep -q "^${FRONTEND_PATH}" && echo true || echo false)
HAS_INFRA=$(echo "$CHANGED" | grep -q "^${INFRA_PATH}\|^${CHARTS_PATH}\|^\.github/" && echo true || echo false)
HAS_ENDPOINTS=$(echo "$CHANGED" | grep -q "Endpoints/" && echo true || echo false)
HAS_ENTITIES=$(echo "$CHANGED" | grep -q "Domain/Entities/" && echo true || echo false)
HAS_EVENTS=$(echo "$CHANGED" | grep -q "Domain/Events/" && echo true || echo false)
```

Use these flags to gate all downstream phases. If a flag is `false`, skip its corresponding tracks.

### Phase 1: Parallel Build

Launch build commands in parallel using separate Bash tool calls in a single response. Only include tracks where changes were detected.

**Track A (if HAS_BACKEND):**
```bash
dotnet build ${SOLUTION} --configuration Release --no-restore
```

**Track B (if HAS_FRONTEND):**
```bash
cd ${FRONTEND_PATH} && npm run type-check
```

If either track fails, STOP and report the failure.

### Phase 1.5: Pending Migrations Check (if HAS_BACKEND)

Check each service for pending EF Core migrations by looping through the configured services:

```bash
# For each service in cloudstack.json backend.services[]:
cd ${SERVICE_PATH}/${SERVICE_NAME}.Infrastructure
dotnet ef migrations has-pending-model-changes --startup-project ../${SERVICE_NAME}.Host
```

If any service has pending migrations, STOP and create the migration using `/add-migration` for the affected service(s) before proceeding.

### Phase 2: Parallel Lint + Unit Tests

Launch all applicable tracks in parallel using separate Bash tool calls in a single response.

**Track A (if HAS_BACKEND): Backend lint + unit tests**

If `--auto-fix` was passed, run `dotnet format ${SOLUTION}` first, then:
```bash
dotnet format ${SOLUTION} --verify-no-changes && dotnet test ${SOLUTION} --no-build --configuration Release --filter "Category!=Integration"
```

**Track B (if HAS_FRONTEND): Frontend lint**

If `--auto-fix` was passed, run `cd ${FRONTEND_PATH} && npm run lint:fix` first, then:
```bash
cd ${FRONTEND_PATH} && npm run lint
```

**Track C (if HAS_INFRA): Infrastructure lint**

Lint all Helm charts found under the charts path, and check Terraform formatting:
```bash
# Find and lint each chart directory
for chart in ${CHARTS_PATH}/*/; do helm lint "$chart"; done
terraform fmt -check -recursive ${TERRAFORM_PATH}
```

If any track fails, STOP and report which track(s) failed.

### Phase 3: Integration Tests (if HAS_BACKEND)

Skip if `--skip-integration` was passed.

```bash
dotnet test ${SOLUTION} --no-build --configuration Release --filter "Category=Integration"
```

If tests fail, STOP and report failures.

### Phase 3.5: Browser Verification (if HAS_FRONTEND)

Check if the frontend is running:

```bash
FRONTEND_PORT=$(jq -r '.frontend.devPort // 5173' cloudstack.json 2>/dev/null || echo 5173)
curl -sf http://localhost:${FRONTEND_PORT} > /dev/null 2>&1 && echo "Frontend: UP" || echo "Frontend: DOWN"
```

- **Frontend running:** Invoke `/smoke-test --frontend-only` to verify routes render without errors. Report results as **advisory (WARNING, not FAIL)** -- browser verification issues don't block the PR.
- **Frontend not running:** Skip with advisory note: "Browser verification skipped -- frontend not running. Run `/run-local` and `/verify-feature` to test manually."

### Phase 4: Parallel Agent Review (Dynamic Composition)

Launch all applicable agents in parallel in a single response. Each agent uses `isolation: "worktree"` for safe parallel reads and `run_in_background: true` so you can begin drafting the PR summary while agents work.

**Always launch:**

1. **`reviewer`** (isolation: worktree, run_in_background: true) -- Code review for security, architecture, and quality issues. Uses the `reviewer` agent definition. The agent should review `git diff origin/main...HEAD` and return a structured report with Critical/Warning/Suggestion categories and a PASS/FAIL summary.

2. **`verifier`** (isolation: worktree, run_in_background: true) -- QA verification that implementation matches the GitHub issue acceptance criteria. Uses the `verifier` agent definition. The agent should fetch the issue via `gh issue view`, compare against the diff, and return MET/UNMET/PARTIAL status for each criterion with a PASS/FAIL summary.

**Conditionally launch:**

3. **`doc-checker`** (isolation: worktree, run_in_background: true) -- Only if `HAS_ENDPOINTS` OR `HAS_ENTITIES` OR `HAS_EVENTS` OR `HAS_INFRA`. Detects stale documentation relative to code changes.

4. **`infra-reviewer`** (isolation: worktree, run_in_background: true) -- Only if `HAS_INFRA`. Dedicated Terraform/Helm/CI review using the `infra-reviewer` agent definition.

While agents run in the background, begin preparing the PR description (title, summary of changes, test plan). You will be notified as each agent completes -- do not poll or sleep. Once all agents have reported back, proceed to Phase 5.

### Phase 5: Evaluate + Scoped Fix Loop

Collect results from all agents.

**If ALL pass:**
- Proceed to Phase 6

**If ANY issues found:**
1. Display the issues to the user, grouped by agent
2. Ask: "Fix these issues automatically? (max 3 iterations)"
3. If yes, fix the issues
4. Re-run only affected tracks -- determine which tracks to re-run based on which files the fix touched:
   - Fix touched `${SRC_PATH}` -> re-run backend build, backend lint+tests
   - Fix touched `${FRONTEND_PATH}` -> re-run frontend build, frontend lint
   - Fix touched `${INFRA_PATH}` or `${CHARTS_PATH}` -> re-run infra lint
   - Re-run only the agents that reported issues (not all agents)
   - When unsure which tracks a fix affects, re-run all tracks
5. If no or max iterations reached, STOP and report

Track iteration count. After 3 failed attempts, STOP with:
```
Maximum fix iterations reached. Manual intervention required.
Remaining issues:
{list issues}
```

### Phase 5.5: Documentation Check (Advisory)

Before creating the PR, if `HAS_ENDPOINTS` OR `HAS_ENTITIES` OR `HAS_EVENTS` OR `HAS_INFRA`, suggest running `/docs` for the affected areas:
- New/changed endpoints -> `/docs api {service}`
- New/changed entities or events -> `/docs domain`
- Infrastructure changes -> `/docs architecture`

This is advisory, not blocking -- note it in the PR output if docs may need updating. If the `doc-checker` agent already ran in Phase 4, use its findings here instead of re-checking.

### Phase 6: Create PR

Run the `/create-pr` skill with the extracted issue number.

```
/create-pr {issue}
```

## Output

On success:
```
## Task Completed Successfully

- Branch: {branch}
- Issue: #{issue}
- PR: {pr-url}

### Quality Gates
- Build: PASS (backend + frontend) / PASS (backend only) / PASS (frontend only)
- Lint: PASS (backend + frontend + infra) / PASS ({active tracks})
- Unit Tests: PASS ({count} tests) / SKIP (no backend changes)
- Integration Tests: PASS ({count} tests) / SKIP
- Browser Verification: PASS / SKIP (no frontend changes) / SKIP (frontend not running)
- Code Review: PASS
- Task Check: PASS ({x}/{y} criteria met)
- Doc Check: PASS (no stale docs) / SKIP (no endpoint/entity/event/infra changes)
- Infra Review: PASS / SKIP (no infra changes)

PR is ready for human review.
```

On failure:
```
## Task Completion Failed

Failed at: {phase name}
Reason: {error details}

{Specific failure output}
```

## When NOT to Use

- **Infrastructure-only changes** (only `infra/`, `deploy/`, `.github/workflows/`) -- use `/complete-infra` instead, which skips .NET build/tests and frontend lint
- **Work in progress** -- this skill expects all implementation to be complete and committed
- **Exploratory changes** -- if you're still figuring out the approach, run `/check-architecture` and `/run-tests` individually instead

## Guidelines

- This skill is idempotent -- safe to run multiple times
- All bash commands use explicit paths relative to repo root
- Subagents run with worktree isolation to avoid polluting main conversation and enable safe parallel reads
- Never force-push or amend commits during this process
- If unsure about a fix, ask the user rather than guessing
- Parallel tracks are launched as multiple tool calls in a single response for maximum throughput
