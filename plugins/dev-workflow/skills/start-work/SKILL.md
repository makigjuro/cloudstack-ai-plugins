---
name: start-work
description: Create a feature branch from a GitHub issue and set up the working context. Use whenever starting implementation on a new issue -- creates the branch, fetches requirements, and begins building automatically.
allowed-tools: Bash, Read, mcp__github-mcp-server__get_issue
user-invocable: true
argument-hint: "{issue-number}"
---

# Start Work

Create a feature branch from a GitHub issue and prepare the working context.

## Arguments

- `{issue}` -- GitHub issue number (required). Pass as argument: `/start-work 42`

## Process

1. **Fetch issue details** -- Read the issue title and body to understand the scope.
2. **Ensure clean working tree** -- Check `git status` for uncommitted changes. Warn the user if the tree is dirty.
3. **Pull latest main** -- Ensure the branch starts from the latest main.
4. **Create and checkout branch** -- Use the naming convention below.
5. **Report** -- Show the branch name and a summary of the issue tasks.

## Branch Naming Convention

```
{username}/{issue-number}-{short-slug}
```

Derive `{username}` from the git config `user.name` (lowercase, no spaces). Derive `{short-slug}` from the issue title (lowercase, hyphens, max 50 chars, no special characters).

Examples:
- `jdoe/42-user-group-assignments`
- `jdoe/15-order-versioning-api`

## Commands

Fetch the issue (gh infers owner/repo from the git remote):

```bash
gh issue view {issue} --json number,title,body,labels,state
```

If the GitHub MCP server is available in this session, you may use `mcp__github-mcp-server__get_issue` instead -- it returns typed JSON without output parsing.

```bash
# Check working tree
git status --short

# Update main and create branch
git fetch origin main
git checkout -b {branch-name} origin/main
```

## After Starting -- Automatic Implementation

Once the branch is created, continue into implementation:

1. **Analyze the issue** -- Parse acceptance criteria, identify affected services, and determine which layers need changes (Domain, Application, Infrastructure, Endpoints, Frontend, Tests).
2. **Create a task list** -- Use TodoWrite to track each implementation step derived from the issue.
3. **Implement** -- Follow the layer order: Domain -> Application -> Infrastructure -> Endpoints -> Frontend -> Tests. Use the appropriate scaffolding skills (`/dotnet-architect:add-entity`, `/dotnet-architect:add-command`, `/dotnet-architect:add-query`, `/dotnet-architect:add-event-handler`, `/dotnet-architect:add-migration`, `/react-developer:add-feature`) where they apply. Commit logically after each meaningful change.
4. **Verify as you go** -- Run tests and architecture checks between steps. Fix issues before moving on.
5. **When done** -- Run `/dev-workflow:complete-task` to go through the full completion workflow (build, lint, tests, review, PR).

Read the issue, plan the work, and start building; ask only when the issue is ambiguous in a way that blocks the work.

## Output

After branch creation, report:
```
## Ready to Work

- Branch: `{branch-name}`
- Issue: #{issue} -- {title}
- Labels: {labels}

### Acceptance Criteria
{parsed AC from issue}

### Implementation Plan
{task list derived from issue analysis}

Starting implementation...
```

## Error Handling

- **Dirty working tree:** List the uncommitted files and ask the user to commit or stash before proceeding.
- **Issue not found:** Verify the issue number and repo. Suggest checking with `gh issue view {number}`.
- **Branch already exists:** Ask the user if they want to check it out instead of creating a new one.
