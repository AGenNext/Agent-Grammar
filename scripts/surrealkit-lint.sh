#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v surrealkit >/dev/null 2>&1; then
  echo "surrealkit is required. Install it before running this script." >&2
  exit 1
fi

surrealkit lint "$ROOT_DIR/surrealkit/creativework-grammar.surql"
