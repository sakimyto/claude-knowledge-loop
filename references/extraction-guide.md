# Extraction Guide

How to identify and extract domain knowledge from notes.

## The Litmus Tests

Every extraction candidate must pass **both** tests:

> **Test 1**: "If the model were 10x smarter, would I still need to tell it this?"
>
> **Test 2**: "Could the model figure this out by reading the codebase?"

- Test 1 = Yes **AND** Test 2 = No → **Extract it.** This is domain knowledge.
- Either test fails → **Skip it.**

Test 1 filters out model-dependent tips. Test 2 filters out knowledge that's already encoded in code.

## Default Categories

### design-principles

**What**: Architectural decisions, design trade-offs, and the reasoning behind them.

**Extract when you see**:
- "We chose X over Y because..."
- "The trade-off here is..."
- "This pattern works better for our case because..."
- Recurring design preferences across multiple decisions

**Examples**:
- **Schema-first development** — Get the data model right first; UI can be regenerated cheaply
- **Eventual consistency over strong consistency** — Our domain tolerates 5-second delays; availability matters more
- **Monorepo for shared types** — Type drift between services caused 3 production bugs; shared types prevent this

**Not this**:
- "React is a good framework" (generic knowledge)
- "We use TypeScript" (trivially observable from code)
- "We prefer composition over inheritance" (inferable from reading the codebase)

---

### business-rules

**What**: Industry-specific rules, regulatory constraints, domain-specific logic that isn't in code.

**Extract when you see**:
- Domain-specific terminology with specific meanings
- "In our industry, X means..."
- Compliance requirements or legal constraints
- Business logic that seems arbitrary but has a reason

**Examples**:
- **90-day return window** — Industry standard for our product category; extending to 120 days reduced support tickets by 40%
- **Tax calculation order** — Must apply prefecture tax before national tax; reversing causes 0.01% rounding errors that compound
- **Content approval SLA** — Brand content requires 48h review minimum; automated posting is prohibited by platform ToS

**Not this**:
- "Customers prefer fast delivery" (obvious)
- "Revenue should grow" (not actionable)

---

### technical-decisions

**What**: Technology choices with their rationale. Think lightweight ADRs (Architecture Decision Records).

**Extract when you see**:
- "We migrated from X to Y because..."
- "We picked X over Y, Z because..."
- Version pinning decisions
- Infrastructure choices and their reasons

**Examples**:
- **Bun over Node** — 3x faster script execution, native TypeScript support; switched 2025-06 after Bun 1.2 stabilized
- **SQLite for local-first** — Eliminated network dependency for offline use; sync via cr-sqlite for multi-device
- **No ORM** — Query builder (Kysely) gives us type safety without hiding SQL; team has strong SQL skills

**Not this**:
- "PostgreSQL is a relational database" (general knowledge)
- "We use Git for version control" (universal practice)

---

### quality-criteria

**What**: Personal or team standards for what "good" looks like. Definition of done. Review criteria.

**Extract when you see**:
- "I always check for..."
- "This isn't done until..."
- Recurring feedback patterns in reviews
- Quality gates or checklists

**Examples**:
- **No dead code** — Remove unused functions/imports immediately; commented-out code is not documentation
- **Error messages must be actionable** — Include what went wrong AND what the user should do next
- **Tests as specification** — Tests should read as documentation; if the test name needs comments, rename it

**Not this**:
- "Code should be clean" (too vague)
- "Always write tests" (generic best practice)

## Custom Categories

Add categories to `knowledge-loop.json` that match your domain:

```json
{
  "categories": [
    "design-principles",
    "business-rules",
    "technical-decisions",
    "quality-criteria",
    "customer-insights",
    "compliance-requirements",
    "operational-runbook"
  ]
}
```

Each custom category should follow the same pattern:
1. Clear scope (what belongs here)
2. Extraction triggers (phrases that signal extractable knowledge)
3. Concrete examples
4. Anti-patterns (what doesn't belong)

**Cross-category knowledge**: If an item fits multiple categories, place it in the single best-fit category. Don't duplicate.

## Anti-Patterns: What NOT to Extract

| Don't extract | Why |
|--------------|-----|
| AI/LLM usage tips | Model-dependent; obsolete when models improve |
| Tool shortcuts/keybindings | Tool-specific; look up when needed |
| One-time events | Not reusable knowledge |
| Meeting notes verbatim | Extract decisions only, not the discussion |
| Generic best practices | The model already knows these |
| Temporary workarounds | Should be fixed, not documented as knowledge |
| Personal opinions without evidence | Not actionable for an LLM |
| Patterns inferable from codebase | The model can discover these by reading code |

## Writing Good Entries

**Format**: `- **Bold keyword** — Concise explanation with context`

**Good**:
- Specific and actionable
- Includes the "why" not just the "what"
- One line, self-contained
- Would help someone (or an LLM) make the right decision

**Bad**:
- Vague or generic
- Missing context or rationale
- Multi-paragraph explanations (put those in docs instead)
- Duplicates something the model would know from reading the codebase

## Quarterly Review

Every 90 days, review your `knowledge-base.md`:

1. **Remove stale entries** — Decisions that were reversed, rules that changed, tools that were replaced
2. **Remove now-inferable entries** — If the codebase now clearly shows a pattern, the explicit entry may be redundant
3. **Merge converged entries** — Multiple entries that evolved into a single principle
4. **Update rationale** — If the "why" has changed even though the "what" hasn't

Stale knowledge is worse than no knowledge — it actively misleads the model.
