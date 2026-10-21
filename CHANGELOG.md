# Changelog

All notable changes to the cloudstack-ai-plugins marketplace. All four plugins share one version.

After a release, update installed plugins with `/plugin` (or reinstall with `/plugin install <name>@cloudstack-ai-plugins`).

## [Unreleased]

### Added
- `/dev-workflow:doctor`: checks the tools the plugins depend on (`jq`, `gh` auth, .NET SDK and `dotnet-ef`, Node, Docker, `terraform`, `terragrunt`, `trivy`, `az`, `helm`) and prints install hints.
- Cost and scope notes in the docs: what `complete-task` launches, how to run a lighter pass, and which parts of the stack are tested.

### Changed
- Pre-commit lint and secret-scan hooks only start on `git commit` / `git push` (hook `if` filters) instead of on every Bash call.
- Bundled MCP servers are pinned (`@upstash/context7-mcp@4.4.4`, `@playwright/mcp@0.0.83`) instead of tracking `latest`.

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

[Unreleased]: https://github.com/makigjuro/cloudstack-ai-plugins/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/makigjuro/cloudstack-ai-plugins/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/makigjuro/cloudstack-ai-plugins/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/makigjuro/cloudstack-ai-plugins/releases/tag/v0.1.0
