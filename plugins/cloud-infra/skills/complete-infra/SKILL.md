---
name: complete-infra
description: Complete infrastructure task — lint, validate, review, and submit PR. Use when an infrastructure-only branch is ready for submission — runs Terraform/Helm validation and creates the PR, skipping application/frontend checks.
allowed-tools: Bash, Read, Glob, Grep, Task, Skill
user-invocable: true
---

# Complete Infrastructure Task

Finalize an infrastructure branch by running infra-specific quality gates and creating a PR. This is the infra equivalent of a full completion workflow — it skips application build/tests and frontend lint.

## Prerequisites

- You must be on a feature branch (not main)
- All infrastructure changes should be committed
- Working tree should be clean

## Arguments

- `{issue}` — GitHub issue number (optional). If not provided, extract from branch name.

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `TG_PATH` = `infrastructure.terragruntPath` (default: `infra/terragrunt`)
- `IAC_WRAPPER` = `infrastructure.iacWrapper` (default: `none`)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure. Derive `TF_PARENT` as the parent directory of `TF_PATH`.

## Scripts

Reusable bash scripts live in `scripts/` relative to this skill directory:

| Script | Purpose |
|--------|---------|
| `scripts/validate-terraform.sh` | Validate changed Terraform modules |
| `scripts/lint-helm.sh` | Lint changed Helm charts |

These scripts read `TF_PATH` and `CHARTS_PATH` from environment variables. Export them before calling:
```bash
export TF_PATH="..." CHARTS_PATH="..."
```

## Process

### Phase 0: Pre-flight

Run pre-flight checks inline (or source the shared preflight script if available):

```bash
BRANCH=$(git branch --show-current)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "ERROR: Cannot complete task on main branch"
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working tree is dirty. Commit or stash changes first."
  exit 1
fi
ISSUE=$(echo "$BRANCH" | grep -oE '/[0-9]+' | tr -d '/' || true)
echo "Branch: $BRANCH"
echo "Issue:  ${ISSUE:-<none>}"
```

### Phase 1: Parallel Infrastructure Lint

Launch all lint tracks in parallel using separate Bash tool calls in a single response.

**Track A: Terraform format check**
```bash
terraform fmt -check -recursive {TF_PARENT}
```

**Track B: Terraform validate (changed modules only)**
```bash
export TF_PATH="{TF_PATH}"
bash {plugin-skills-path}/complete-infra/scripts/validate-terraform.sh
```

**Track C: Helm lint (if charts changed)**
```bash
export CHARTS_PATH="{CHARTS_PATH}"
bash {plugin-skills-path}/complete-infra/scripts/lint-helm.sh
```

If any lint track fails, STOP and report.

### Phase 2: Infrastructure Review (Parallel Agents)

Launch the review agent with worktree isolation:

**Agent: `infra-reviewer`** (isolation: worktree) — Dedicated Terraform/Helm/CI review using the `infra-reviewer` agent definition. Reviews `git diff origin/main...HEAD -- {TF_PARENT}/ {CHARTS_PATH}/ .github/workflows/` and returns PASS/FAIL with findings covering security, naming, resource limits, and CI best practices.

### Phase 3: Evaluate

**If review passes:** Proceed to Phase 4.

**If issues found:**
1. Display findings
2. Fix issues (max 3 iterations)
3. Re-run from Phase 1

### Phase 4: Create PR

Run `/create-pr {issue}`.

## Output

```
## Infrastructure Task Completed

- Branch: {branch}
- Issue: #{issue}
- PR: {pr-url}

### Quality Gates
- Terraform Format: PASS
- Terraform Validate: PASS
- Helm Lint: PASS / SKIP (no chart changes)
- Infra Review: PASS

PR is ready for human review.
```
