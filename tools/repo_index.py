#!/usr/bin/env python3
"""
repo_index.py — horAIzon 3.0 Repo Index Generator

Generates _architecture/repo_index.md: a compact structured summary of every
source file in the repo. This is injected as the FIRST context file in every
aider call so that 8b models can reason about the full codebase without
blowing their 8k context window.

~2,000-4,000 tokens for a medium-sized repo.

Usage:
  python tools/repo_index.py
"""

from __future__ import annotations

import ast
import datetime
import os
from pathlib import Path

REPO_ROOT   = Path(__file__).parent.parent
OUTPUT_PATH = REPO_ROOT / "_architecture" / "repo_index.md"

LANG_MAP = {
    ".py":    "Python",
    ".rs":    "Rust",
    ".dart":  "Dart",
    ".go":    "Go",
    ".ts":    "TypeScript",
    ".js":    "JavaScript",
    ".md":    "Markdown",
    ".toml":  "TOML",
    ".yaml":  "YAML",
    ".yml":   "YAML",
    ".json":  "JSON",
    ".ps1":   "PowerShell",
}

SKIP_DIRS = {".n8n", 
    ".git", "__pycache__", "node_modules", "target", ".dart_tool",
    "build", ".gradle", ".idea", ".vscode", "dist", ".next",
}

SKIP_FILES = {"repo_index.md"}
MAX_SUMMARY_CHARS = 120


def extract_summary(path: Path) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""
    lines = text.splitlines()
    if path.suffix == ".py":
        try:
            tree = ast.parse(text)
            for node in ast.walk(tree):
                if isinstance(node, (ast.Module, ast.FunctionDef, ast.ClassDef)):
                    doc = ast.get_docstring(node)
                    if doc:
                        first = doc.strip().splitlines()[0]
                        return first[:MAX_SUMMARY_CHARS]
        except Exception:
            pass
    for line in lines[:15]:
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("#!"):
            continue
        for prefix in ("///", "//", "#", "/*", "*", "---", "==="):
            if stripped.startswith(prefix):
                stripped = stripped[len(prefix):].strip()
                break
        if len(stripped) > 4:
            return stripped[:MAX_SUMMARY_CHARS]
    return ""


def get_top_symbols(path: Path) -> str:
    if path.suffix != ".py":
        return ""
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
        tree = ast.parse(text)
        names = []
        for node in ast.iter_child_nodes(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                names.append(node.name)
        return ", ".join(names[:8])
    except Exception:
        return ""


def collect_files() -> list:
    records = []
    for root, dirs, files in os.walk(REPO_ROOT):
        root_path = Path(root)
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in sorted(files):
            if fname in SKIP_FILES:
                continue
            fpath = root_path / fname
            suffix = fpath.suffix.lower()
            lang = LANG_MAP.get(suffix)
            if lang is None:
                continue
            rel = fpath.relative_to(REPO_ROOT).as_posix()
            size_kb = fpath.stat().st_size / 1024
            summary = extract_summary(fpath)
            symbols = get_top_symbols(fpath)
            records.append({"path": rel, "lang": lang, "size_kb": size_kb, "summary": summary, "symbols": symbols})
    return records


def format_table(records: list) -> str:
    lines = ["| File | Lang | Size | Summary | Key Symbols |", "| :--- | :--- | ---: | :--- | :--- |"]
    for r in records:
        size = f"{r['size_kb']:.1f}k"
        summary = r["summary"].replace("|", "\\|")
        symbols = r["symbols"].replace("|", "\\|")
        lines.append(f"| `{r['path']}` | {r['lang']} | {size} | {summary} | {symbols} |")
    return "\n".join(lines)


def main() -> None:
    print("[repo_index] Scanning repository...")
    records = collect_files()
    print(f"[repo_index] Found {len(records)} indexable files.")
    now = datetime.datetime.now().isoformat(timespec="seconds")
    content = f"# horAIzon 3.0 - Repository Index\nGenerated: {now}\nFiles: {len(records)}\n\n> Inject as first context file so 8b models can reason about the full repo.\n\n---\n\n{format_table(records)}\n"
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(content, encoding="utf-8")
    print(f"[repo_index] Written to: {OUTPUT_PATH.relative_to(REPO_ROOT)}")
    print(f"[repo_index] Estimated tokens: ~{len(content) // 4:,}")


if __name__ == "__main__":
    main()
