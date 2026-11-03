---
name: new-project
description: Create a new project from the cloud-app-blueprint reference starter — hexagonal .NET 10 service, YARP gateway, React app, Terraform/Terragrunt for Azure Container Apps, CI workflows and blueprint.json — renamed to the user's project name, then build and test it. Use when the user wants to start a new project, bootstrap a greenfield app, or scaffold a repo on the cloud-app-blueprint architecture.
allowed-tools: Bash, Read, AskUserQuestion
argument-hint: "<ProjectName> [--short <id>] [--dir <path>]"
---

# New Project

Create a new repository from `examples/dotnet-react-azure` in the cloud-app-blueprint repo, renamed to the user's project, and prove it works before handing it over. A deterministic script does the copy and rename; this skill picks the names, runs it, and verifies the result.

## Arguments

- `<ProjectName>` -- PascalCase or kebab-case (`AcmeShop`, `acme-shop`). Becomes the .NET namespace prefix: `AcmeShop.Orders.Host`, `src/AcmeShop.sln`.
- `--short <id>` -- lowercase prefix for Azure resource names, container images and the compose project, 2-7 letters/digits. Defaults to the name without separators when that fits.
- `--dir <path>` -- target directory. Defaults to `./<kebab-name>` under the current directory.

## Process

### Step 1: Names

If no project name was given, ask for it. Ask nothing else up front; everything else is either derived or fixed by the starter.

Work out the short name the way the script will: the name lowercased with `-`, `_` and spaces removed. When it is longer than 7 characters or starts with a digit and `--short` was not given, ask with AskUserQuestion, offering two or three candidates of at most 7 characters (e.g. for `acme-shop`: `acme`, `acmshop`, `ashop`). Explain the reason in one line: Azure storage account names are limited to 24 characters, and the state account is `<short>tfstatestagingweu`.

These come from the starter as they are, so don't ask about them:
- Cloud: Azure. Runtime: Container Apps. Frontend hosting: Static Web Apps. Region: West Europe (`weu`). The other values in `blueprint.json` are untested end to end (see the plugins' getting-started "What's tested").
- Layers: every layer is included (backend, gateway, web, infra, CI), with Orders as the sample service.

### Step 2: Create

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/new-project.sh" <ProjectName> [--short <id>] [--dir <path>]
```

The script downloads `examples/dotnet-react-azure` from GitHub at the tag that matches the plugin version (or `main` when there is no such tag), renames every `Starter`/`starter` identifier in paths and file contents, removes the notes that only apply inside the plugins repo, fails if any reference to the starter is left, and makes one initial commit on `main` (skipped when the target is inside an existing git repository).

| Exit | Meaning | Action |
|---|---|---|
| 0 | Created | Continue to Step 3 |
| 2 | Name or short name invalid | Show the message, ask for a valid value, rerun |
| 3 | Target exists and is not empty | Ask for another `--dir`. Never delete or overwrite the existing directory |
| 1 | Download, copy or rename failed | Show the output; stop |

Pass `--from <path-to-examples/dotnet-react-azure>` instead of downloading only when the user points at a local checkout of the plugins repo.

### Step 3: Verify

Run in the new project directory. Skip a layer only when its tool is missing (say which, and suggest `/dev-workflow:doctor`); don't skip because a check is slow.

```bash
# Backend: build with warnings as errors, then unit tests
dotnet build src/<ProjectName>.sln -warnaserror
dotnet test src/<ProjectName>.sln --no-build --filter "Category!=Integration"

# Integration tests: only when Docker is running (Testcontainers PostgreSQL)
docker info >/dev/null 2>&1 && dotnet test src/<ProjectName>.sln --no-build --filter "Category=Integration"

# Web
(cd web && npm ci && npm run type-check && npm run lint && npm test -- --run && npm run build)

# Infra: offline validation, no Azure credentials used
(cd infra/terragrunt/dev && env -u ARM_SUBSCRIPTION_ID TG_OFFLINE=true terragrunt run --all --provider-cache --non-interactive validate)
```

If a check fails, report the failing command and its output. Don't patch the generated project to make it pass: a failure here is a bug in the starter or the script, so say so.

### Step 4: Report

```markdown
## Created <ProjectName>

**Location:** <dir>
**Namespace:** <ProjectName> -- **Resource prefix:** <short>
**Source:** <source line from the script>

| Check | Result |
|---|---|
| dotnet build | pass |
| Unit tests | N passed |
| Integration tests | N passed / skipped (no Docker) |
| Web (type-check, lint, test, build) | pass |
| Terragrunt validate (dev) | N/N units |

### Next steps
1. `cd <dir> && claude`, then `/dotnet-architect:check-architecture`
2. Run it locally: `cp .env.example .env && docker compose up --build`
3. Push it: `gh repo create <owner>/<kebab-name> --private --source . --push`
4. Deploy: follow `infra/README.md` (state bootstrap, OIDC), then `/cloud-infra:infra-apply dev` and `/cloud-infra:deploy dev`
5. Replace the sample: `/dotnet-architect:add-entity`, `/react-developer:add-feature`, or delete Orders once you have your own service
```

To change the region, edit `location`/`location_short` in `infra/terragrunt/root.hcl`, `LOCATION`/`LOCATION_SHORT` in `infra/scripts/bootstrap-state.sh`, the `-weu` names in `.github/workflows/`, and `conventions.locationShort` in `blueprint.json`. Mention this only if the user asks about regions.
