# Plugin Development Guide

How to contribute new plugins or extend existing ones in the cloudstack-ai-plugins marketplace.

## Plugin Structure

Each plugin lives in `plugins/<plugin-name>/` with this structure:

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # Required: plugin manifest
├── README.md                # Plugin documentation
├── skills/
│   └── <skill-name>/
│       └── SKILL.md         # Skill definition
├── agents/                  # Optional
│   └── <agent-name>.md
├── rules/                   # Optional
│   └── <rule-name>.md
├── hooks/                   # Optional
│   └── hooks.json
└── scripts/                 # Optional
    └── <script>.sh
```

## Creating a New Plugin

### 1. Create the directory

```bash
mkdir -p plugins/my-plugin/.claude-plugin
mkdir -p plugins/my-plugin/skills
```

### 2. Write plugin.json

```json
{
  "name": "my-plugin",
  "description": "What this plugin does in one sentence",
  "version": "0.1.0",
  "author": { "name": "Your Name" },
  "license": "MIT"
}
```

### 3. Add to marketplace.json

Add an entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin",
  "description": "Same description as plugin.json",
  "version": "0.1.0",
  "author": { "name": "Your Name" },
  "tags": ["relevant", "tags"]
}
```

### 4. Write skills

See [Writing Skills](#writing-skills) below.

### 5. Test locally

```bash
claude --plugin-dir ./plugins/my-plugin
```

## Writing Skills

### SKILL.md Structure

```yaml
---
name: my-skill
description: What this skill does. Include trigger keywords. Be specific and slightly "pushy" to ensure reliable invocation.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
user-invocable: true
---

# Skill Title

Brief description of what this skill does and when to use it.

## Arguments

- `{arg1}` -- Description (required/optional)

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `FIELD_1` = `section.field` (default: fallback value)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Process

### Step 1: ...

Detailed instructions.

## Output

Expected output format.

## Error Handling

- **Error case**: What to do
```

### Key Principles

1. **Always read cloudstack.json first** — Extract project-specific values before doing anything
2. **Auto-detect when config is missing** — Never fail just because cloudstack.json doesn't exist
3. **Use generic examples** — Don't reference specific projects in instructions
4. **Keep skills under 500 lines** — Extract reference material to bundled files if needed
5. **Include error handling** — Cover common failure modes
6. **Include a checklist** — Help verify the skill ran correctly

### cloudstack.json Integration

Every skill that needs project-specific values should:

1. Read `cloudstack.json` from `$CLAUDE_PROJECT_DIR/cloudstack.json`
2. Extract only the fields it needs
3. Have sensible defaults for every field
4. Auto-detect from project structure when the config file is missing

Example preamble:

```markdown
## Configuration

Read `cloudstack.json` from the project root. Extract:
- `SOLUTION` = `backend.solutionPath` (default: find `*.sln` in `src/`)
- `SERVICES` = `backend.services[]` (default: discover from `src/*/` directories)
```

## Writing Agents

Agents are markdown files with YAML frontmatter:

```yaml
---
name: my-agent
description: What this agent does
model: sonnet
tools: Bash, Read, Glob, Grep
---

# Agent instructions...
```

Key fields:
- `model`: `sonnet` (default), `opus` (complex analysis), or `haiku` (fast checks)
- `tools`: Comma-separated list of allowed tools

## Writing Rules

Rules provide contextual guidance based on file paths:

```yaml
---
paths:
  - "src/**/*.cs"
  - "src/**/*.csproj"
---

# Rule Title

## Convention 1
- Description
```

The `paths` field determines when the rule activates.

## Writing Hooks

Plugin hooks go in `hooks/hooks.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/scripts/my-hook.sh\"" }
        ]
      }
    ]
  }
}
```

Use `${CLAUDE_PLUGIN_ROOT}` to reference scripts within the plugin directory.

## Testing

### Local testing

```bash
# Test a single plugin
claude --plugin-dir ./plugins/my-plugin

# Test multiple plugins
claude --plugin-dir ./plugins/dotnet-architect --plugin-dir ./plugins/dev-workflow
```

### Validation

```bash
# Validate plugin structure
claude plugin validate ./plugins/my-plugin
```

### CI

The `validate-plugins.yml` workflow automatically checks:
- marketplace.json structure
- plugin.json manifests
- SKILL.md frontmatter (name, description required)
- Agent and rule frontmatter
- File references (every skill directory has a SKILL.md)
