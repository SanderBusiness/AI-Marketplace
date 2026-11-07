#!/bin/zsh
# Open a new macOS Terminal.app window with an interactive Claude Code session (auto mode) for ONE GitHub issue.
# Usage: launch-terminal.sh <issue-number[,issue-number...]> <repo-dir> <work-dir> [model]
#   work-dir: scratch directory for the prompt and the done-marker (created if missing)
# The session touches <work-dir>/done-<issue> as its very last step.
set -eu
N="$1"; REPO="$2"; WORK="$3"; MODEL="${4:-sonnet}"
mkdir -p "$WORK"
SAFE="${N//,/-}"; MARKER="$WORK/done-$SAFE"
PROMPT="$WORK/prompt-$SAFE.txt"
rm -f "$MARKER"

cat > "$PROMPT" <<PROMPT_EOF
Work on GitHub issue(s) #$N of this repo (read each with: gh issue view <n> --comments). If several are listed they belong together: write a short shared design first, then implement all against it, one commit per issue. You know nothing about other issues outside this group.

Follow the repo's CLAUDE.md and project skills strictly (translations, legal texts, tests, lint, typecheck, whatever it demands). Build on existing local commits if they touch the same area (git log -10). If the issue turns out to be already done, change nothing and say so.

Rules: do NOT push. Do NOT mutate production data (reading is fine, never print credentials). Commit locally with a clear message and the commit attribution lines your own system context asks for. If something needs a product decision from the owner, ask it here in this terminal; the owner is watching and will answer.

When finished, give a short summary (status, what changed with path:line, tests, open questions), then as your very last step run: touch $MARKER
PROMPT_EOF

CMD="cd '$REPO' && claude --permission-mode auto --model $MODEL \"\$(cat '$PROMPT')\""
ESC=$(printf '%s' "$CMD" | sed 's/\\/\\\\/g; s/"/\\"/g')
osascript -e 'tell application "Terminal"' -e 'activate' -e "do script \"$ESC\"" -e 'end tell' >/dev/null
echo "launched #$N, marker: $MARKER"
