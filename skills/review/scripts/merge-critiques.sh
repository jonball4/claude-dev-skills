#!/usr/bin/env bash
set -euo pipefail
: "${ARTIFACTS_DIR:?ARTIFACTS_DIR is required}"

readonly ALL=(correctness quality maintainability security contract)
IFS=',' read -r -a SELECTED <<< "${REVIEW_DIMENSIONS:-correctness,quality,maintainability,security,contract}"
[[ "${#SELECTED[@]}" -gt 0 ]] || { echo 'REVIEW_DIMENSIONS must not be empty' >&2; exit 1; }

contains() {
  local needle="$1"
  shift
  local value
  for value in "$@"; do [[ "$value" == "$needle" ]] && return 0; done
  return 1
}

for dim in "${SELECTED[@]}"; do
  contains "$dim" "${ALL[@]}" || { echo "invalid review dimension: $dim" >&2; exit 1; }
done
for ((i = 0; i < ${#SELECTED[@]}; i++)); do
  for ((j = i + 1; j < ${#SELECTED[@]}; j++)); do
    [[ "${SELECTED[$i]}" != "${SELECTED[$j]}" ]] || { echo "duplicate review dimension: ${SELECTED[$i]}" >&2; exit 1; }
  done
done

mkdir -p -- "$ARTIFACTS_DIR"
readonly RESULT_SCHEMA='def severity: if any(. == "error") then "error" elif any(. == "warning") then "warning" elif any(. == "info") then "info" else "none" end; type == "object" and (.max_severity | IN("none", "info", "warning", "error")) and (.comment_count | type == "number" and floor == . and . >= 0) and (.comments | type == "array") and (.comment_count == (.comments | length)) and (all(.comments[]; type == "object" and (.file | type == "string" and length > 0) and (.line | type == "number" and floor == . and . >= 1) and (.message | type == "string" and length > 0) and (.severity | IN("info","warning","error")))) and (.max_severity == ([.comments[].severity] | severity))'

DIM_JSON=$(printf '%s\n' "${SELECTED[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')
for dim in "${SELECTED[@]}"; do
  file="$ARTIFACTS_DIR/${dim}_critique_result.json"
  [[ -f "$file" ]] || { echo "missing critique result: $file" >&2; exit 1; }
  jq -e "$RESULT_SCHEMA" "$file" >/dev/null || { echo "invalid critique result: $file" >&2; exit 1; }
done

shopt -s nullglob
for file in "$ARTIFACTS_DIR"/*_critique_result.json; do
  dim=$(basename "$file" _critique_result.json)
  contains "$dim" "${SELECTED[@]}" || { echo "unexpected critique dimension: $dim" >&2; exit 1; }
done
shopt -u nullglob

DIM_RESULTS='[]'
for dim in "${SELECTED[@]}"; do
  result=$(jq --arg dimension "$dim" '. + {dimension: $dimension}' "$ARTIFACTS_DIR/${dim}_critique_result.json")
  DIM_RESULTS=$(jq -n --argjson current "$DIM_RESULTS" --argjson result "$result" '$current + [$result]')
done
MAX_SEVERITY=$(jq -r '[.[].max_severity] | if any(. == "error") then "error" elif any(. == "warning") then "warning" elif any(. == "info") then "info" else "none" end' <<<"$DIM_RESULTS")
TOTAL=$(jq '[.[].comment_count] | add' <<<"$DIM_RESULTS")
ALL_COMMENTS=$(jq '[.[] as $d | $d.comments[] | . + {dimension: $d.dimension}]' <<<"$DIM_RESULTS")
TMP=$(mktemp "$ARTIFACTS_DIR/.critique-result.XXXXXX"); trap 'rm -f -- "$TMP"' EXIT
jq -n --arg max_severity "$MAX_SEVERITY" --argjson comment_count "$TOTAL" --argjson dimensions "$DIM_RESULTS" --argjson comments "$ALL_COMMENTS" --argjson selected "$DIM_JSON" '{max_severity: $max_severity, comment_count: $comment_count, selected_dimensions: $selected, dimensions: $dimensions, comments: $comments}' >"$TMP"
mv -f -- "$TMP" "$ARTIFACTS_DIR/critique_result.json"
trap - EXIT
printf 'Merged: dimensions=%s severity=%s, total_comments=%s\n' "$(IFS=,; echo "${SELECTED[*]}")" "$MAX_SEVERITY" "$TOTAL"
