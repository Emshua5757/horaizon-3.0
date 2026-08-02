#!/usr/bin/env python3
"""
horAIzon 3.0 — Context Compilation CLI Tool

Usage:
  # Automatically compile all active task specs & MCP contracts:
  python tools/compile_context.py --all --output context.md

  # Compile specific files & directories:
  python tools/compile_context.py -o task-016B_compiled_context.md _architecture/tasks/active/TASK-016B_flutter_code_topology_live_physics_animation.md client_flutter/lib/features/code_visualizer/ shua_code_visualizer/src/
"""

import sys
import os
import glob
import argparse

DEFAULT_OUTPUT = "compiled_context.md"

def expand_paths(paths):
    expanded = []
    valid_exts = {".md", ".toml", ".json", ".yaml", ".yml", ".rs", ".ts", ".dart", ".go", ".cs"}
    ignored_dirs = {"target", ".git", ".dart_tool", "build", "node_modules", ".n8n"}
    
    for p in paths:
        abs_p = os.path.abspath(p)
        if os.path.isdir(abs_p):
            for root, dirs, files in os.walk(abs_p):
                dirs[:] = [d for d in dirs if d not in ignored_dirs]
                for f in sorted(files):
                    ext = os.path.splitext(f)[1].lower()
                    if ext in valid_exts:
                        expanded.append(os.path.join(root, f))
        elif os.path.isfile(abs_p):
            expanded.append(abs_p)
    return expanded

def find_default_files(repo_root):
    paths = [
        os.path.join(repo_root, "_architecture", "contracts"),
        os.path.join(repo_root, "_architecture", "decisions"),
        os.path.join(repo_root, "_architecture", "tasks", "active"),
    ]
    return expand_paths(paths)

def compile_context(file_paths, output_path, repo_root):
    compiled_parts = []
    compiled_parts.append("# horAIzon 3.0 — Compiled Master Context Document\n\n")
    compiled_parts.append(f"> Total Files Included: {len(file_paths)}\n\n")
    compiled_parts.append("=" * 80 + "\n\n")

    for path in file_paths:
        abs_path = os.path.abspath(path)
        rel_path = os.path.relpath(abs_path, repo_root) if os.path.isabs(path) else path
        filename = os.path.basename(path)

        compiled_parts.append(f"<!-- START_FILE: {rel_path} -->\n")
        compiled_parts.append(f"# FILE: {filename}\n")
        compiled_parts.append(f"**Relative Path**: `{rel_path}`\n\n")

        if os.path.exists(abs_path):
            with open(abs_path, "r", encoding="utf-8", errors="replace") as f:
                compiled_parts.append(f.read())
        else:
            compiled_parts.append(f"> [!WARNING] File not found: `{rel_path}`\n")

        compiled_parts.append("\n\n<!-- END_FILE: " + rel_path + " -->\n")
        compiled_parts.append("=" * 80 + "\n\n")

    content_str = "".join(compiled_parts)

    output_abs = os.path.abspath(output_path)
    os.makedirs(os.path.dirname(output_abs), exist_ok=True)

    with open(output_abs, "w", encoding="utf-8") as out_f:
        out_f.write(content_str)

    # Context size calculations
    char_count = len(content_str)
    word_count = len(content_str.split())
    # Standard LLM token estimation (~3.8 chars per token for code/markdown)
    estimated_tokens = int(char_count / 3.8)
    
    sonnet_limit = 200000
    sonnet_pct = (estimated_tokens / sonnet_limit) * 100.0

    print("=" * 80)
    print(f"[OK] Successfully compiled {len(file_paths)} files into: {output_abs}")
    print("=" * 80)
    print("CONTEXT CAPACITY REPORT:")
    print(f"   * Total Characters : {char_count:,}")
    print(f"   * Total Words      : {word_count:,}")
    print(f"   * Estimated Tokens : ~{estimated_tokens:,} tokens")
    print(f"   * Claude Sonnet Max: 200,000 tokens")
    print(f"   * Capacity Usage   : {sonnet_pct:.2f}% of Sonnet window")
    print("-" * 80)

    if estimated_tokens <= sonnet_limit:
        print(f"  [PASS] Claude 3.5 / 3.7 Sonnet CAN easily eat and understand 100% of this context document!")
        print(f"         It uses only {sonnet_pct:.1f}% of Sonnet's 200k context capacity.")
    else:
        print(f"  [WARNING] Context exceeds Sonnet's 200k token limit ({sonnet_pct:.1f}%). Trim unnecessary files.")
    print("=" * 80)

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    
    parser = argparse.ArgumentParser(description="Compile horAIzon 3.0 specs and tasks into a single prompt document for Claude.")
    parser.add_argument("files", nargs="*", help="Specific files or directories to compile")
    parser.add_argument("-o", "--output", default=DEFAULT_OUTPUT, help="Output filename/path (default: compiled_context.md)")
    parser.add_argument("-a", "--all", action="store_true", help="Automatically include all active tasks and contract specs")

    args = parser.parse_args()

    if args.all or not args.files:
        file_paths = find_default_files(repo_root)
    else:
        file_paths = expand_paths(args.files)

    compile_context(file_paths, args.output, repo_root)

if __name__ == "__main__":
    main()
