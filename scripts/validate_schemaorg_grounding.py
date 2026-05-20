#!/usr/bin/env python3
"""Validate that Agent-Grammar artifact schemas stay grounded in Schema.org.

The rule is strict:
- artifactKind is AGenNext routing metadata only.
- @type must use the allowed native Schema.org type(s) for that artifactKind.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
MAPPING_PATH = ROOT / "rules" / "schemaorg" / "artifact-kind-types.json"
SCHEMA_DIR = ROOT / "rules" / "json-schema" / "creativework"


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"{path.relative_to(ROOT)} invalid JSON: {exc}")
    if not isinstance(data, dict):
        fail(f"{path.relative_to(ROOT)} root must be an object")
    return data


def find_const(obj: Any, key: str) -> str | None:
    if isinstance(obj, dict):
        if key in obj and isinstance(obj[key], dict):
            value = obj[key].get("const")
            if isinstance(value, str):
                return value
        for value in obj.values():
            found = find_const(value, key)
            if found:
                return found
    elif isinstance(obj, list):
        for item in obj:
            found = find_const(item, key)
            if found:
                return found
    return None


def find_allowed_types(obj: Any) -> set[str]:
    found: set[str] = set()
    if isinstance(obj, dict):
        type_rule = obj.get("@type")
        if isinstance(type_rule, dict):
            const_value = type_rule.get("const")
            enum_value = type_rule.get("enum")
            if isinstance(const_value, str):
                found.add(const_value)
            if isinstance(enum_value, list):
                found.update(item for item in enum_value if isinstance(item, str))
        for value in obj.values():
            found.update(find_allowed_types(value))
    elif isinstance(obj, list):
        for item in obj:
            found.update(find_allowed_types(item))
    return found


def main() -> None:
    mapping = load_json(MAPPING_PATH)

    for artifact_kind, allowed_types in mapping.items():
        if not isinstance(allowed_types, list) or not allowed_types:
            fail(f"mapping for {artifact_kind} must be a non-empty list")

        schema_path = SCHEMA_DIR / f"{artifact_kind}.schema.json"
        if not schema_path.exists():
            fail(f"missing schema for artifactKind {artifact_kind}: {schema_path.relative_to(ROOT)}")

        schema = load_json(schema_path)
        declared_kind = find_const(schema, "artifactKind")
        if declared_kind != artifact_kind:
            fail(f"{schema_path.relative_to(ROOT)} artifactKind must be {artifact_kind}")

        declared_types = find_allowed_types(schema)
        expected_types = set(allowed_types)
        if not declared_types:
            fail(f"{schema_path.relative_to(ROOT)} must declare allowed @type values")
        if not declared_types.issubset(expected_types):
            fail(
                f"{schema_path.relative_to(ROOT)} declares @type {sorted(declared_types)} "
                f"outside allowed schema.org types {sorted(expected_types)}"
            )

        print(f"ok: {artifact_kind} -> {sorted(declared_types)}")


if __name__ == "__main__":
    main()
