"""
__main__.py — CLI entry point for sync_contracts.

Usage:
  python -m tools.sync_contracts                   # regenerate all languages
  python -m tools.sync_contracts --lang dart rust  # specific languages only
  python -m tools.sync_contracts --dry-run         # preview without writing
  python -m tools.sync_contracts --check           # fail if generated files differ (CI mode)

Run from the repo root: c:\\horaizon-3.0
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Allow running as `python -m tools.sync_contracts` from repo root
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from tools.sync_contracts import parser as schema_parser
from tools.sync_contracts.generators.dart_gen       import DartGenerator
from tools.sync_contracts.generators.rust_gen       import RustGenerator
from tools.sync_contracts.generators.go_gen         import GoGenerator
from tools.sync_contracts.generators.typescript_gen import TypeScriptGenerator
from tools.sync_contracts.generators.python_gen     import PythonGenerator
from tools.sync_contracts.generators.base           import BaseGenerator

GENERATORS: dict[str, BaseGenerator] = {
    "dart":       DartGenerator(),
    "rust":       RustGenerator(),
    "go":         GoGenerator(),
    "typescript": TypeScriptGenerator(),
    "python":     PythonGenerator(),
}

REPO_ROOT = Path(__file__).parent.parent.parent  # c:\horaizon-3.0


def resolve_output_root(lang: str, schema_output: dict[str, str]) -> Path:
    """Resolve absolute output directory for a language."""
    rel = schema_output.get(lang, f"tools/sync_contracts/generated/{lang}")
    return REPO_ROOT / rel


def main() -> None:
    ap = argparse.ArgumentParser(
        description="sync_contracts — regenerate HBP v2 contracts across all languages"
    )
    ap.add_argument(
        "--lang",
        nargs="+",
        choices=list(GENERATORS.keys()),
        metavar="LANG",
        help=f"Languages to generate. Choices: {', '.join(GENERATORS)}. Default: all.",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be written without touching the filesystem.",
    )
    ap.add_argument(
        "--check",
        action="store_true",
        help=(
            "CI mode: fail with exit code 1 if any generated file differs "
            "from what is on disk (files are not written)."
        ),
    )
    ap.add_argument(
        "--schema",
        type=Path,
        default=None,
        help="Path to hbp_operations.toml. Defaults to tools/sync_contracts/schema/hbp_operations.toml.",
    )
    args = ap.parse_args()

    # Load schema
    schema_path = args.schema or (
        Path(__file__).parent / "schema" / "hbp_operations.toml"
    )
    print(f"[sync_contracts] Loading schema: {schema_path}")
    schema = schema_parser.load(schema_path)
    print(
        f"[sync_contracts] Schema loaded — "
        f"{len(schema.enums)} enums, "
        f"{len(schema.structs)} structs, "
        f"{len(schema.operations)} operations"
    )

    selected_langs = args.lang or list(GENERATORS.keys())
    check_failed = False

    for lang in selected_langs:
        gen = GENERATORS[lang]
        output_root = resolve_output_root(lang, schema.output)
        files = gen.generate(schema)

        print(f"\n[sync_contracts] {lang.upper()} -> {output_root}")

        for rel_path, content in files.items():
            dest = output_root / rel_path
            encoded = content.encode("utf-8")

            if args.check:
                if not dest.exists():
                    print(f"  ✗ MISSING  {rel_path}")
                    check_failed = True
                elif dest.read_bytes() != encoded:
                    print(f"  ✗ DIFFERS  {rel_path}")
                    check_failed = True
                else:
                    print(f"  ✓ OK       {rel_path}")
                continue

            if args.dry_run:
                print(f"  (dry-run) would write {rel_path}  ({len(encoded)} bytes)")
                continue

            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(encoded)
            print(f"  ✓ wrote    {rel_path}  ({len(encoded)} bytes)")

    if args.check and check_failed:
        print(
            "\n[sync_contracts] CHECK FAILED — "
            "run `python -m tools.sync_contracts` to regenerate."
        )
        sys.exit(1)
    elif args.check:
        print("\n[sync_contracts] All generated files are up to date.")

    if not args.dry_run and not args.check:
        print(f"\n[sync_contracts] Done. Generated {len(selected_langs)} language(s).")


if __name__ == "__main__":
    main()
