#!/usr/bin/env bash
set -euo pipefail
: "${ARTIFACTS_DIR:?ARTIFACTS_DIR is required}"
[[ $# -eq 1 ]] || { echo "usage: $0 <dimension>" >&2; exit 2; }
DIMENSION=$1
case "$DIMENSION" in correctness|quality|maintainability|security|contract) ;; *) echo "invalid dimension: $DIMENSION" >&2; exit 2 ;; esac
mkdir -p -- "$ARTIFACTS_DIR"
RESULT_FILE="$ARTIFACTS_DIR/${DIMENSION}_critique_result.json"
INPUT=$(cat)
jq -e '
  type == "object" and (.comments | type == "array") and
  (all(.comments[]; type == "object" and (.file | type == "string" and length > 0) and (.line | type == "number" and floor == . and . >= 1) and (.message | type == "string" and length > 0) and (.severity | IN("info", "warning", "error")))) and
  (.summary | type == "string") and (.justification | type == "string") and
  (if (.comments | length) == 0 then (.justification | length > 0) else (.justification | length == 0) end)
' <<<"$INPUT" >/dev/null
TMP=$(mktemp "$ARTIFACTS_DIR/.critique.XXXXXX")
trap 'rm -f -- "$TMP"' EXIT
jq -S '{max_severity: ([.comments[].severity] | if any(. == "error") then "error" elif any(. == "warning") then "warning" elif any(. == "info") then "info" else "none" end), comment_count: (.comments | length), summary, justification, comments: .comments}' <<<"$INPUT" >"$TMP"
mv -f -- "$TMP" "$RESULT_FILE"
trap - EXIT
printf '[%s] persisted %s\n' "$DIMENSION" "$RESULT_FILE"
