---
name: doctor
description: Check that the tools the cloudstack plugins depend on are installed and authenticated — jq, gh, .NET SDK and dotnet-ef, Node, Docker, Terraform, Terragrunt, trivy, Azure CLI, Helm — and print install hints for anything missing. Use when setting up a machine, when a skill or hook fails because a tool is missing, or before the first /complete-task or /infra-apply.
allowed-tools: Bash, Read
argument-hint: "[backend|frontend|infra|all]"
---

# Doctor

Report which prerequisites are present, which are missing, and how to install them. Only check; never install anything or change configuration.

## Configuration

Read `cloudstack.json` from the project root if it exists, and use it to decide which layers apply:
- Backend: `backend.solutionPath` set, or a `*.sln` under `src/`
- Frontend: `frontend.path` set, or a `package.json` in `web/`, `frontend/` or `client/`
- Infra: `infrastructure.*` set, or `infra/` / `deploy/` directories
- Runtime: `infrastructure.runtime` (`container-apps` default, `aks`)

With an argument, check only that layer. Without one, check every layer the project uses, plus the core tools.

## Checks

Run each command, and treat a non-zero exit or "command not found" as missing.

| Layer | Tool | Check | Why it's needed |
|---|---|---|---|
| core | `git` | `git --version` | everything |
| core | `jq` | `jq --version` | hooks (format, pre-commit lint, secret scan) and `run-tests` resolution — without it they are skipped |
| core | `gh` | `gh auth status` | issues, branches and PRs (`start-work`, `create-tasks`, `create-pr`, `complete-task`) |
| backend | .NET SDK | `dotnet --list-sdks` | build and tests; the reference stack targets .NET 10 |
| backend | `dotnet-ef` | `dotnet ef --version` | `add-entity`, `add-migration`, the pending-migrations gate |
| backend | Docker | `docker info` | Testcontainers integration tests, local dev |
| frontend | Node + npm | `node --version`, `npm --version` | type-check, lint, dev server |
| infra | `terraform` | `terraform version` | `infra-lint`, `infra-apply` |
| infra | `terragrunt` | `terragrunt --version` | only if `infrastructure.iacWrapper` is `terragrunt` or `terragrunt.hcl` files exist |
| infra | `trivy` | `trivy --version` | `trivy-scan`, `infra-lint`, `complete-infra` (a missing trivy fails those gates) |
| infra | Azure CLI | `az account show` | plan/apply against Azure; reports whether you are logged in and to which subscription |
| infra | `helm` | `helm version` | only for the AKS runtime or if `deploy/charts/` exists |

Report the subscription name from `az account show`, but not IDs or tokens.

## Install hints

Give the hint for the detected OS (`uname`):

| Tool | macOS | Linux |
|---|---|---|
| jq | `brew install jq` | `apt install jq` |
| gh | `brew install gh`, then `gh auth login` | see cli.github.com, then `gh auth login` |
| .NET SDK | `brew install --cask dotnet-sdk` | see dotnet.microsoft.com/download |
| dotnet-ef | `dotnet tool install --global dotnet-ef` | same |
| Docker | Docker Desktop or `brew install --cask docker` | Docker Engine for your distro |
| Node | `brew install node` | nodejs.org or your package manager |
| terraform | `brew install hashicorp/tap/terraform` | developer.hashicorp.com/terraform/install |
| terragrunt | `brew install terragrunt` | github.com/gruntwork-io/terragrunt releases |
| trivy | `brew install trivy` | trivy.dev installation docs |
| Azure CLI | `brew install azure-cli`, then `az login` | learn.microsoft.com/cli/azure/install-azure-cli, then `az login` |
| helm | `brew install helm` | helm.sh/docs/intro/install |

## Output

```
## cloudstack doctor

| Layer | Tool | Status | Detail |
|---|---|---|---|
| core | jq | OK | 1.7.1 |
| core | gh | MISSING AUTH | run `gh auth login` |
| infra | trivy | MISSING | brew install trivy |
...

Ready: backend, frontend
Blocked: infra (trivy missing; az not logged in)
```

End with the one or two commands that unblock the most, if anything is missing.
