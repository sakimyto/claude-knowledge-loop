---
name: knowledge-loop
description: "Extract domain knowledge from your notes and feed it back into CLAUDE.md. Not AI tips — your design principles, business rules, technical decisions, and quality criteria."
---

# Knowledge Loop

Extract domain knowledge from notes and update `knowledge-base.md` + CLAUDE.md automatically.

**Core principle**: Extract knowledge that remains valuable regardless of how smart the model becomes. If the model were 10x smarter, would it still need this information? If yes, extract it.

## Execution Flow

### 1. Load Config

Read `~/.claude/knowledge-loop.json`. If missing, instruct the user to run `setup.sh` first.

```json
{
  "source": {
    "directory": "~/notes",
    "pattern": "*.md",
    "date_field": "filename",
    "date_format": "YYYYMMDD_*"
  },
  "output": {
    "knowledge_base": "~/.claude/docs/knowledge-base.md",
    "claude_md": "~/.claude/CLAUDE.md",
    "claude_md_section": "Domain Knowledge (auto-updated)",
    "max_claude_md_lines": 8,
    "max_items_per_category": 8
  },
  "categories": [
    "design-principles",
    "business-rules",
    "technical-decisions",
    "quality-criteria"
  ],
  "language": "en",
  "search_keywords": []
}
```

Expand `~` in all paths to the actual home directory.

### 2. Detect New Notes

Find notes modified since the last update.

- Read the `knowledge-base.md` header for `last_updated` date
- If `knowledge-base.md` doesn't exist, process all notes
- Filter notes by the configured `date_format` pattern (e.g., `YYYYMMDD_*`)
- Only process notes whose date (from filename) is after the last update

### 3. Extract Domain Knowledge

Read each new note and extract knowledge that matches the configured categories.

**Default categories:**

| Category | What to extract |
|----------|----------------|
| `design-principles` | Why this design was chosen. Architecture rationale. Trade-off decisions. |
| `business-rules` | Industry/domain-specific rules. Constraints from business context. |
| `technical-decisions` | Technology choices and their reasons (ADR-like). Migration decisions. |
| `quality-criteria` | Personal quality standards. Definition of "done". Review criteria. |

**Extraction litmus test**: "If the model were 10x smarter, would I still need to tell it this?" → Yes = extract.

**Anti-patterns (DO NOT extract):**

- AI/LLM usage tips (model-dependent, will become obsolete)
- Tool-specific shortcuts or keybindings
- One-time events or meeting notes
- Generic industry knowledge the model already knows
- Subjective opinions without actionable implications

**Language**: Use the language specified in config (`language` field).

**If `search_keywords` is configured** (non-empty array): Only scan notes containing at least one keyword. If empty, scan all new notes.

### 4. Deduplicate

Read existing `knowledge-base.md` and check for duplicates:

- **Duplicate** → Skip
- **Refinement of existing item** → Update the existing entry
- **Genuinely new** → Add to appropriate category

### 5. Update knowledge-base.md

Write/update the knowledge base file at the configured `output.knowledge_base` path:

```markdown
# Domain Knowledge Base

last_updated: YYYY-MM-DD

---

## Design Principles

- **Principle name** — Description of the principle and why it matters
- ...

## Business Rules

- **Rule name** — Description and context
- ...

## Technical Decisions

- **Decision** — What was decided and why (date if known)
- ...

## Quality Criteria

- **Criterion** — What "good" looks like for this aspect
- ...
```

Rules:
- Keep each category at or under `max_items_per_category` entries
- When exceeding the limit, merge or remove the least specific/impactful items
- Each entry is one line: `- **Bold keyword** — Explanation`
- Section headers match the `categories` config, converted to Title Case with hyphens replaced by spaces

### 6. Update CLAUDE.md

Update the auto-managed section in the configured `claude_md` path.

**Section markers:**

```markdown
<!-- knowledge-loop:start -->
## Domain Knowledge (auto-updated)

- Most impactful items here (max 8 lines)
- See `docs/knowledge-base.md` for full list

<!-- knowledge-loop:end -->
```

Rules:
- If markers exist, replace content between them
- If markers don't exist, append the section at the end of the file
- Use the section name from `claude_md_section` config
- Limit to `max_claude_md_lines` lines (default 8)
- Select the highest-impact items across all categories
- Always include a reference to the full knowledge base file

### 7. Report

Report to the user:

- Number of notes scanned
- New entries added (with category breakdown)
- Entries updated
- Duplicates skipped
- Any items removed due to category limits

## Custom Categories

Users can add custom categories in `knowledge-loop.json`:

```json
{
  "categories": [
    "design-principles",
    "business-rules",
    "technical-decisions",
    "quality-criteria",
    "customer-insights",
    "compliance-requirements"
  ]
}
```

Each category will become a section in `knowledge-base.md`.

## Notes

- This skill does NOT search the web or check for model/tool updates
- This skill extracts **human domain knowledge**, not AI usage patterns
- Run daily or when you've written notes with significant decisions/learnings
- The skill is language-aware: set `language` in config to match your notes
