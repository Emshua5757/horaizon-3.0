"""
__main__.py — CLI entry point for sync_contracts.

Usage:
  python -m tools.sync_contracts                   # regenerate all languages + API_REFERENCE.md
  python -m tools.sync_contracts --lang dart rust  # specific languages only
  python -m tools.sync_contracts --watch           # hot-reload watcher mode
  python -m tools.sync_contracts --dry-run         # preview without writing
  python -m tools.sync_contracts --check           # fail if generated files differ (CI mode)

Run from the repo root: c:\\horaizon-3.0
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

# Allow running as `python -m tools.sync_contracts` from repo root
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from tools.sync_contracts import parser as schema_parser
from tools.sync_contracts.generators.dart_gen       import DartGenerator
from tools.sync_contracts.generators.rust_gen       import RustGenerator
from tools.sync_contracts.generators.go_gen         import GoGenerator
from tools.sync_contracts.generators.typescript_gen import TypeScriptGenerator
from tools.sync_contracts.generators.python_gen     import PythonGenerator
from tools.sync_contracts.generators import markdown as markdown_gen
from tools.sync_contracts.generators.base           import BaseGenerator

GENERATORS: dict[str, BaseGenerator] = {
    "dart":       DartGenerator(),
    "rust":       RustGenerator(),
    "go":         GoGenerator(),
    "typescript": TypeScriptGenerator(),
    "python":     PythonGenerator(),
}

REPO_ROOT = Path(__file__).parent.parent.parent  # c:\horaizon-3.0
DEFAULT_SCHEMA_DIR = REPO_ROOT / "_architecture" / "contracts" / "hbp" / "schema"


def resolve_output_root(lang: str, schema_output: dict[str, str]) -> Path:
    """Resolve absolute output directory for a language."""
    rel = schema_output.get(lang, f"tools/sync_contracts/generated/{lang}")
    return REPO_ROOT / rel


def run_sync(schema_dir: Path, selected_langs: list[str], dry_run: bool, check: bool) -> bool:
    print(f"\n[sync_contracts] Loading schemas from: {schema_dir}")
    schema = schema_parser.load(schema_dir)
    print(
        f"[sync_contracts] Schema loaded — "
        f"{len(schema.enums)} enums, "
        f"{len(schema.structs)} structs, "
        f"{len(schema.operations)} operations"
    )

    check_failed = False

    # 1. Multi-language code generators
    for lang in selected_langs:
        gen = GENERATORS[lang]
        output_root = resolve_output_root(lang, schema.output)
        files = gen.generate(schema)

        print(f"\n[sync_contracts] {lang.upper()} -> {output_root}")

        for rel_path, content in files.items():
            dest = output_root / rel_path
            encoded = content.encode("utf-8")

            if check:
                if not dest.exists():
                    print(f"  ✗ MISSING  {rel_path}")
                    check_failed = True
                elif dest.read_bytes() != encoded:
                    print(f"  ✗ DIFFERS  {rel_path}")
                    check_failed = True
                else:
                    print(f"  ✓ OK       {rel_path}")
                continue

            if dry_run:
                print(f"  (dry-run) would write {rel_path}  ({len(encoded)} bytes)")
                continue

            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(encoded)
            print(f"  ✓ wrote    {rel_path}  ({len(encoded)} bytes)")

    # 2. Markdown API Reference generator
    if not check and not dry_run:
        print(f"\n[sync_contracts] MARKDOWN -> _architecture/contracts/hbp/API_REFERENCE.md")
        md_files = markdown_gen.generate(schema)
        for dest, content in md_files.items():
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(content.encode("utf-8"))
            print(f"  ✓ wrote    {dest.name}  ({len(content)} bytes)")

    if check and check_failed:
        print("\n[sync_contracts] CHECK FAILED — run `python -m tools.sync_contracts` to regenerate.")
        return False
    elif check:
        print("\n[sync_contracts] All generated files are up to date.")
        return True

    if not dry_run and not check:
        print(f"\n[sync_contracts] Done. Generated {len(selected_langs)} language(s) + API_REFERENCE.md.")
    return True


def watch_mode(schema_dir: Path, selected_langs: list[str]) -> None:
    print(f"\n[sync_contracts] Watch mode daemon started — monitoring {schema_dir}/*.toml")
    last_mtimes: dict[Path, float] = {}

    def get_mtimes() -> dict[Path, float]:
        return {p: p.stat().st_mtime for p in schema_dir.glob("*.toml")}

    run_sync(schema_dir, selected_langs, dry_run=False, check=False)
    last_mtimes = get_mtimes()

    try:
        while True:
            time.sleep(1)
            current_mtimes = get_mtimes()
            if current_mtimes != last_mtimes:
                print("\n[sync_contracts] Schema change detected! Regenerating contracts...")
                try:
                    run_sync(schema_dir, selected_langs, dry_run=False, check=False)
                except Exception as e:
                    print(f"[sync_contracts] Regeneration error: {e}")
                last_mtimes = current_mtimes
    except KeyboardInterrupt:
        print("\n[sync_contracts] Watch mode stopped.")


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
        help="CI mode: fail with exit code 1 if generated files differ.",
    )
    ap.add_argument(
        "--watch",
        action="store_true",
        help="Daemon watch mode: auto-regenerate contracts when TOML schema files change.",
    )
    ap.add_argument(
        "--schema-dir",
        type=Path,
        default=DEFAULT_SCHEMA_DIR,
        help="Path to schema directory containing .toml files.",
    )
    args = ap.parse_args()

    selected_langs = args.lang or list(GENERATORS.keys())

    if args.watch:
        watch_mode(args.schema_dir, selected_langs)
    else:
        success = run_sync(args.schema_dir, selected_langs, args.dry_run, args.check)
        if not success:
            sys.exit(1)


if __name__ == "__main__":
    main()
