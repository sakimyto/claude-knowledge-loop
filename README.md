# claude-knowledge-loop

Extract domain knowledge from your notes and feed it back into Claude Code.

```
Your notes  ──→  Extract  ──→  knowledge-base.md  ──→  CLAUDE.md
    ↑                                                       │
    │                                                       ↓
    └──────────  You work  ←──────  Claude uses it  ←───────┘
```

## What This Is

A Claude Code skill that reads your notes, extracts **domain knowledge** (design principles, business rules, technical decisions, quality criteria), and writes it to `CLAUDE.md` so Claude can use it in every session.

Your head contains knowledge that no model can guess: why you chose this architecture, what your industry requires, what "good" means to you. This tool makes that knowledge explicit.

## What This Is NOT

- **Not AI tips** — "How to prompt better" becomes obsolete when models improve. Domain knowledge doesn't.
- **Not a RAG system** — This produces a curated, human-readable knowledge base, not vector embeddings.
- **Not automatic** — It extracts candidates; you review and refine.

## The Litmus Tests

Every candidate must pass **both**:

> **Test 1**: "If the model were 10x smarter, would I still need to tell it this?"
> **Test 2**: "Could the model figure this out by reading the codebase?"

- Test 1 = Yes **AND** Test 2 = No → Extract it.
- Either fails → Skip.

## Install

### 1. Clone

```bash
git clone https://github.com/sakimyto/claude-knowledge-loop.git
```

### 2. Run setup

```bash
cd claude-knowledge-loop
bash scripts/setup.sh
```

This creates `~/.claude/knowledge-loop.json` and optionally installs a SessionStart hook.

### 3. Copy the skill to your project

```bash
mkdir -p your-project/.claude/skills/knowledge-loop
cp SKILL.md your-project/.claude/skills/knowledge-loop/SKILL.md
```

### 4. (Optional) Add the SessionStart hook

Add to your project's `.claude/settings.local.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/knowledge-loop-check.sh"
          }
        ]
      }
    ]
  }
}
```

## Usage

In Claude Code:

```
/knowledge-loop
```

The skill will:
1. Read your config from `~/.claude/knowledge-loop.json`
2. Find notes modified since the last extraction
3. Extract domain knowledge into categories
4. Update `~/.claude/docs/knowledge-base.md`
5. Update the auto-managed section in `~/.claude/CLAUDE.md`
6. Report what was added/updated/skipped

## Config

`~/.claude/knowledge-loop.json`:

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
    "max_claude_md_lines": 5,
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

| Field | Description |
|-------|-------------|
| `source.directory` | Path to your notes directory |
| `source.pattern` | Glob pattern for note files |
| `source.date_format` | Filename date pattern for chronological filtering |
| `output.knowledge_base` | Full knowledge base output path |
| `output.claude_md` | CLAUDE.md to update |
| `output.claude_md_section` | Section header for auto-managed content |
| `output.max_claude_md_lines` | Max lines in CLAUDE.md section |
| `output.max_items_per_category` | Max entries per category in knowledge base |
| `categories` | Knowledge categories to extract |
| `language` | Language for extracted entries |
| `search_keywords` | Filter notes by keywords (empty = all notes) |

## Categories

### Default

| Category | Description |
|----------|-------------|
| `design-principles` | Why this design was chosen. Architecture rationale. |
| `business-rules` | Industry/domain-specific rules and constraints. |
| `technical-decisions` | Technology choices and their reasons (ADR-like). |
| `quality-criteria` | Personal quality standards. Definition of "done". |

### Custom

Add any categories that match your domain:

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

See [`references/extraction-guide.md`](references/extraction-guide.md) for detailed extraction criteria and examples.

## How It Works

```
┌─────────────────────────────────────────┐
│              Your Notes                 │
│  20260221_api-redesign.md               │
│  20260220_pricing-meeting.md            │
│  ...                                    │
└──────────────┬──────────────────────────┘
               │ /knowledge-loop
               ▼
┌─────────────────────────────────────────┐
│         Extract & Categorize            │
│  "10x smarter model still needs this?"  │
│  "Inferable from codebase?"             │
│  Yes + No → extract  /  else → skip     │
└──────────────┬──────────────────────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
┌──────────────┐ ┌──────────────────────┐
│ knowledge-   │ │ ~/.claude/CLAUDE.md  │
│ base.md      │ │ (auto-managed        │
│ (full list)  │ │  section only)       │
└──────────────┘ └──────────────────────┘
```

## Maintenance

Review your `knowledge-base.md` every 90 days. The skill warns about stale entries during extraction. Stale knowledge actively misleads the model — prune ruthlessly.

## License

MIT
