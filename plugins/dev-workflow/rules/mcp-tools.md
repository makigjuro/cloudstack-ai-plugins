---
paths:
  - "**"
---

# MCP Tool Usage

When MCP tools are available, prefer them over CLI equivalents. MCP tools return structured data, handle authentication automatically, and are more reliable than parsing CLI output.

> **Note:** MCP servers are optional and user-configured. The sections below describe tools that may or may not be available in your environment. If a referenced MCP tool is not available, fall back to the CLI equivalent.

## context7 — Library Documentation

Before scaffolding code that uses a library, look up the current API to avoid outdated patterns.

**When to use:**
- Scaffolding code that uses frameworks or libraries (EF Core, Express, Django, Spring Boot, etc.)
- Debugging library-specific errors
- Checking if a library has a built-in feature before writing custom code
- Researching library capabilities during feature planning

**How to use:**
1. Resolve the library ID: `mcp__context7__resolve-library-id` with the library name
2. Query docs: `mcp__context7__query-docs` with the library ID and your question

Don't look up docs for every trivial operation — use it when the pattern is non-obvious, when hitting an error, or when a library feature might already exist for what you're building.

## playwright — Browser Automation

Use for frontend verification, smoke testing, interactive CRUD verification, and visual confirmation.

**When to use:**
- After `/run-local` — navigate to the app and verify it loaded
- After `/add-feature` — screenshot the new page with `/screenshot` or `/verify-feature`
- During `/smoke-test` — verify routes render, auth works, and CRUD flows succeed
- During `/verify-feature` — auto-detect changed routes, screenshot, check console/network
- During `/complete-task` — browser verification when frontend files changed
- Debugging frontend issues — take screenshots, check console errors, inspect network

### Basic pattern (navigate + check)

1. Navigate: `mcp__playwright__browser_navigate` to the URL
2. Wait: `mcp__playwright__browser_wait_for` for content to load
3. Snapshot: `mcp__playwright__browser_snapshot` for accessibility tree, or `browser_take_screenshot` for visual
4. Check: `mcp__playwright__browser_console_messages` for errors

### Interactive CRUD pattern

For verifying create/edit/delete flows work end-to-end:

1. `browser_snapshot` to find interactive elements (buttons, links)
2. `browser_click` on the trigger (e.g., "Create" button)
3. `browser_wait_for` the dialog/form to appear
4. `browser_fill_form` with test data
5. `browser_click` on submit
6. `browser_network_requests` to verify the API call returned 2xx
7. `browser_snapshot` to confirm the new item appears in the list

### Network inspection pattern

Use `browser_network_requests` to verify API health:
- All API calls should return 2xx
- Flag any 401 (auth issue), 403 (permissions), 4xx (client error), or 5xx (server error)
- Check after page load and after interactive actions

### Responsive pattern

For mobile viewport testing:
1. `browser_resize` to `375, 667` (iPhone SE)
2. `browser_take_screenshot` for mobile view
3. `browser_resize` to `1280, 720` to restore desktop viewport

## Mermaid Chart — Diagram Validation

Use to validate mermaid diagrams before writing them to documentation files.

**When to use:**
- During `/docs` — validate any mermaid syntax in generated docs
- During `/prd` — validate architecture diagrams

**How:** `mcp__claude_ai_Mermaid_Chart__validate_and_render_mermaid_diagram` with the diagram source

## GitHub Operations

Use the `gh` CLI for GitHub operations:

```bash
# Issues
gh issue view $ISSUE --json number,title,body,labels,state
gh issue create --title "..." --body "..."
gh issue list --label "..."

# Pull Requests
gh pr create --title "..." --body "..."
gh pr view $PR --json number,title,body,state
gh pr list

# Search
gh search issues "query" --repo owner/repo
gh search code "query" --repo owner/repo
```

If the `github-mcp-server` MCP is available, prefer its structured tools (`mcp__github-mcp-server__get_issue`, `mcp__github-mcp-server__create_pull_request`, etc.) over the CLI equivalents for typed JSON responses.
