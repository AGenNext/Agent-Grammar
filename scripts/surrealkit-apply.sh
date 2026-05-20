#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v surrealkit >/dev/null 2>&1; then
  echo "surrealkit is required. Install it before running this script." >&2
  exit 1
fi

if [[ -z "${SURREAL_URL:-}" ]]; then
  echo "SURREAL_URL is required" >&2
  exit 1
fi

if [[ -z "${SURREAL_NAMESPACE:-}" ]]; then
  echo "SURREAL_NAMESPACE is required" >&2
  exit 1
fi

if [[ -z "${SURREAL_DATABASE:-}" ]]; then
  echo "SURREAL_DATABASE is required" >&2
  exit 1
fi

surrealkit apply \
  --url "$SURREAL_URL" \
  --namespace "$SURREAL_NAMESPACE" \
  --database "$SURREAL_DATABASE" \
  "$ROOT_DIR/surrealkit/creativework-grammar.surql"
