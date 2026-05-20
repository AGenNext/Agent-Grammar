#!/usr/bin/env python3
"""Validate the SurrealKit-managed grammar source is present and contains required DB-level functions."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "surrealkit" / "creativework-grammar.surql"
REQUIRED_SNIPPETS = [
    "DEFINE TABLE grammar_validation_report SCHEMAFULL",
    "fn::grammar::action::validate",
    "fn::grammar::creativework::validate",
    "fn::grammar::creativework::report",
]


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def main() -> None:
    if not SOURCE.exists():
        fail(f"missing {SOURCE.relative_to(ROOT)}")

    text = SOURCE.read_text(encoding="utf-8")
    for snippet in REQUIRED_SNIPPETS:
        if snippet not in text:
            fail(f"{SOURCE.relative_to(ROOT)} missing required snippet: {snippet}")

    print(f"ok: {SOURCE.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
