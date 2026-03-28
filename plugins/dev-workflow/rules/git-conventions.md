---
paths:
  - "**"
---

# Git Conventions

## Branch Naming

Format: `{username}/{issue-number}-{short-slug}`

Examples:
- `jdoe/166-aks-cluster-services`
- `asmith/247-real-time-sse-websocket`

Legacy branches used `feature/` prefix — new branches must use the `{username}/` format.

## Commit Messages

Format: lowercase imperative, no period at end

```
{verb} {what was done}
```

**Verbs:**
- `add` — new feature or file (not "added", not "adds")
- `fix` — bug fix
- `update` — enhancement to existing feature
- `remove` — delete code or feature
- `refactor` — restructure without behaviour change
- `rename` — rename files, variables, or types
- `move` — relocate files between directories
- `enforce` — add or tighten a rule/constraint
- `address` — respond to review feedback

**Examples:**
```
add user registration endpoint with validation
fix null reference in heartbeat processor
update device list to show online status badge
remove deprecated v1 API routes
refactor query handlers to use Result pattern
```

**Rules:**
- First line under 72 characters
- No capitalization of first word (lowercase)
- No trailing period
- One logical change per commit — not one giant commit per feature
- Reference issue number in the PR, not in every commit message

## Protected Branches

- Never commit directly to `main` — always use feature branches
- Never force-push to `main`
- Merge via pull request only

## Staging

- Stage specific files by name, not `git add -A` or `git add .`
- Never commit `.env`, `appsettings.*.json` with secrets, or `**/bin/` / `**/obj/` directories
- Review `git diff --cached` before committing

## PR Conventions

- PR title: imperative mood, under 70 characters (matches the primary commit)
- Link to GitHub issue with `Closes #{number}`
- One PR per issue — don't bundle unrelated changes
