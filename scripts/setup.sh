#!/bin/bash
# claude-knowledge-loop setup script
# Generates ~/.claude/knowledge-loop.json and a SessionStart hook

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
CONFIG_FILE="$CLAUDE_DIR/knowledge-loop.json"
DOCS_DIR="$CLAUDE_DIR/docs"
HOOK_DIR=""  # Will be set during setup

echo "=== claude-knowledge-loop setup ==="
echo ""

# 1. Ask for notes directory
read -rp "Where are your notes? (absolute path): " NOTES_DIR
NOTES_DIR="${NOTES_DIR/#\~/$HOME}"

if [ ! -d "$NOTES_DIR" ]; then
  echo "Error: Directory '$NOTES_DIR' does not exist."
  exit 1
fi

# 2. Ask for filename pattern
echo ""
echo "How are your note files named?"
echo "  1) YYYYMMDD_title.md (e.g., 20260221_design-review.md)"
echo "  2) YYYY-MM-DD_title.md (e.g., 2026-02-21_design-review.md)"
echo "  3) Other pattern"
read -rp "Choose [1/2/3]: " PATTERN_CHOICE

case "$PATTERN_CHOICE" in
  1) DATE_FORMAT="YYYYMMDD_*" ;;
  2) DATE_FORMAT="YYYY-MM-DD_*" ;;
  3) read -rp "Enter your date format pattern: " DATE_FORMAT ;;
  *) DATE_FORMAT="YYYYMMDD_*" ;;
esac

# 3. Ask for language
echo ""
read -rp "Language for extracted knowledge (en/ja/etc.) [en]: " LANGUAGE
LANGUAGE="${LANGUAGE:-en}"

# 4. Ask for search keywords (optional)
echo ""
echo "Optional: Enter search keywords to filter notes (comma-separated)."
echo "Leave empty to scan all notes."
read -rp "Keywords: " KEYWORDS_RAW

KEYWORDS="[]"
if [ -n "$KEYWORDS_RAW" ]; then
  KEYWORDS=$(echo "$KEYWORDS_RAW" | awk -F',' '{
    printf "["
    for (i=1; i<=NF; i++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      if (i > 1) printf ", "
      printf "\"%s\"", $i
    }
    printf "]"
  }')
fi

# 5. Ask for hook location (project-level)
echo ""
echo "Where should the SessionStart hook be installed?"
echo "This should be your project's .claude/hooks/ directory."
read -rp "Hook directory (e.g., /path/to/project/.claude/hooks) [skip]: " HOOK_DIR

# 6. Create config
mkdir -p "$DOCS_DIR"

cat > "$CONFIG_FILE" << JSONEOF
{
  "source": {
    "directory": "${NOTES_DIR/#$HOME/\~}",
    "pattern": "*.md",
    "date_field": "filename",
    "date_format": "$DATE_FORMAT"
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
  "language": "$LANGUAGE",
  "search_keywords": $KEYWORDS
}
JSONEOF

echo ""
echo "Created: $CONFIG_FILE"

# 7. Create hook if requested
if [ -n "$HOOK_DIR" ] && [ "$HOOK_DIR" != "skip" ]; then
  HOOK_DIR="${HOOK_DIR/#\~/$HOME}"
  mkdir -p "$HOOK_DIR"

  HOOK_FILE="$HOOK_DIR/knowledge-loop-check.sh"
  cat > "$HOOK_FILE" << 'HOOKEOF'
#!/bin/bash
# SessionStart hook: check if knowledge-base.md was updated today

KB_FILE="$HOME/.claude/docs/knowledge-base.md"
TODAY=$(date +%Y-%m-%d)

if [ ! -f "$KB_FILE" ]; then
  echo "[knowledge-loop] knowledge-base.md does not exist. Run /knowledge-loop to initialize."
  exit 0
fi

LAST_UPDATE=$(grep 'last_updated:' "$KB_FILE" | head -1 | sed 's/last_updated: //')

if [ "$LAST_UPDATE" != "$TODAY" ]; then
  echo "[knowledge-loop] Domain knowledge is not synced today (last: ${LAST_UPDATE:-unknown}). Run /knowledge-loop during this session."
fi
HOOKEOF

  chmod +x "$HOOK_FILE"
  echo "Created: $HOOK_FILE"
fi

# 8. Show next steps
echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo ""
echo "1. Install the skill to your project:"
echo "   cp -r /path/to/claude-knowledge-loop/SKILL.md your-project/.claude/skills/knowledge-loop/SKILL.md"
echo ""

if [ -n "$HOOK_DIR" ] && [ "$HOOK_DIR" != "skip" ]; then
  echo "2. Add the hook to your project's .claude/settings.local.json:"
  echo '   {
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
   }'
  echo ""
  echo "3. Run /knowledge-loop in Claude Code to extract your first batch of domain knowledge."
else
  echo "2. Run /knowledge-loop in Claude Code to extract your first batch of domain knowledge."
fi
echo ""
echo "Config: $CONFIG_FILE"
echo "Edit this file to customize categories, keywords, and output paths."
