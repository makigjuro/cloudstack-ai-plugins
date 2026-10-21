# Getting Started

cloudstack-ai-plugins is a reference architecture for cloud web apps plus the Claude Code workflow that builds and ships it. This guide takes you from install to your first deployed change.

## Prerequisites

- [Claude Code](https://claude.com/claude-code)
- `gh` (GitHub CLI), authenticated
- For the stack you use:
  - .NET SDK and `dotnet-ef`
  - Node.js
  - Docker (for integration tests and local dev)
  - `terraform`, `trivy`, `az` CLI (and `terragrunt`; `helm` only for the AKS runtime)

Check your machine with `/dev-workflow:doctor` once the plugins are installed. It lists what's missing and how to install it.

## 1. Install

```
/plugin marketplace add makigjuro/cloudstack-ai-plugins
/plugin install dev-workflow@cloudstack-ai-plugins
/plugin install dotnet-architect@cloudstack-ai-plugins
/plugin install react-developer@cloudstack-ai-plugins
/plugin install cloud-infra@cloudstack-ai-plugins
```

Install only the layers you need. Each plugin works on its own, and `dev-workflow` uses whichever others are present.

## 2. Configure

```
/dev-workflow:init
```

This scans your project and writes a `cloudstack.json` with your solution, services, frontend path, infra paths and conventions. It's optional, since the plugins auto-detect without it. It is worth having on a real project. Every field is in the [cloudstack.json reference](cloudstack-json-reference.md), and `templates/cloudstack.json` is a full starting point.

Check that the backend matches the architecture:

```
/dotnet-architect:check-architecture
```

## 3. Build a feature

1. **Plan.** `/dev-workflow:prd` for a complex feature, or `/dev-workflow:plan-feature` for a simple one. Then `/dev-workflow:create-tasks` turns the plan into GitHub issues.
2. **Branch.** `/dev-workflow:start-work 42` creates the branch from issue #42 and starts implementing.
3. **Build.** Claude uses the scaffolding skills as it goes:
   - `/dotnet-architect:add-entity`, `add-command`, `add-query`, `add-event-handler`
   - `/react-developer:add-feature`
   - `/cloud-infra:add-terraform-module` for new resources (and `add-helm-chart` on the AKS runtime)

   The convention skills keep each layer consistent while it edits.
4. **Verify.** `/dev-workflow:run-tests` runs only the affected tests. `/react-developer:verify-feature` checks changed pages in a browser.
5. **Ship.** `/dev-workflow:complete-task` builds, lints, tests, runs the review agents, fixes what they find and opens the PR.

## 4. Deploy

1. `/cloud-infra:infra-lint` validates Terraform and Helm and runs the trivy security scan.
2. `/cloud-infra:infra-apply dev` shows the plan for an environment.
3. `/cloud-infra:infra-apply dev --apply` applies exactly that reviewed plan after you confirm. If anything changed since planning, it stops so you can re-plan and review again.

For an infra-only branch, `/cloud-infra:complete-infra` runs lint, scan and review, then opens the PR.

The target runtime is Azure Container Apps. A one-command app deploy is in progress ([#4](https://github.com/makigjuro/cloudstack-ai-plugins/issues/4)): build SHA-tagged images, run migrations as a job, roll a new revision and smoke-test it.

## Cost and speed

`/dev-workflow:complete-task` is the most expensive command. After the build, lint and test gates it launches review agents in parallel:
- **Always:** `dotnet-architect:reviewer` and `dev-workflow:verifier`.
- **When relevant:** `doc-checker` (Haiku), `infra-reviewer` and `frontend-reviewer`.

With the Workflow tool, each critical or warning finding also gets its own verification agent. Each review agent runs on your session model, so cost scales with the model, the size of the diff and the number of findings.

For a lighter pass:
- Run `/dotnet-architect:check-architecture`, `/dev-workflow:run-tests` and `/dev-workflow:lint` while you work. Save `complete-task` for when the branch is ready.
- Use `/dev-workflow:complete-task --skip-integration` for work-in-progress checks.
- Keep branches small. Every agent reviews the whole diff.

## What's tested

The reference path is the one the plugins are built and used against:
- .NET 10 with WolverineFx, EF Core and PostgreSQL
- React with TanStack Query, Zustand and shadcn/ui
- Terraform + Terragrunt on Azure, GitHub Actions

Other values in `cloudstack.json` are accepted, and the skills adapt by reading your existing code, but they haven't been tested end to end:
- `cloud: aws | gcp`
- `uiLibrary: mui | antd`
- `stateManagement: swr | redux`
- `messageBroker: rabbitmq`

Reports are welcome in the [issues](https://github.com/makigjuro/cloudstack-ai-plugins/issues).

## MCP servers

The plugins bundle what they need:
- **context7**, for library docs while scaffolding
- **Playwright**, for browser checks in react-developer

Mermaid Chart (diagram validation) and `github-mcp-server` are used when you have them; GitHub operations default to `gh`.

## Next

- [Reference architecture](architecture.md): layers, CQRS flow, cloud topology, quality gates
- [Writing plugins and skills](plugin-development.md)
