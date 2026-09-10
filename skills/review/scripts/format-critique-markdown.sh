#!/usr/bin/env bash
set -euo pipefail
: "${ARTIFACTS_DIR:?ARTIFACTS_DIR is required}"
REFINED="$ARTIFACTS_DIR/refined_critique_result.json"
jq -e 'type == "object" and (.max_severity | IN("none","info","warning","error")) and (.comments | type == "array")' "$REFINED" >/dev/null
MAX_SEV=$(jq -r '.max_severity' "$REFINED")
TOTAL=$(jq -r '.comment_count' "$REFINED")
CHALLENGE_SUM=$(jq -r '.challenge_summary // empty' "$REFINED")
case "$MAX_SEV" in error) BADGE='**Error**';; warning) BADGE='**Warning**';; info) BADGE='**Info**';; *) BADGE='[OK] **Clean**';; esac
echo '## Automated Code Review'; echo; echo "**Overall:** $BADGE - $TOTAL finding(s)"; echo
for dim in correctness quality maintainability security contract; do
  dim_cap="$(printf '%s' "$dim" | cut -c1 | tr '[:lower:]' '[:upper:]')$(printf '%s' "$dim" | cut -c2-)"
  echo "### $dim_cap Review"; echo
  jq -r --arg dim "$dim" '.comments[] | select(.dimension == $dim) | "- **[\(.severity | ascii_upcase)]** `\(.file):\(.line)` - \(.message)"' "$REFINED"
  echo
done
if [[ -n "$CHALLENGE_SUM" ]]; then echo '### Challenge Review'; echo; echo "$CHALLENGE_SUM"; echo; fi
echo '---'; echo '*Generated from the canonical review artifact.*'
