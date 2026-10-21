---
name: skill-writing
description: Principles for writing and editing Claude Code skills — trigger-focused descriptions, writing style, structure, and progressive disclosure. Apply whenever creating or modifying a SKILL.md file.
user-invocable: false
paths:
  - ".claude/skills/**/*.md"
  - "plugins/**/skills/**/*.md"
---

# Skill Writing Principles

Follow these principles when creating or modifying skills.

## Description Frontmatter

The `description` field in YAML frontmatter is the primary triggering mechanism — Claude decides whether to invoke a skill based on it. Write descriptions that are specific about when to trigger. Name the categories of intent that should trigger the skill; calibrated urgency is fine, ideally tuned against real prompts rather than added one phrase per missed trigger.

**Good:** "Scaffold a new CQRS command with handler, validator, and POST endpoint following project conventions. Use this whenever the user wants to add a write operation, mutation endpoint, POST route, or state-changing action to any microservice."

**Bad:** "Create a command"

Include both what the skill does AND specific contexts/keywords that should trigger it.

## Writing Style

- Use imperative form in instructions
- Explain the **why** behind instructions, not just the what — Claude understands reasoning better than rigid rules
- Avoid heavy-handed MUSTs and NEVERs in all-caps unless genuinely critical (security, data loss). Instead, explain why something matters so the model understands the tradeoff
- Start with a draft, then review with fresh eyes for clarity and conciseness

## Structure

Keep SKILL.md under 500 lines. If approaching this limit, extract reference material into bundled files:

```
skill-name/
├── SKILL.md           # Core workflow (< 500 lines)
└── references/        # Detailed docs loaded on demand
    └── templates.md
```

## Progressive Disclosure

Skills load in three levels:
1. **Metadata** (name + description) — always in context (~100 words)
2. **SKILL.md body** — loaded when skill triggers
3. **Bundled resources** — loaded on demand via Read

Keep the most important instructions in the SKILL.md body. Put detailed templates, long examples, and reference tables in bundled files.

## Practical Patterns

- Include a checklist at the end for verification
- Add a "Related Skills" section linking to skills commonly used before/after
- Include realistic code templates grounded in existing project patterns
- Pin an exact output format only where a consumer parses it
- For skills that run bash commands, show the actual commands (not pseudocode)

## Avoiding Common Issues

- Don't duplicate instructions already in background skills — reference them instead ("see the git-conventions skill")
- Don't over-constrain — give Claude room to adapt to the specific context
- Test with realistic prompts: would a user actually say this? Would the skill trigger?
- Keep examples concrete and tied to your project's domain concepts
