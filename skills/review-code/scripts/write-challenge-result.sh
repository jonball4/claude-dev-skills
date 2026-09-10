#!/usr/bin/env bash
set -euo pipefail
: "${ARTIFACTS_DIR:?ARTIFACTS_DIR is required}"
RAW="$ARTIFACTS_DIR/critique_result.json"
[[ -f "$RAW" ]] || { echo "missing critique_result.json" >&2; exit 1; }
IFS=',' read -r -a SELECTED <<< "${REVIEW_DIMENSIONS:-correctness,quality,maintainability,security,contract}"
ALLOWED_JSON=$(printf '%s\n' "${SELECTED[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')
INPUT=$(cat)
jq -e --argjson allowed "$ALLOWED_JSON" 'type == "object" and (.downgrades | type == "array") and (.blind_spots | type == "array") and (.empty_critique_flags | type == "array") and (.summary | type == "string") and (all(.downgrades[]; type == "object" and (.dimension | IN($allowed[])) and (.action | IN("remove","downgrade")) and (.original_file | type == "string" and length > 0) and (.original_line | type == "number" and floor == . and . >= 1) and (.reason | type == "string" and length > 0) and (.action != "downgrade" or (.downgrade_to | IN("info","warning","error")))))' <<<"$INPUT" >/dev/null
jq -e --argjson allowed "$ALLOWED_JSON" --slurpfile raw "$RAW" 'all(.downgrades[]; . as $d | any($raw[0].comments[]; .dimension == $d.dimension and .file == $d.original_file and .line == $d.original_line))' <<<"$INPUT" >/dev/null
TMP=$(mktemp "$ARTIFACTS_DIR/.challenge.XXXXXX"); trap 'rm -f -- "$TMP"' EXIT
jq --argjson selected "$ALLOWED_JSON" '{selected_dimensions: $selected, downgrades, blind_spots, empty_critique_flags, summary}' <<<"$INPUT" >"$TMP"
mv -f -- "$TMP" "$ARTIFACTS_DIR/challenge_result.json"
TMP=$(mktemp "$ARTIFACTS_DIR/.refined.XXXXXX"); trap 'rm -f -- "$TMP"' EXIT
jq --argjson selected "$ALLOWED_JSON" --slurpfile raw "$RAW" '
  . as $challenge |
  ($raw[0].comments | map(
    . as $comment |
    if any($challenge.downgrades[]; .action == "remove" and .dimension == $comment.dimension and .original_file == $comment.file and .original_line == $comment.line) then empty
    else ([$challenge.downgrades[] | select(.action == "downgrade" and .dimension == $comment.dimension and .original_file == $comment.file and .original_line == $comment.line) | .downgrade_to][0] // $comment.severity) as $severity | $comment | .severity = $severity
    end
  )) as $comments |
  {max_severity: ([$comments[].severity] | if any(. == "error") then "error" elif any(. == "warning") then "warning" elif any(. == "info") then "info" else "none" end), comment_count: ($comments | length), selected_dimensions: $selected, dimensions: $raw[0].dimensions, challenge_summary: $challenge.summary, comments: $comments, removals: [$challenge.downgrades[] | select(.action == "remove")], downgrades_applied: [$challenge.downgrades[] | select(.action == "downgrade")], blind_spots: $challenge.blind_spots, empty_critique_flags: $challenge.empty_critique_flags}
' <<<"$INPUT" >"$TMP"
mv -f -- "$TMP" "$ARTIFACTS_DIR/refined_critique_result.json"
trap - EXIT
printf 'Challenge complete: %s findings across dimensions=%s\n' "$(jq -r .comment_count "$ARTIFACTS_DIR/refined_critique_result.json")" "$(IFS=,; echo "${SELECTED[*]}")"
