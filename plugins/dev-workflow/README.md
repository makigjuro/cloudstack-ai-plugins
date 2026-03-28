# dev-workflow

End-to-end development workflow plugin for Claude Code. Provides PRD generation, feature planning, GitHub issue creation, branch management, quality gates, parallel code review, and PR creation.

## What's Included

### Skills (13)

| Skill | Description |
|-------|-------------|
| `/prd` | Generate a Product Requirements Document through guided discovery |
| `/plan-feature` | Break a feature into structured implementation tasks |
| `/create-tasks` | Create GitHub issues (auto-detects single issue vs epic + tasks) |
| `/start-work` | Create a feature branch from a GitHub issue |
| `/complete-task` | Full completion workflow: build, lint, test, review, PR |
| `/create-pr` | Create a pull request with structured description |
| `/code-review` | Deep code review for security, architecture, and quality |
| `/task-check` | QA check: verify implementation matches issue acceptance criteria |
| `/run-tests` | Run tests with smart change detection |
| `/lint` | Run all linters and formatters |
| `/run-local` | Start the local development environment |
| `/docs` | Generate or update documentation from code |
| `/diagnose` | Investigate problems with structured evidence gathering |

### Agents (4)

| Agent | Model | Purpose |
|-------|-------|---------|
| `verifier` | Sonnet | QA gate — verifies implementation matches GitHub issue acceptance criteria |
| `investigator` | Sonnet | Evidence gatherer for diagnosing problems, collects facts without drawing conclusions |
| `analyzer` | Opus | Codebase analyzer — finds patterns, related code, and integration points before new features |
| `doc-checker` | Haiku | Fast advisory check — detects stale documentation relative to code changes |

### Rules (4)

| Rule | Scope | Description |
|------|-------|-------------|
| `git-conventions` | `**` | Branch naming, commit messages, staging, PR conventions |
| `workflow` | `**` | Master workflow doc — end-to-end development process with all skill references |
| `mcp-tools` | — | Guidance for optional MCP servers (context7, playwright, Mermaid Chart, GitHub) |
| `skill-writing` | — | Principles for writing effective Claude Code skills |

### Hooks (3)

| Hook | Trigger | Description |
|------|---------|-------------|
| `format-on-save.sh` | PostToolUse (Edit/Write) | Auto-formats files after editing (C#, TS/JS, Terraform, Python, Go) |
| `pre-commit-lint.sh` | PreToolUse (Bash) | Lints and auto-fixes staged files before git commit |
| `scan-secrets.sh` | PreToolUse (Bash) | Scans for leaked secrets before git commit/push |

### Scripts

| Script | Description |
|--------|-------------|
| `preflight.sh` | Shared pre-flight check for branch validation and issue extraction |

## Configuration

The hooks and scripts auto-detect project paths. For explicit configuration, create a `cloudstack.json` in your project root:

```json
{
  "backend": {
    "solutionPath": "src/MyProject.sln"
  },
  "frontend": {
    "path": "web"
  }
}
```

Without this file, the plugin will:
- Search for `*.sln` files under `src/` or the project root
- Look for `package.json` in `web/`, `frontend/`, `client/`, or `app/` directories

## Supported Languages

The format-on-save and pre-commit hooks support:
- **C#** via `dotnet format`
- **TypeScript/JavaScript** via ESLint
- **Terraform** via `terraform fmt`
- **Python** via ruff or black
- **Go** via gofmt
- **Helm** via `helm lint`

## Optional MCP Servers

The plugin works best with these MCP servers, but none are required:

- **context7** — Library documentation lookup (avoids outdated patterns)
- **playwright** — Browser automation for frontend verification
- **Mermaid Chart** — Diagram validation for documentation
- **github-mcp-server** — Structured GitHub API access (falls back to `gh` CLI)

## Installation

Add to your Claude Code project as a plugin:

```bash
claude plugins add /path/to/dev-workflow
```

Or reference it in your project's plugin configuration.
