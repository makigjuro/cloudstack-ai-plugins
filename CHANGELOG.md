# Changelog

All notable changes to the cloud-app-blueprint marketplace (named cloudstack-ai-plugins before 0.4.0). All four plugins share one version.

After a release, run `/plugin marketplace update cloud-app-blueprint`, then update the plugins from `/plugin` (or reinstall with `/plugin install <name>@cloud-app-blueprint`).

## [Unreleased]

### Fixed
Found by deploying the starter to a real Azure subscription. It now deploys end to end: platform, migration job, Orders and gateway revisions healthy, smoke test passing.
- First apply of a new environment: units whose dependencies don't exist yet were planned with mock outputs, and applying those saved plans failed with 404s. `/cloud-infra:infra-apply` and the infra README now apply in waves, with a fresh plan per wave, and refuse plans that contain mock values. `/cloud-infra:deploy` and the CI rollout plan the gateway again after the services it routes to exist.
- `terragrunt run --all plan -out=tfplan` fails on Terragrunt 0.93. Terraform flags now go after `--` everywhere.
- Orders exited on start in Azure (`Auth:Authority and Auth:Audience must be configured`). Each `env.hcl` now sets `auth_authority` (empty = the deploy tenant) and `auth_audience`, and the Orders unit passes them. `add-container-app` adds them for new services, and the infra README documents the app registration.
- The Dockerfiles crashed in `dotnet restore` when building `linux/amd64` on Apple Silicon. The SDK stage now runs on `$BUILDPLATFORM` and cross-compiles with `-a $TARGETARCH`.
- `deploy` and the CI rollout treat a revision in `ActivationFailed` as failed instead of waiting for it.
- The Key Vault firewall accepts `KEY_VAULT_ALLOWED_IPS` (IPv4) at run time, so an operator's IP doesn't have to be committed.
- Destroying dev now purges its Key Vault (no purge protection there), so the next apply doesn't recover the old vault and its secrets.
- `new-project` no longer prints git's detached-HEAD notices. The infra README uses the same 7-character image tags as the deploy skill and CI.

## [0.4.0] - 2026-11-03

### Renamed
- The repo and marketplace are now **cloud-app-blueprint** (was `cloudstack-ai-plugins`, which clashed with Apache CloudStack). GitHub redirects the old URLs.
- The config file is now `blueprint.json` (was `cloudstack.json`), and the schema is `schema/blueprint.schema.json`. The format is unchanged. `/dev-workflow:init` offers to rename an existing `cloudstack.json`, and the hook scripts still read the old name.
- The starter moved to `examples/dotnet-react-azure`.
- **Migrating an install:** `/plugin marketplace remove cloudstack-ai-plugins`, then `/plugin marketplace add makigjuro/cloud-app-blueprint` and reinstall the plugins with `@cloud-app-blueprint`.

### Added
- `/dev-workflow:new-project <Name>`: creates a repo from the starter, renamed to your project (namespaces, files, images, Azure resource prefix), then builds and tests it. CI regenerates a project from the starter on every starter change.
- `/dev-workflow:doctor`: checks the tools the plugins depend on (`jq`, `gh` auth, .NET SDK and `dotnet-ef`, Node, Docker, `terraform`, `terragrunt`, `trivy`, `az`, `helm`) and prints install hints.
- Cost and scope notes in the docs: what `complete-task` launches, how to run a lighter pass, and which parts of the stack are tested.
- `examples/dotnet-react-azure`: a working reference app with a hexagonal .NET Orders service, YARP gateway, React app, Terraform/Terragrunt for Azure Container Apps (dev/staging/prod), docker-compose, and its own `blueprint.json`.
- Azure Container Apps runtime:
  - `infrastructure.runtime` (`container-apps` default, `aks`), `frontendHosting` and `containerApps` in `blueprint.json`, detected by `/dev-workflow:init`.
  - `/cloud-infra:add-container-app` and `/cloud-infra:add-container-app-job` scaffold services and migration jobs.
  - `/cloud-infra:deploy` ships SHA-tagged images (migration job, then apps with the gateway last, then smoke test, with rollback to the recorded tags). It previews by default.
  - `/cloud-infra:add-ci-pipeline` writes the GitHub Actions workflows (CI, then dev deploy and staging/prod promotion with OIDC, plus Static Web Apps). The starter ships the reference output.
  - `container-apps-conventions` background skill and a Container Apps checklist in `infra-reviewer`.

### Changed
- Pre-commit lint and secret-scan hooks only start on `git commit` / `git push` (hook `if` filters) instead of on every Bash call.
- Bundled MCP servers are pinned (`@upstash/context7-mcp@4.4.4`, `@playwright/mcp@0.0.83`) instead of tracking `latest`.
- Lint (`lint`, `infra-lint`, `complete-infra`, `complete-task`) runs `helm lint` only on the AKS runtime or when charts exist, and validates Terragrunt units with `--provider-cache` on Container Apps.
- Skills aligned with the starter, which builds and runs:
  - no `.WithOpenApi()` (deprecated in .NET 10, `ASPDEPR002`); `AddOpenApi`/`MapOpenApi` plus endpoint metadata instead
  - `WolverineFx.RuntimeCompilation` and explicit handler assembly discovery
  - `Result` in Shared.Infrastructure, with domain factories guarding via `ArgumentException`
  - a `ToHttpResult(location)` overload for 201 responses
  - ProblemDetails errors with `error`/`message`/`errorType`
  - tenant ID taken from the token
  - `--migrate` registers only persistence
  - xunit.v3 and FluentAssertions 7.x pinned for licensing
  - frontend query hooks in `hooks/api/`, a fetch-based API client, and in-memory tokens

### Fixed
- When `jq` is missing, the hooks now show a visible warning instead of silently skipping lint, formatting and the secret scan.

## [0.3.0] - 2026-10-21

### Added
- Repositioned as a reference architecture plus the workflow that builds and ships it. Azure Container Apps is the default runtime in the docs, with AKS + Helm as the alternative (Container Apps skills tracked in #4).
- `validators.mcpServer` config: architecture checks and reviews use a project's batch validation MCP tools when available.
- `scripts/resolve-test-projects.sh`: deterministic changed-files → test-projects resolution for `/run-tests`.
- `complete-task` Workflow-tool path with schema-validated findings and adversarial verification. `frontend-reviewer` now runs when frontend files change.
- `infra-apply` applies exactly the saved, reviewed plan, including `terragrunt run --all`.

### Changed
- Review agents inherit the session model; only `doc-checker` pins Haiku.
- `rules/` folders, which Claude Code never loads from plugins, converted to background convention skills.
- MCP tool names use the plugin-prefixed form (`mcp__plugin_<plugin>_<server>__<tool>`). Agents and skills are referenced by namespaced names.
- GitHub operations are `gh`-first. `prd` and `plan-feature` run in the main conversation.
- Prompt audit: stale instructions removed, and scaffolding templates aligned with the conventions (async handler calls, positional commands, entity-specific error codes, migration output dir, testing conventions).

### Fixed
- `trivy-scan` documented CLI flags the script never accepted. Script paths used an undefined placeholder.
- Several contradictions between skills, such as entity constructors, repository-interface location, PR title casing and endpoint auth exemptions.

## [0.2.0] - 2026-04-19

### Added
- `/dev-workflow:init` (generate `cloudstack.json`), `/dotnet-architect:generate-tests`, and the `react-developer:frontend-reviewer` agent.
- `/cloud-infra:trivy-scan`, wired into `infra-lint` and `complete-infra`.
- Bundled context7 and Playwright MCP configs.
- Newer skill frontmatter (`argument-hint`, `context: fork`, `allowed-tools`).

## [0.1.0] - 2026-03-28

### Added
- Initial marketplace with four plugins: `dotnet-architect`, `react-developer`, `cloud-infra`, `dev-workflow`.
- Reference architecture docs, `cloudstack.json` schema and template, hooks for formatting, pre-commit lint and secret scanning.

[Unreleased]: https://github.com/makigjuro/cloud-app-blueprint/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/makigjuro/cloud-app-blueprint/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/makigjuro/cloud-app-blueprint/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/makigjuro/cloud-app-blueprint/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/makigjuro/cloud-app-blueprint/releases/tag/v0.1.0
