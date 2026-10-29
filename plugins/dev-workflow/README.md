# dev-workflow

**The workflow layer of the [cloudstack reference architecture](../../README.md).** It moves a feature from idea to a shippable pull request and runs the backend, frontend and infra plugins' checks at the right moments.

```
/plugin install dev-workflow@cloudstack-ai-plugins
```

## The flow

| Stage | Skills |
|---|---|
| Plan | `/dev-workflow:prd` (full requirements), `/dev-workflow:plan-feature` (lighter breakdown), `/dev-workflow:create-tasks` (GitHub issues: single or epic + tasks) |
| Build | `/dev-workflow:start-work 42` branches from the issue and starts implementing |
| Verify | `/dev-workflow:run-tests` (only affected test projects), `/dev-workflow:lint`, `/dev-workflow:run-local` (Aspire or Docker Compose) |
| Ship | `/dev-workflow:complete-task` builds, lints, tests, runs parallel review agents, fixes issues (max 3 rounds) and opens the PR |
| Support | `/dev-workflow:code-review`, `/dev-workflow:task-check`, `/dev-workflow:create-pr`, `/dev-workflow:docs`, `/dev-workflow:diagnose`, `/dev-workflow:init`, `/dev-workflow:doctor` (checks prerequisites) |

`complete-task` checks only what changed and uses whichever other plugins are installed:
- With dotnet-architect: .NET build, migrations check, architecture review.
- With react-developer: type-check, ESLint, browser checks and frontend review.
- With cloud-infra: Helm/Terraform lint, trivy and infra review.

Without them, it still handles tests, review, acceptance criteria and the PR.

## Agents

| Agent | Model | Role |
|---|---|---|
| `dev-workflow:verifier` | session model | Checks the implementation against the issue's acceptance criteria |
| `dev-workflow:analyzer` | session model | Maps existing patterns and integration points before a new feature |
| `dev-workflow:investigator` | session model | Gathers evidence for `/diagnose` without jumping to conclusions |
| `dev-workflow:doc-checker` | Haiku | Fast advisory check for docs made stale by the change |

## Always-on guardrails

- **Convention skills** that Claude applies automatically:
  - `git-conventions`: branches, commits, PRs
  - `workflow`: which skill fits each step
  - `mcp-tools`: when to use the MCP servers
  - `skill-writing`: how to write skills
- **Hooks** (lint and secret scan start only on `git commit` / `git push`; they need `jq` and warn visibly if it's missing):
  - `format-on-save.sh` formats C#, TS/JS, Terraform, Python and Go after edits.
  - `pre-commit-lint.sh` lints staged files before `git commit`.
  - `scan-secrets.sh` blocks leaked keys and tokens before commit or push.

## Configuration

Run `/dev-workflow:init` to generate `cloudstack.json` from your project layout. The fields this plugin uses most are:
- `backend.solutionPath`
- `backend.services[]` (with `aliases`/`testProjects` for test resolution)
- `frontend.path`
- `localDev.*`
- `conventions.branchFormat` / `commitStyle`
- `validators.mcpServer`

Without the file, the plugin auto-detects. See the [cloudstack.json reference](../../docs/cloudstack-json-reference.md).

**MCP servers:** context7 (library docs) is bundled. Mermaid Chart and `github-mcp-server` are used when available. GitHub operations default to the `gh` CLI.
