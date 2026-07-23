#!/usr/bin/env python3
"""
overnight_planner.py — horAIzon 3.0 Local Spec & Task Generator

Uses local Ollama (offloaded to system RAM + 4GB VRAM) to analyze system specs
and draft actionable TASK-XXX markdown files overnight.

Generated tasks land in: _architecture/tasks/proposed/
When you wake up, review them and have cloud AI (Gemini 3.5) execute them!

Usage:
  python tools/overnight_planner.py --topic phase2
  python tools/overnight_planner.py --topic phase3
  python tools/overnight_planner.py --all
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import subprocess
import sys
from pathlib import Path
import urllib.request

REPO_ROOT    = Path(__file__).parent.parent
SPECS_DIR    = REPO_ROOT / "_architecture" / "specs"
ACTIVE_DIR   = REPO_ROOT / "_architecture" / "tasks" / "active"
PROPOSED_DIR = REPO_ROOT / "_architecture" / "tasks" / "proposed"
LOGS_DIR     = REPO_ROOT / "_architecture" / "progress" / "agent_logs"

OLLAMA_URL = "http://localhost:11434/api/generate"

# Default model: 7b or 14b will run fine via CPU+GPU RAM offloading
DEFAULT_MODEL = "qwen2.5-coder:7b"
FALLBACK_MODEL = "llama3.1:8b"

PROMPT_TEMPLATE = """\
You are an expert Principal Software Architect for horAIzon 3.0 (a native-first, local-first personal assistant ecosystem).

ARCHITECTURE CONTEXT:
- Protocol: HBP v2 (MessagePack over WebSocket on port 7700)
- Core processes: Rust (shua_governor), Flutter (client_flutter), Go (shua_resume), TypeScript/Node (shua_diary), Python (shua_code_visualizer)
- Design Rule: NO SDUI, Native UI, typed contracts via sync_contracts.py.

TOPIC TO PLAN:
{topic_description}

EXISTING ACTIVE TASKS (do not duplicate these):
{existing_tasks}

INSTRUCTIONS:
Generate 2 to 4 detailed, executable TASK markdown files for Phase 2/3 development.
Each task MUST follow this exact format:

---START_TASK---
# TASK-XXX — [Short Descriptive Title]

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Proposed |
| **Phase** | [Phase 2 or Phase 3] |
| **Type** | AI-executable |
| **Language** | [Rust / Dart / Go / TypeScript / Python] |
| **Target** | [Target path] |
| **Blocks** | [Subsequent tasks] |
| **Prerequisites** | [Dependencies] |

---

## Context
[Detailed explanation of what this component is and why it exists]

---

## Technical Specifications
[Exact data structures, HBP v2 ops, or file layouts]

---

## Implementation Steps
[Step-by-step instructions for Gemini 3.5 to implement]

---

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
---END_TASK---

Generate clear, modular, professional task specifications now.
"""

TOPICS = {
    "phase2_code_vis": """
Phase 2 — shua_code_visualizer:
- Python AST scanner that parses repository topology (functions, structs, imports, call graphs).
- Real-time file-watcher that emits `TopologyDeltaEvent` over HBP v2 when files change.
- Exports graph topology JSON over HBP v2 (`shua.code_visualizer.scan`, `shua.code_visualizer.topology.get`).
- Flutter visualizer screen using custom painter or graph rendering.
""",
    "phase3_resume": """
Phase 3 — shua_resume:
- Go backend for Typst PDF compilation.
- Matrix storage for resume blocks (YAML/JSON schema).
- AI resume tailoring engine calling Ollama `qwen2.5:1.5b` for job description keyword alignment.
- Content-Addressed Storage (CAS) for generated PDF exhibits.
""",
    "phase3_diary": """
Phase 3 — shua_diary:
- TypeScript / Node block-based diary engine with LexoRank ordering.
- SQLite storage for block items.
- Server-pushed sentiment scoring events (`shua.diary.sentiment.score`).
- Global Identity Matrix memory elevation (`shua.diary.memory.elevate`).
"""
}


def get_existing_tasks() -> str:
    tasks = []
    for f in list(ACTIVE_DIR.glob("*.md")) + list(PROPOSED_DIR.glob("*.md")):
        tasks.append(f.name)
    return "\n".join(tasks) if tasks else "None"


def call_ollama(model: str, prompt: str) -> str:
    print(f"[planner] Sending prompt to local Ollama ({model})...")
    print("  (Note: Ollama automatically offloads model layers between 4GB VRAM and System RAM)")

    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "num_ctx": 4096,
            "temperature": 0.2
        }
    }

    req = urllib.request.Request(
        OLLAMA_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )

    try:
        with urllib.request.urlopen(req, timeout=1800) as response:
            res = json.loads(response.read().decode("utf-8"))
            return res.get("response", "")
    except Exception as e:
        print(f"[planner] ERROR calling Ollama: {e}")
        return ""


def parse_and_save_tasks(raw_response: str) -> list[Path]:
    PROPOSED_DIR.mkdir(parents=True, exist_ok=True)
    saved_files = []

    # Find tasks using delimiter
    task_blocks = raw_response.split("---START_TASK---")
    
    # Calculate next available task number
    existing_nums = []
    for f in list(ACTIVE_DIR.glob("TASK-*.md")) + list(PROPOSED_DIR.glob("TASK-*.md")):
        try:
            num = int(f.name.split("-")[1].split("_")[0])
            existing_nums.append(num)
        except (IndexError, ValueError):
            pass
    next_num = (max(existing_nums) if existing_nums else 12) + 1

    for block in task_blocks:
        if "---END_TASK---" not in block:
            continue
        task_md = block.split("---END_TASK---")[0].strip()
        
        # Extract title line
        lines = task_md.splitlines()
        title_line = next((l for l in lines if l.startswith("# TASK-")), "")
        
        # Format filename
        slug = "task_draft"
        if title_line:
            clean_title = title_line.replace("#", "").strip()
            # extract title after dash if present
            if "—" in clean_title:
                clean_title = clean_title.split("—")[1]
            elif "-" in clean_title:
                clean_title = clean_title.split("-", 1)[1]
            slug = clean_title.strip().lower().replace(" ", "_")
            slug = "".join(c for c in slug if c.isalnum() or c == "_")

        task_id = f"TASK-{next_num:03d}"
        next_num += 1

        filename = f"{task_id}_{slug}.md"
        out_path = PROPOSED_DIR / filename

        # Ensure correct header ID in task content
        if title_line:
            task_md = task_md.replace(title_line, f"# {task_id} — {slug.replace('_', ' ').title()}")

        out_path.write_text(task_md, encoding="utf-8")
        print(f"[planner] Generated proposed task: {out_path.name}")
        saved_files.append(out_path)

    return saved_files


def main() -> None:
    ap = argparse.ArgumentParser(description="Overnight Task Planner using Local Ollama")
    ap.add_argument("--topic", choices=["phase2", "phase3", "all"], default="all")
    ap.add_argument("--model", default=DEFAULT_MODEL, help=f"Ollama model (default: {DEFAULT_MODEL})")
    args = ap.parse_args()

    PROPOSED_DIR.mkdir(parents=True, exist_ok=True)
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    print("==================================================")
    print(" horAIzon 3.0 — Overnight Task Planner")
    print("==================================================")
    print(f" Target Dir: {PROPOSED_DIR}")
    print(f" Model:      {args.model}")
    print("==================================================\n")

    topics_to_run = list(TOPICS.keys()) if args.topic == "all" else [k for k in TOPICS if args.topic in k]

    existing = get_existing_tasks()

    for key in topics_to_run:
        topic_desc = TOPICS[key]
        print(f"\n[planner] Planning topic: {key}...")
        prompt = PROMPT_TEMPLATE.format(
            topic_description=topic_desc,
            existing_tasks=existing
        )
        response = call_ollama(args.model, prompt)
        if response:
            saved = parse_and_save_tasks(response)
            print(f"[planner] Successfully drafted {len(saved)} tasks for {key}")

    print("\n==================================================")
    print(" Planning Complete!")
    print(f" Check proposed tasks in: {PROPOSED_DIR}")
    print(" When you wake up, pick tasks and let Gemini 3.5 execute them!")
    print("==================================================")


if __name__ == "__main__":
    main()
