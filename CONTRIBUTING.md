# Contributing to cloud-app-blueprint

Thanks for your interest! cloud-app-blueprint is a reference architecture for cloud web apps plus the Claude Code workflow that builds and ships it. Good contributions make one of those stronger: a skill that scaffolds or checks part of the architecture, a convention that keeps a layer consistent, an agent that reviews it, or a whole new layer (another cloud, another frontend).

## Quick ways to contribute

- **Report bugs** -- [Open an issue](https://github.com/makigjuro/cloud-app-blueprint/issues/new?template=bug-report.yml)
- **Request features** -- [Open an issue](https://github.com/makigjuro/cloud-app-blueprint/issues/new?template=feature-request.yml)
- **Ask questions** -- [Start a discussion](https://github.com/makigjuro/cloud-app-blueprint/discussions)
- **Star the repo** -- Helps others discover it

## Adding a new skill

1. Fork the repo
2. Pick the plugin it belongs to (or create a new one)
3. Create `plugins/<plugin>/skills/<skill-name>/SKILL.md` with:
   - YAML frontmatter (`name`, `description`, `allowed-tools`, `user-invocable: true`)
   - Configuration section reading from `blueprint.json`
   - Step-by-step instructions
   - Error handling and output format
4. Run `claude plugin validate ./plugins/<plugin>` to check structure
5. Open a PR

See [Plugin Development Guide](docs/plugin-development.md) for detailed instructions.

## Adding a new convention skill

Claude Code does not load a `rules/` directory from plugins, so coding conventions ship as background skills.

1. Create `plugins/<plugin>/skills/<convention-name>/SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: my-conventions
   description: What the conventions cover. Apply whenever writing or editing <files>.
   user-invocable: false
   paths:
     - "src/**/*.cs"
   ---
   ```
2. Keep each skill focused -- one concern per file
3. Open a PR

## Adding a new agent

1. Create `plugins/<plugin>/agents/<agent-name>.md` with frontmatter:
   ```yaml
   ---
   name: my-agent
   description: What this agent does
   tools: Bash, Read, Glob, Grep
   ---
   ```
2. Omit `model` so the agent inherits the session model; pin `haiku` only for fast, advisory checks
3. Define clear scope boundaries
4. Include output format specification
5. Open a PR

## Creating a new plugin

1. Create `plugins/<plugin-name>/.claude-plugin/plugin.json`
2. Add the plugin entry to `.claude-plugin/marketplace.json`
3. Follow the structure in [docs/plugin-development.md](docs/plugin-development.md)
4. Open a PR

## Guidelines

- **No project-specific references** -- Skills must be generic, configured via `blueprint.json`
- **Auto-detect when config is missing** -- Never fail just because `blueprint.json` doesn't exist
- **Keep skills under 500 lines** -- Extract reference material to bundled files
- **Include error handling** -- Cover common failure modes
- **Test locally** -- `claude --plugin-dir ./plugins/<plugin>` before submitting

## Code of conduct

Be respectful and constructive. We're all here to build useful tools.

## Releasing

All four plugins share one version.

1. Move the `[Unreleased]` entries in `CHANGELOG.md` under a new version heading, and add its compare link at the bottom.
2. Bump `version` in every `plugins/*/.claude-plugin/plugin.json` and in `.claude-plugin/marketplace.json` (the metadata and each plugin entry).
3. Merge, then tag the merge commit and publish the release:
   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z
   gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <changelog section>
   ```

`/dev-workflow:new-project` downloads the starter at the tag that matches the plugin version, so tag every release.
