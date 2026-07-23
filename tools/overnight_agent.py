#!/usr/bin/env python3
"""
overnight_agent.py — horAIzon 3.0 autonomous coding agent

Reads a TASK-XXX.md file from _architecture/tasks/active/,
drives aider + local Ollama to execute it autonomously,
logs everything, and updates task status on completion.

Usage:
  # Run a specific task
  python tools/overnight_agent.py TASK-003

  # Run all not-started tasks in dependency order
  python tools/overnight_agent.py --all

  # Dry run — show what would be executed
  python tools/overnight_agent.py --all --dry-run

  # Use a different model (default: qwen2.5-coder:14b)
  python tools/overnight_agent.py TASK-003 --model qwen2.5-coder:7b

Requirements (run tools/setup_overnight_agent.py first):
  pip install aider-chat
  ollama pull qwen2.5-coder:14b
"""

from __future__ import annotations

import argparse
import datetime
import os
import re
import subprocess
import sys
from pathlib import Path

# ---- Paths ----
REPO_ROOT    = Path(__file__).parent.parent
TASKS_DIR    = REPO_ROOT / "_architecture" / "tasks" / "active"
ARCHIVED_DIR = REPO_ROOT / "_architecture" / "tasks" / "archived"
LOGS_DIR     = REPO_ROOT / "_architecture" / "progress" / "agent_logs"
REPO_INDEX   = REPO_ROOT / "_architecture" / "repo_index.md"

# ---- Models ----
DEFAULT_MODEL   = "qwen2.5-coder:7b"
FALLBACK_MODEL  = "llama3.1:8b"
OLLAMA_BASE_URL = "http://localhost:11434"

# ---- 8b model tuning ----
# Keeps the aider repo-map under ~1k tokens so the model's 8k window
# isn't consumed by the map alone. The repo_index.md we inject manually
# is a much denser summary (~2-4k tokens total).
MAP_TOKENS_LIMIT = 1024

# ---- Task dependency order (edit when adding new tasks) ----
TASK_ORDER = [
    "TASK-002",   # VSCode workspace setup — no dependencies
    "TASK-003",   # Governor Cargo scaffold
    "TASK-004",   # Governor HBP v2 broker
    "TASK-005",   # Governor process registry
    "TASK-006",   # Governor Ollama + AI router + Dream Loop
    "TASK-007",   # Governor config + systemd (needs Pi5 SSH from TASK-001)
    "TASK-008",   # Flutter scaffold
    "TASK-009",   # Flutter HBP client
    "TASK-010",   # Flutter router + splash + theme
    "TASK-011",   # Flutter dashboard + governor screens
    "TASK-012",   # Flutter settings + connection banner
    # TASK-001 is manual (Pi5 SSH) — excluded from auto-run
    # TASK-007 is semi-manual (Pi5 deploy) — run separately
]

# Tasks that require human interaction — agent will skip these
MANUAL_TASKS = {"TASK-001", "TASK-007"}


# ============================================================
# Task file helpers
# ============================================================

def find_task_file(task_id: str) -> Path | None:
    """Find a task MD file by ID (e.g. 'TASK-003')."""
    for f in TASKS_DIR.glob(f"{task_id}_*.md"):
        return f
    return None


def get_task_status(task_file: Path) -> str:
    """Read the status from a task file: 'not_started' | 'in_progress' | 'done'."""
    content = task_file.read_text(encoding="utf-8")
    if "[ ] Not started" in content:
        return "not_started"
    if "[/] In progress" in content:
        return "in_progress"
    if "[x] Done" in content:
        return "done"
    return "unknown"


def mark_task_status(task_file: Path, status: str) -> None:
    """Update the status line in a task file."""
    content = task_file.read_text(encoding="utf-8")
    replacements = {
        "not_started": ("[ ] Not started", "[/] In progress"),
        "in_progress":  ("[/] In progress", "[x] Done"),
        "done":         ("[ ] Not started", "[x] Done"),
    }
    old, new = replacements.get(status, (None, None))
    if old and old in content:
        content = content.replace(old, new, 1)
        task_file.write_text(content, encoding="utf-8")


def get_task_title(task_file: Path) -> str:
    """Extract the H1 title from a task file."""
    content = task_file.read_text(encoding="utf-8")
    for line in content.splitlines():
        if line.startswith("# TASK-"):
            return line.lstrip("# ").strip()
    return task_file.stem


def read_task_content(task_file: Path) -> str:
    """Return full task content."""
    return task_file.read_text(encoding="utf-8")


# ============================================================
# Ollama availability check
# ============================================================

def check_ollama(model: str) -> bool:
    """Check if Ollama is running and the model is available."""
    try:
        result = subprocess.run(
            ["ollama", "list"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            print("[agent] ERROR: Ollama is not running or not installed.")
            print("  Start Ollama: ollama serve")
            return False
        if model not in result.stdout:
            print(f"[agent] Model '{model}' not found. Pulling now...")
            pull = subprocess.run(["ollama", "pull", model], timeout=600)
            if pull.returncode != 0:
                print(f"[agent] ERROR: Could not pull {model}")
                return False
            print(f"[agent] Model '{model}' ready.")
        return True
    except (FileNotFoundError, subprocess.TimeoutExpired):
        print("[agent] ERROR: Ollama not found. Install from https://ollama.com")
        return False


def check_aider() -> bool:
    """Check if aider is installed."""
    try:
        result = subprocess.run(
            ["aider", "--version"],
            capture_output=True, text=True, timeout=5
        )
        return result.returncode == 0
    except FileNotFoundError:
        return False


# ============================================================
# Agent prompt builder
# ============================================================

SYSTEM_PROMPT = """\
You are an expert software engineer working on the horAIzon 3.0 project.
The repo root is the current directory.
You MUST follow the task instructions precisely.
Do NOT ask clarifying questions — execute the task fully.
Do NOT skip steps — implement everything described.
After completing each step, verify it works before moving to the next.
When writing Rust code, run `cargo check` to verify.
When writing Dart code, run `flutter analyze` to verify.
Commit working code at the end of the task with the message: "feat: complete {task_id}"
"""

def build_aider_message(task_file: Path) -> str:
    """Build the message to send to aider."""
    task_content = read_task_content(task_file)
    task_id = task_file.stem.split("_")[0]
    return f"""Execute the following task completely and without skipping any steps.

{task_content}

---
After completing all steps:
1. Run any verification commands listed in the Acceptance Criteria section
2. Fix any errors before finishing
3. Confirm each acceptance criterion is met
4. Commit all changes with: git commit -m "feat: complete {task_id}"
"""


# ============================================================
# Aider runner
# ============================================================

def run_aider(
    task_file: Path,
    model: str,
    log_file: Path,
    dry_run: bool = False,
) -> bool:
    """Run aider with the given task. Returns True on success."""
    task_id = task_file.stem.split("_")[0]
    message = build_aider_message(task_file)

    # Determine which files aider should be aware of
    context_files = _get_context_files(task_id)

    cmd = [
        "aider",
        "--model", f"ollama/{model}",
        "--yes",                          # non-interactive
        "--auto-commits",                 # commit when done
        "--dirty-commits",                # commit dirty files too
        "--message", message,
        "--no-suggest-shell-commands",    # don't suggest — just do
        "--map-tokens", str(MAP_TOKENS_LIMIT),  # 8b: limit repo-map tokens
        # Additional context files
        *context_files,
    ]

    print(f"[agent] Running aider for {task_id}...")
    print(f"[agent] Model: {model}")
    print(f"[agent] Log:   {log_file}")
    print(f"[agent] Context files: {context_files}")

    if dry_run:
        print("[agent] DRY RUN — would execute:")
        print("  " + " ".join(cmd))
        return True

    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    with open(log_file, "w", encoding="utf-8") as log:
        log.write(f"=== horAIzon overnight_agent ===\n")
        log.write(f"Task:     {task_id}\n")
        log.write(f"Model:    {model}\n")
        log.write(f"Started:  {datetime.datetime.now().isoformat()}\n")
        log.write(f"Command:  {' '.join(cmd)}\n\n")
        log.flush()

        def _run_once(attempt: int) -> bool:
            """Run aider once. Returns True on success."""
            if attempt > 1:
                print(f"[agent] Retry attempt {attempt}...")
                log.write(f"\n[RETRY attempt {attempt}]\n")
            try:
                proc = subprocess.Popen(
                    cmd,
                    cwd=str(REPO_ROOT),
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    env={
                        **os.environ,
                        # Ollama OpenAI-compat endpoint for aider
                        "OPENAI_API_BASE": f"{OLLAMA_BASE_URL}/v1",
                        "OPENAI_API_KEY":  "ollama",
                    },
                )

                # Tee output to both log and stdout
                for line in proc.stdout:
                    print(line, end="", flush=True)
                    log.write(line)
                    log.flush()

                proc.wait()
                return proc.returncode == 0

            except KeyboardInterrupt:
                print("\n[agent] Interrupted by user.")
                log.write("\n[INTERRUPTED]\n")
                return False

        # Run with one automatic retry for 8b model reliability
        success = _run_once(1)
        if not success:
            print("[agent] First attempt failed — retrying once...")
            success = _run_once(2)

        log.write(f"\n\nFinished: {datetime.datetime.now().isoformat()}\n")
        log.write(f"Status: {'SUCCESS' if success else 'FAILED'}\n")
        return success


def _get_context_files(task_id: str) -> list[str]:
    """Return paths that aider should load as context for this task.

    repo_index.md is ALWAYS injected first — it gives 8b models a compact
    map of the entire codebase (~2-4k tokens) so they can reason about the
    repo without loading every file.
    """
    # Always include the repo index + the task file itself
    base = [
        str(REPO_INDEX.relative_to(REPO_ROOT)),   # repo map (first!)
        f"_architecture/tasks/active/{task_id}_*.md",
    ]

    per_task: dict[str, list[str]] = {
        "TASK-003": [
            "_architecture/specs/shua_governor/shua_governor_spec.md",
        ],
        "TASK-004": [
            "_architecture/contracts/hbp/hbp_v2_spec.md",
            "_architecture/specs/shua_governor/shua_governor_spec.md",
            "shua_governor/src/main.rs",
        ],
        "TASK-005": [
            "_architecture/specs/shua_governor/shua_governor_spec.md",
            "shua_governor/src/broker/frame.rs",
            "shua_governor/src/broker/dispatcher.rs",
        ],
        "TASK-006": [
            "_architecture/specs/shua_governor/shua_governor_spec.md",
        ],
        "TASK-007": [
            "_architecture/specs/shua_governor/shua_governor_spec.md",
        ],
        "TASK-008": [
            "_architecture/specs/client_flutter/client_flutter_spec.md",
        ],
        "TASK-009": [
            "_architecture/contracts/hbp/hbp_v2_spec.md",
            "_architecture/specs/client_flutter/client_flutter_spec.md",
        ],
        "TASK-010": [
            "_architecture/specs/client_flutter/client_flutter_spec.md",
            "client_flutter/lib/core/hbp/hbp_client.dart",
        ],
        "TASK-011": [
            "_architecture/specs/client_flutter/client_flutter_spec.md",
            "_architecture/contracts/hbp/hbp_v2_spec.md",
        ],
        "TASK-012": [
            "_architecture/specs/client_flutter/client_flutter_spec.md",
        ],
    }

    # Resolve glob patterns
    resolved: list[str] = []
    for pattern in base + per_task.get(task_id, []):
        matches = list(REPO_ROOT.glob(pattern))
        resolved.extend(str(p.relative_to(REPO_ROOT)) for p in matches if p.exists())

    return resolved


# ============================================================
# Archive task on completion
# ============================================================

def archive_task(task_file: Path) -> None:
    """Move a completed task to the archived folder."""
    ARCHIVED_DIR.mkdir(parents=True, exist_ok=True)
    dest = ARCHIVED_DIR / task_file.name
    task_file.rename(dest)
    print(f"[agent] Archived: {task_file.name} → tasks/archived/")


# ============================================================
# Main runner
# ============================================================

def run_task(task_id: str, model: str, dry_run: bool, archive: bool) -> bool:
    """Find and execute a single task. Returns True on success."""
    if task_id in MANUAL_TASKS:
        print(f"[agent] Skipping {task_id} — manual task (requires human on Pi5)")
        return True

    task_file = find_task_file(task_id)
    if task_file is None:
        print(f"[agent] ERROR: No task file found for {task_id} in {TASKS_DIR}")
        return False

    status = get_task_status(task_file)
    if status == "done":
        print(f"[agent] Skipping {task_id} — already done")
        return True

    title = get_task_title(task_file)
    print(f"\n{'='*60}")
    print(f"[agent] Starting: {task_id}")
    print(f"[agent] Title:    {title}")
    print(f"{'='*60}\n")

    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = LOGS_DIR / f"{ts}_{task_id}.log"

    # Mark as in-progress
    if not dry_run:
        mark_task_status(task_file, "not_started")

    success = run_aider(task_file, model, log_file, dry_run)

    if success and not dry_run:
        mark_task_status(task_file, "in_progress")  # in_progress → done
        print(f"\n[agent] {task_id} COMPLETED ✓")
        if archive:
            archive_task(task_file)
    elif not success:
        print(f"\n[agent] {task_id} FAILED — check log: {log_file}")

    return success


def main() -> None:
    ap = argparse.ArgumentParser(
        description="overnight_agent — autonomous coding agent for horAIzon 3.0"
    )
    ap.add_argument(
        "task",
        nargs="?",
        help="Task ID to run, e.g. TASK-003. Omit with --all to run all.",
    )
    ap.add_argument(
        "--all",
        action="store_true",
        help="Run all not-started tasks in dependency order.",
    )
    ap.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Ollama model to use. Default: {DEFAULT_MODEL}",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be executed without running.",
    )
    ap.add_argument(
        "--no-archive",
        action="store_true",
        help="Don't move completed tasks to archived/.",
    )
    args = ap.parse_args()

    if not args.task and not args.all:
        ap.print_help()
        sys.exit(1)

    print(f"\n{'='*60}")
    print(" horAIzon 3.0 — Overnight Agent")
    print(f"{'='*60}")
    print(f" Model:   {args.model}")
    print(f" Dry run: {args.dry_run}")
    print(f" Repo:    {REPO_ROOT}")
    print(f"{'='*60}\n")

    # Pre-flight checks
    if not args.dry_run:
        if not check_aider():
            print("[agent] ERROR: aider not installed.")
            print("  Install: pip install aider-chat")
            print("  Or run:  python tools/setup_overnight_agent.py")
            sys.exit(1)

        if not check_ollama(args.model):
            print(f"[agent] Trying fallback model: {FALLBACK_MODEL}")
            if not check_ollama(FALLBACK_MODEL):
                sys.exit(1)
            args.model = FALLBACK_MODEL

    archive = not args.no_archive

    if args.all:
        print(f"[agent] Running all tasks in order: {TASK_ORDER}")
        failed = []
        for task_id in TASK_ORDER:
            ok = run_task(task_id, args.model, args.dry_run, archive)
            if not ok:
                failed.append(task_id)
                print(f"[agent] Stopping at {task_id} — fix errors before continuing.")
                break

        print(f"\n{'='*60}")
        if failed:
            print(f"[agent] STOPPED at: {failed}")
        else:
            print("[agent] ALL TASKS COMPLETE")
        print(f"{'='*60}\n")

    else:
        task_id = args.task.upper()
        if not task_id.startswith("TASK-"):
            task_id = f"TASK-{task_id}"
        ok = run_task(task_id, args.model, args.dry_run, archive)
        sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
