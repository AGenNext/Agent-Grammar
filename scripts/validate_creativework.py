#!/usr/bin/env python3
"""Validate AGenNext artifacts against Agent-Grammar rules.

The validator is grounded in Schema.org:
- @context must be https://schema.org
- @type must match the allowed Schema.org type for artifactKind
- artifactKind is AGenNext routing metadata only
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_DIR = ROOT / "rules" / "json-schema" / "creativework"
TYPE_MAP = ROOT / "rules" / "schemaorg" / "artifact-kind-types.json"
EXAMPLES = ROOT / "examples"


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"{path}: invalid JSON: {exc}")
    if not isinstance(data, dict):
        fail(f"{path}: root must be an object")
    return data


def load_type_map() -> dict[str, list[str]]:
    data = load_json(TYPE_MAP)
    result: dict[str, list[str]] = {}
    for key, value in data.items():
        if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
            fail(f"{TYPE_MAP}: {key} must map to a list of Schema.org type names")
        result[key] = value
    return result


def validate_action(path: Path, action: object, index: int) -> None:
    if not isinstance(action, dict):
        fail(f"{path}: potentialAction[{index}] must be an object")
    if action.get("@type") != "Action":
        fail(f"{path}: potentialAction[{index}].@type must be Action")
    action_name = action.get("name")
    if not isinstance(action_name, str) or not action_name.strip():
        fail(f"{path}: potentialAction[{index}].name is required")


def validate_artifact(path: Path) -> None:
    data = load_json(path)
    type_map = load_type_map()

    if data.get("@context") != "https://schema.org":
        fail(f"{path}: @context must be https://schema.org")

    artifact_kind = data.get("artifactKind")
    if not isinstance(artifact_kind, str) or not artifact_kind:
        fail(f"{path}: artifactKind is required")

    allowed_types = type_map.get(artifact_kind)
    if not allowed_types:
        fail(f"{path}: unknown artifactKind {artifact_kind}")

    schema_path = SCHEMA_DIR / f"{artifact_kind}.schema.json"
    if not schema_path.exists():
        fail(f"{path}: missing grammar schema {schema_path.relative_to(ROOT)}")

    schema_type = data.get("@type")
    if schema_type not in allowed_types:
        fail(
            f"{path}: @type {schema_type!r} is invalid for artifactKind {artifact_kind}; "
            f"allowed: {allowed_types}"
        )

    name = data.get("name")
    if not isinstance(name, str) or not name.strip():
        fail(f"{path}: name is required")

    if "potentialAction" in data:
        action = data["potentialAction"]
        actions = action if isinstance(action, list) else [action]
        if not actions:
            fail(f"{path}: potentialAction cannot be empty")
        for index, item in enumerate(actions):
            validate_action(path, item, index)


def iter_jsonld_files() -> list[Path]:
    if not EXAMPLES.exists():
        return []
    return sorted(EXAMPLES.rglob("*.jsonld"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", type=Path)
    parser.add_argument("--all", action="store_true")
    args = parser.parse_args()

    if not TYPE_MAP.exists():
        fail(f"missing type map: {TYPE_MAP.relative_to(ROOT)}")

    if args.path:
        validate_artifact(ROOT / args.path if not args.path.is_absolute() else args.path)
        print(f"ok: {args.path}")
        return

    if args.all:
        files = iter_jsonld_files()
        if not files:
            print("ok: no examples found")
            return
        for path in files:
            validate_artifact(path)
            print(f"ok: {path.relative_to(ROOT)}")
        return

    parser.print_help()


if __name__ == "__main__":
    main()
