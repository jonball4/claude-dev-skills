#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
"$ROOT_DIR/tests/review/test-review-scripts.sh"
"$ROOT_DIR/tests/contracts/test-context-and-state.sh"
"$ROOT_DIR/tests/install/test-bootstrap.sh"
printf 'All deterministic workflow tests passed\n'
