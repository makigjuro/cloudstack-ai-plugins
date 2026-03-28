# Getting Started

## Prerequisites

- [Claude Code](https://claude.ai/code) installed
- A .NET + React + Azure project (or any subset)

## Installation

### Step 1: Add the marketplace

In Claude Code, run:

```
/plugin marketplace add makigjuro/cloudstack-ai-plugins
```

### Step 2: Install plugins

Install the plugins you need:

```
/plugin install dotnet-architect@cloudstack-ai-plugins
/plugin install react-developer@cloudstack-ai-plugins
/plugin install cloud-infra@cloudstack-ai-plugins
/plugin install dev-workflow@cloudstack-ai-plugins
```

### Step 3: Configure your project

Create a `cloudstack.json` at your project root. Start from the template:

```bash
cp <plugin-path>/templates/cloudstack.json ./cloudstack.json
```

Or create a minimal one:

```json
{
  "$schema": "https://raw.githubusercontent.com/makigjuro/cloudstack-ai-plugins/main/schema/cloudstack.schema.json",
  "project": {
    "name": "MyProject",
    "namespace": "MyProject"
  },
  "backend": {
    "solutionPath": "src/MyProject.sln",
    "services": [
      { "name": "OrderService", "path": "src/OrderService", "projectPrefix": "MyProject.OrderService" }
    ]
  }
}
```

This file is optional. Without it, plugins auto-detect from your project structure.

### Step 4: Verify installation

```
/dotnet-architect:check-architecture
```

This should scan your project and report on hexagonal architecture layer compliance.

## Configuration Reference

See [cloudstack.json reference](cloudstack-json-reference.md) for all available fields.

## Workflow

The recommended workflow with all plugins installed:

1. **Plan**: `/dev-workflow:plan-feature` to break down the feature
2. **Track**: `/dev-workflow:create-tasks` to create GitHub issues
3. **Branch**: `/dev-workflow:start-work 42` to create a feature branch
4. **Build**: Use `/dotnet-architect:add-*` and `/react-developer:add-feature` skills
5. **Verify**: `/dotnet-architect:check-architecture` for quick checks
6. **Complete**: `/dev-workflow:complete-task` for the full quality pipeline

## Optional MCP Servers

For the best experience, configure these MCP servers in your `.mcp.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

- **context7**: Library documentation lookup (used by scaffolding skills)
- **playwright**: Browser automation (used by screenshot, verify-feature, smoke-test)
