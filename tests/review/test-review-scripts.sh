#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
MERGE="$ROOT_DIR/skills/review-code/scripts/merge-critiques.sh"
WRITE="$ROOT_DIR/skills/review-code/scripts/write-critique-result.sh"
CHALLENGE="$ROOT_DIR/skills/review-code/scripts/write-challenge-result.sh"
VALIDATE="$ROOT_DIR/skills/review-code/scripts/validate-review-artifacts.sh"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

expect_fail() {
  if "$@" >/dev/null 2>&1; then
    echo "expected failure but command passed: $*" >&2
    exit 1
  fi
}

write_empty() {
  local dimension=$1
  printf '%s\n' '{"comments":[],"justification":"No issues found.","summary":"Clean review."}' |
    ARTIFACTS_DIR="$TMP_DIR" "$WRITE" "$dimension" >/dev/null
}

write_empty correctness
write_empty contract
REVIEW_DIMENSIONS=correctness,contract ARTIFACTS_DIR="$TMP_DIR" "$MERGE" >/dev/null
printf '%s\n' '{"downgrades":[],"blind_spots":[],"empty_critique_flags":[],"summary":"No critique changes."}' |
  REVIEW_DIMENSIONS=correctness,contract ARTIFACTS_DIR="$TMP_DIR" "$CHALLENGE" >/dev/null
REVIEW_DIMENSIONS=correctness,contract ARTIFACTS_DIR="$TMP_DIR" "$VALIDATE" >/dev/null

printf '%s\n' '{"comments":[{"file":"src/example.ts","line":4,"message":"Boundary is untested.","severity":"warning"}],"justification":"","summary":"One finding."}' |
  ARTIFACTS_DIR="$TMP_DIR" "$WRITE" correctness >/dev/null
REVIEW_DIMENSIONS=correctness,contract ARTIFACTS_DIR="$TMP_DIR" "$MERGE" >/dev/null
printf '%s\n' '{"downgrades":[{"dimension":"correctness","original_file":"src/example.ts","original_line":4,"reason":"Evidence shows this is advisory.","action":"downgrade","downgrade_to":"info"}],"blind_spots":[],"empty_critique_flags":[],"summary":"Downgraded one finding."}' |
  REVIEW_DIMENSIONS=correctness,contract ARTIFACTS_DIR="$TMP_DIR" "$CHALLENGE" >/dev/null
REVIEW_DIMENSIONS=correctness,contract ARTIFACTS_DIR="$TMP_DIR" "$VALIDATE" >/dev/null
[[ "$(jq -r '.comments[0].severity' "$TMP_DIR/refined_critique_result.json")" == info ]]

rm -f "$TMP_DIR/contract_critique_result.json"
expect_fail env REVIEW_DIMENSIONS=correctness,contract ARTIFACTS_DIR="$TMP_DIR" "$MERGE"
write_empty contract
printf '%s\n' '{"comments":[{"file":"x","line":1,"message":"extra","severity":"info"}],"justification":"","summary":"extra"}' |
  ARTIFACTS_DIR="$TMP_DIR" "$WRITE" quality >/dev/null
expect_fail env REVIEW_DIMENSIONS=correctness,contract ARTIFACTS_DIR="$TMP_DIR" "$MERGE"
rm -f "$TMP_DIR/quality_critique_result.json"
printf '%s\n' '{"comments":[{"file":"x","line":0,"message":"bad line","severity":"info"}],"justification":"","summary":"bad"}' |
  expect_fail env ARTIFACTS_DIR="$TMP_DIR" "$WRITE" correctness
printf '%s\n' '{"downgrades":[{"dimension":"correctness","original_file":"missing.ts","original_line":1,"reason":"not present","action":"remove"}],"blind_spots":[],"empty_critique_flags":[],"summary":"bad reference"}' |
  expect_fail env REVIEW_DIMENSIONS=correctness,contract ARTIFACTS_DIR="$TMP_DIR" "$CHALLENGE"

printf 'Review helper contract tests passed\n'
