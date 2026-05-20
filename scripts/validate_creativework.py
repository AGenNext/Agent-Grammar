#!/usr/bin/env python3
"""Validate AGenNext CreativeWork artifacts against Agent-Grammar JSON Schemas.

Usage:
  python scripts/validate_creativework.py --path examples/valid/prompt.jsonld
  python scripts/validate_creativework.py --all
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
BASE_SCHEMA = ROOT / "rules" / "json-schema" / "creativework" / "base.schema.json"
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


def validate_base(path: Path) -> None:
    data = load_json(path)

    if data.get("@context") != "https://schema.org":
        fail(f"{path}: @context must be https://schema.org")

    if data.get("@type") != "CreativeWork":
        fail(f"{path}: @type must be CreativeWork")

    name = data.get("name")
    if not isinstance(name, str) or not name.strip():
        fail(f"{path}: name is required")

    if "potentialAction" in data:
        action = data["potentialAction"]
        actions = action if isinstance(action, list) else [action]
        if not actions:
            fail(f"{path}: potentialAction cannot be empty")
        for index, item in enumerate(actions):
            if not isinstance(item, dict):
                fail(f"{path}: potentialAction[{index}] must be an object")
            if item.get("@type") != "Action":
                fail(f"{path}: potentialAction[{index}].@type must be Action")
            action_name = item.get("name")
            if not isinstance(action_name, str) or not action_name.strip():
                fail(f"{path}: potentialAction[{index}].name is required")


def iter_jsonld_files() -> list[Path]:
    if not EXAMPLES.exists():
        return []
    return sorted(EXAMPLES.rglob("*.jsonld"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", type=Path)
    parser.add_argument("--all", action="store_true")
    args = parser.parse_args()

    if not BASE_SCHEMA.exists():
        fail(f"missing schema: {BASE_SCHEMA.relative_to(ROOT)}")

    if args.path:
        validate_base(ROOT / args.path if not args.path.is_absolute() else args.path)
        print(f"ok: {args.path}")
        return

    if args.all:
        files = iter_jsonld_files()
        if not files:
            print("ok: no examples found")
            return
        for path in files:
            validate_base(path)
            print(f"ok: {path.relative_to(ROOT)}")
        return

    parser.print_help()


if __name__ == "__main__":
    main()
