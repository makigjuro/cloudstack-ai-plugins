---
name: init
description: Scan a project and generate cloudstack.json configuration. Use when setting up cloudstack-ai-plugins for the first time, onboarding a new project, or when the user says "init", "setup", "configure", "get started", or "onboard".
allowed-tools: Bash, Read, Glob, Grep, Write, AskUserQuestion
user-invocable: true
argument-hint: "[--minimal]"
---

# Initialize Project

Scan the project structure, detect the tech stack, and generate a `cloudstack.json` configuration file. This is the first thing users should run after installing cloudstack-ai-plugins.

## Arguments

- `--minimal` -- Generate only the essential fields, skip optional sections

## Process

### Step 1: Check for existing config

```bash
test -f cloudstack.json && echo "EXISTS" || echo "NONE"
```

If `cloudstack.json` already exists, ask the user whether to overwrite or update it.

### Step 2: Detect project structure

Run these scans in parallel:

**Backend detection:**
```bash
# .NET solution
find . -name "*.sln" -maxdepth 3 -not -path "./.git/*" 2>/dev/null

# Shared domain project
find . -path "*/Domain/Entities" -type d -not -path "*/bin/*" -not -path "*/obj/*" 2>/dev/null

# Shared infrastructure project
find . -path "*Shared*Infrastructure*" -name "*.csproj" -not -path "*/bin/*" 2>/dev/null

# Microservices (directories containing .Application subfolder)
find . -name "*.Application" -type d -not -path "*/bin/*" -not -path "*/obj/*" 2>/dev/null

# Messaging framework
grep -rl "WolverineFx\|MediatR\|MassTransit" --include="*.csproj" -l 2>/dev/null | head -1

# ORM detection
grep -rl "Microsoft.EntityFrameworkCore" --include="*.csproj" -l 2>/dev/null | head -1
```

**Frontend detection:**
```bash
# Package.json location
find . -name "package.json" -maxdepth 3 -not -path "*/node_modules/*" -not -path "*/tools/*" 2>/dev/null

# If found, detect framework and libraries from dependencies
cat <frontend-path>/package.json | grep -E "react|vue|angular|@tanstack|zustand|redux|shadcn|@mui|vite|webpack|next"
```

**Infrastructure detection:**
```bash
# Terraform
find . -name "*.tf" -maxdepth 4 -not -path "./.git/*" 2>/dev/null | head -1

# Terragrunt
find . -name "terragrunt.hcl" -maxdepth 4 2>/dev/null | head -1

# Helm charts
find . -name "Chart.yaml" -maxdepth 4 2>/dev/null

# Docker Compose
find . -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -maxdepth 3 2>/dev/null

# .NET Aspire
find . -name "*AppHost*" -type d -maxdepth 4 2>/dev/null

# CI/CD
ls .github/workflows/*.yml 2>/dev/null || ls .gitlab-ci.yml 2>/dev/null || ls azure-pipelines.yml 2>/dev/null
```

**Repository detection:**
```bash
git remote get-url origin 2>/dev/null
```

### Step 3: Resolve ambiguities

Use AskUserQuestion for anything that can't be auto-detected:

- **Multiple solutions found** -- Ask which is the primary one
- **No namespace detectable** -- Ask for the root C# namespace
- **Multiple frontend directories** -- Ask which is the main one
- **Cloud provider unclear** -- Ask Azure vs AWS vs GCP

Keep questions to a minimum. If a value is clearly detectable, don't ask.

### Step 4: Generate cloudstack.json

Build the configuration object from detected values. Include:

- `$schema` reference for IDE autocompletion
- `project` -- name (from solution name or directory), namespace (from .csproj)
- `repository` -- owner/name (from git remote)
- `backend` -- solutionPath, sharedDomainPath, sharedInfraPath, services[], orm, messaging
- `frontend` -- path, framework, stateManagement, uiLibrary, bundler, devPort
- `infrastructure` -- cloud, iac, iacWrapper, terraformPath, chartsPath, namespace
- `localDev` -- orchestrator, appHostPath or composePath
- `conventions` -- branchFormat (detect from existing branches), commitStyle

If `--minimal` was passed, only include `project`, `backend.solutionPath`, and `backend.services[]`.

Write the file:
```bash
# Write cloudstack.json to project root
```

### Step 5: Recommend plugins

Based on what was detected, recommend which plugins to install:

```markdown
## Project Initialized

Created `cloudstack.json` with:
- {N} microservices detected
- {frontend framework} frontend at `{path}/`
- {iac tool} infrastructure at `{path}/`

### Recommended plugins:

| Plugin | Why | Install |
|--------|-----|---------|
| dotnet-architect | {N} .NET services detected | `/plugin install dotnet-architect@cloudstack-ai-plugins` |
| react-developer | React frontend at `{path}/` | `/plugin install react-developer@cloudstack-ai-plugins` |
| cloud-infra | Terraform + Helm detected | `/plugin install cloud-infra@cloudstack-ai-plugins` |
| dev-workflow | Git workflow + CI/CD | `/plugin install dev-workflow@cloudstack-ai-plugins` |

### Next steps:
1. Review `cloudstack.json` and adjust any values
2. Install recommended plugins above
3. Try `/dotnet-architect:check-architecture` to validate your project
```

Only recommend plugins relevant to what was detected (e.g., skip react-developer if no frontend found).

## Error Handling

- **Not a git repo:** Warn but continue -- skip repository section
- **No .NET solution found:** Skip backend section, note it
- **No frontend found:** Skip frontend section
- **Permission denied on scan:** Note the directory and skip it

## Related Skills

- `/dotnet-architect:check-architecture` -- Run after init to validate architecture
- `/dev-workflow:start-work` -- Begin implementing with proper branch workflow
