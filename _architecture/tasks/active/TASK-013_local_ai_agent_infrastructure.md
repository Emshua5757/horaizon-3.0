# TASK-013 — Local AI Agent Infrastructure (n8n + Ollama + RAG + Multi-Agent Pipeline)

> **Merged from:** TASK-013 (Docker/Qdrant/RAG/Executor) + TASK-015 (Native n8n Multi-Agent Planner Loop)

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Deferred — not started |
| **Phase** | Phase 2 — Infrastructure |
| **Type** | AI-executable + Manual validation |
| **Language** | Docker / Python / n8n (JavaScript Code nodes) |
| **Target** | `c:\horaizon-3.0\tools\n8n_agent\` |
| **Blocks** | Nothing — runs alongside all other phases |
| **Prerequisites** | Docker Desktop installed, Ollama running locally, n8n at `localhost:5678` |

---

## Context

The goal is a **24/7 offline AI agent loop** that continuously improves the horAIzon 3.0 codebase when idle or sleeping — no internet required. The system has two modes:

- **Planner Mode** (overnight / idle): Reads architecture specs, existing tasks, and code context via RAG, then generates new `TASK-XXX.md` proposal files using local Ollama. A **Reviewer Agent** critiques each generated task before saving — routing good tasks to `proposed/` and bad ones to `review_needed/` for human inspection.
- **Executor Mode** (when a task is explicitly approved): Feeds a task file to `aider` + local Ollama and executes it.

The visual orchestration layer is **n8n** (self-hosted), which handles scheduling, RAG retrieval, and workflow chaining. The vector store is **Qdrant** (local Docker). Embeddings use `nomic-embed-text` (already installed).

> **Note:** `overnight_planner.py` remains as a standalone fallback. The n8n multi-agent workflow will eventually replace it — but both coexist until the n8n workflow is verified end-to-end.

---

## Architecture Diagram

```
[ Repo Files / Specs / Logs ]
        │
        ▼  (Indexing Workflow — runs on file change or schedule)
[ n8n: Indexer Workflow ]
        │  chunks files → nomic-embed-text → Qdrant
        ▼
[ Qdrant Vector Store :6333 ]
        │
        ▼  (Planner Workflow — runs nightly at 22:00)
[ n8n: Multi-Agent Planner Workflow ]
        │
        ├──► Agent 1 (Planner):  Ollama → drafts TASK-XXX.md
        │
        ├──► Agent 2 (Reviewer): Ollama → critiques task (score 1-10, verdict pass/fail)
        │
        ├──► IF score >= 7 & verdict == pass
        │       TRUE  ──► _architecture/tasks/proposed/
        │       FALSE ──► _architecture/tasks/review_needed/
        │
        ▼
[ _architecture/tasks/proposed/ ]
        │
        ▼  (Manual review by Joshua — approve tasks → move to active/)
[ _architecture/tasks/active/ ]
        │
        ▼  (Executor Workflow — triggered on idle detection or manually)
[ n8n: Executor Workflow ]
        │  reads task → aider + Ollama → code written + committed
        ▼
[ shua_governor / client_flutter / etc. ]
```

---

## Part A — Docker Compose Setup

### Step A1: Create `tools/n8n_agent/docker-compose.yml`

```yaml
version: "3.9"

services:

  # ---- n8n: Visual workflow automation ----
  n8n:
    image: n8nio/n8n:latest
    container_name: horaizon_n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=shua
      - N8N_BASIC_AUTH_PASSWORD=horaizon3
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=Asia/Manila
      - TZ=Asia/Manila
      # Point n8n's Ollama node to host Ollama
      - OLLAMA_HOST=http://host.docker.internal:11434
    volumes:
      - n8n_data:/home/node/.n8n
      # Mount the repo so n8n can read/write task files directly
      - c:/horaizon-3.0:/workspace
    extra_hosts:
      - "host.docker.internal:host-gateway"

  # ---- Qdrant: Local vector store for RAG ----
  qdrant:
    image: qdrant/qdrant:latest
    container_name: horaizon_qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"   # REST API
      - "6334:6334"   # gRPC
    volumes:
      - qdrant_data:/qdrant/storage

volumes:
  n8n_data:
  qdrant_data:
```

### Step A2: Start the stack

```powershell
cd c:\horaizon-3.0\tools\n8n_agent
docker compose up -d

# Verify both containers are running
docker compose ps
```

Expected output:
```
NAME                STATUS    PORTS
horaizon_n8n        running   0.0.0.0:5678->5678/tcp
horaizon_qdrant     running   0.0.0.0:6333->6333/tcp
```

Open n8n at: http://localhost:5678
Login: `shua` / `horaizon3`

---

## Part B — RAG Indexer Workflow

This n8n workflow runs on a schedule (every hour) and indexes these file paths into Qdrant:

| Source | Path Pattern | Why |
|---|---|---|
| Architecture specs | `_architecture/specs/**/*.md` | Gives planner context of modules |
| Contracts | `_architecture/contracts/**/*.md` | HBP v2 spec awareness |
| Active tasks | `_architecture/tasks/active/*.md` | Know what's already assigned |
| Progress logs | `_architecture/progress/*.md` | Know what's been done |
| Source code | `shua_governor/src/**/*.rs` | Code understanding |
| Source code | `client_flutter/lib/**/*.dart` | Flutter code context |

### Step B1: Workflow structure

```
[Cron Trigger: every 1 hour]
        │
        ▼
[Read Files Node]
  - Path: /workspace/_architecture/**/*.md
  - Path: /workspace/shua_governor/src/**/*.rs
  - Path: /workspace/client_flutter/lib/**/*.dart
        │
        ▼
[Text Splitter Node]
  - Chunk size: 800 tokens
  - Overlap: 80 tokens
        │
        ▼
[Embeddings: Ollama Node]
  - Model: nomic-embed-text
  - Base URL: http://host.docker.internal:11434
        │
        ▼
[Qdrant Vector Store: Upsert]
  - Collection: horaizon_codebase
  - URL: http://qdrant:6333
```

### Step B2: Create the Qdrant collection (once)

```powershell
$body = @{
    vectors = @{
        size = 768          # nomic-embed-text output dimension
        distance = "Cosine"
    }
} | ConvertTo-Json -Depth 5

Invoke-RestMethod `
    -Uri "http://localhost:6333/collections/horaizon_codebase" `
    -Method PUT `
    -Body $body `
    -ContentType "application/json"
```

---

## Part C — Multi-Agent Planner Workflow (replaces `overnight_planner.py`)

Runs nightly at 22:00 (Asia/Manila). Uses RAG to retrieve context, then runs a **two-agent loop**: Planner drafts tasks, Reviewer critiques them before saving.

### Step C1: Create `_architecture/tasks/review_needed/` folder

```powershell
New-Item -ItemType Directory -Force -Path "c:\horaizon-3.0\_architecture\tasks\review_needed"
```

### Step C2: Workflow structure

```
[Schedule Trigger: 22:00]
        │
        ▼
[Code: Read Repo Index]
  Reads _architecture/repo_index.md → passes as context string
        │
        ▼
[Code: Read Existing Tasks]
  Lists all files in active/ and proposed/ → avoids duplicates
        │
        ▼
[Code: Build Topic Queue]
  Returns array from planner_queue.txt: [{key, description}, ...]
        │
        ▼
[Loop Over Items: one topic at a time]
        │
        ├──►[HTTP Request → Ollama: PLANNER]
        │    POST http://localhost:11434/api/generate
        │    model: qwen2.5-coder:7b
        │    stream: false, num_ctx: 8192, temperature: 0.2
        │    prompt: topic + repo_index + existing_tasks
        │
        ├──►[Code: Parse Task Blocks]
        │    Split on ---START_TASK--- / ---END_TASK---
        │    Extract title, determine next TASK-XXX ID
        │
        ├──►[HTTP Request → Ollama: REVIEWER]
        │    POST http://localhost:11434/api/generate
        │    System: "You are a senior architect reviewing a task spec."
        │    Prompt: "Rate 1-10. Detailed enough? Scoped to one session?
        │             Free of conflicts? Follows TASK-XXX format?
        │             Reply ONLY JSON: {score, verdict: pass|fail, reason}"
        │
        ├──►[Code: Parse Review JSON]
        │    Extracts score and verdict; defaults to fail if unparseable
        │
        ├──►[IF: verdict == 'pass' AND score >= 7]
        │    TRUE  ──► [Code: Write to proposed/]
        │    FALSE ──► [Code: Write to review_needed/] + append rejection reason
        │
        └──► Loop continues with next topic
```

### Step C3: Parse Review JSON (Code node)

```javascript
const raw = $input.first().json.response;
// Strip markdown code fences if model wraps in ```json
const clean = raw.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
try {
  const review = JSON.parse(clean);
  return [{ json: { ...review, task_markdown: $('Parse Task Blocks').first().json.task_markdown } }];
} catch(e) {
  // If model returned garbage, default to fail so human reviews it
  return [{ json: { score: 0, verdict: 'fail', reason: 'Reviewer returned unparseable response: ' + raw.slice(0, 200), task_markdown: $('Parse Task Blocks').first().json.task_markdown } }];
}
```

### Step C4: Write Task Files (Code node — both branches)

**Pass branch (→ proposed/):**
```javascript
const fs = require('fs');
const path = require('path');
const proposed = 'c:\\horaizon-3.0\\_architecture\\tasks\\proposed';
const filename = $input.first().json.filename;
const content  = $input.first().json.task_markdown;
fs.mkdirSync(proposed, { recursive: true });
fs.writeFileSync(path.join(proposed, filename), content, 'utf8');
return [{ json: { written: filename, destination: 'proposed' } }];
```

**Fail branch (→ review_needed/):**
```javascript
const fs = require('fs');
const path = require('path');
const reviewDir = 'c:\\horaizon-3.0\\_architecture\\tasks\\review_needed';
const filename = $input.first().json.filename;
const content  = $input.first().json.task_markdown + '\n\n---\n## Reviewer Rejection\n' + $input.first().json.reason;
fs.mkdirSync(reviewDir, { recursive: true });
fs.writeFileSync(path.join(reviewDir, filename), content, 'utf8');
return [{ json: { written: filename, destination: 'review_needed', reason: $input.first().json.reason } }];
```

### Step C5: Create `tools/n8n_agent/planner_queue.txt`

```text
phase2_code_visualizer_flutter_screen
phase3_resume_go_backend
phase3_resume_typst_compiler
phase3_diary_typescript_backend
phase3_diary_sentiment_engine
phase3_diary_global_identity_matrix
phase3_gym_workout_tracker
phase3_crypto_portfolio_tracker
infra_qdrant_vector_compaction
infra_global_identity_matrix_schema
```

---

## Part D — Executor Workflow (Idle-Triggered)

### Step D1: Idle detection script `tools/n8n_agent/idle_monitor.py`

```python
"""
idle_monitor.py — Detects Windows idle time and triggers n8n executor webhook.

Runs as a background process. When the system is idle for > 15 minutes,
it hits the n8n executor webhook to start coding a proposed task.
"""
import time
import urllib.request
import json
import ctypes

N8N_EXECUTOR_WEBHOOK = "http://localhost:5678/webhook/executor"
IDLE_THRESHOLD_MINUTES = 15
CHECK_INTERVAL_SECONDS = 60

class LASTINPUTINFO(ctypes.Structure):
    _fields_ = [("cbSize", ctypes.c_uint), ("dwTime", ctypes.c_ulong)]

def get_idle_seconds() -> float:
    lii = LASTINPUTINFO()
    lii.cbSize = ctypes.sizeof(LASTINPUTINFO)
    ctypes.windll.user32.GetLastInputInfo(ctypes.byref(lii))
    millis = ctypes.windll.kernel32.GetTickCount() - lii.dwTime
    return millis / 1000.0

def trigger_executor(task_file: str) -> None:
    payload = json.dumps({"task_file": task_file}).encode("utf-8")
    req = urllib.request.Request(
        N8N_EXECUTOR_WEBHOOK,
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    try:
        urllib.request.urlopen(req, timeout=10)
        print(f"[idle_monitor] Triggered executor for: {task_file}")
    except Exception as e:
        print(f"[idle_monitor] Trigger failed: {e}")

def get_next_proposed_task() -> str | None:
    from pathlib import Path
    proposed = sorted(
        Path("_architecture/tasks/proposed").glob("TASK-*.md")
    )
    return str(proposed[0]) if proposed else None

def main() -> None:
    print(f"[idle_monitor] Watching for {IDLE_THRESHOLD_MINUTES}min idle...")
    triggered_this_session = set()

    while True:
        idle = get_idle_seconds()
        if idle >= IDLE_THRESHOLD_MINUTES * 60:
            task = get_next_proposed_task()
            if task and task not in triggered_this_session:
                print(f"[idle_monitor] Idle {idle:.0f}s — triggering task: {task}")
                trigger_executor(task)
                triggered_this_session.add(task)
        time.sleep(CHECK_INTERVAL_SECONDS)

if __name__ == "__main__":
    main()
```

### Step D2: Executor Workflow structure in n8n

```
[Webhook Trigger: POST /webhook/executor]
  - Receives: { "task_file": "path/to/TASK-XXX_...md" }
        │
        ▼
[Qdrant: Vector Search]
  - Query: task title + context section
  - Top K: 8 most relevant chunks (additional RAG context for aider)
        │
        ▼
[Execute Command Node]
  - Command: python
  - Args: tools/overnight_agent.py {task_file} --model qwen2.5-coder:7b
  - Working dir: /workspace
        │
        ▼
[Code Node: Check exit code]
  - If success → move task to active/ (done)
  - If failure → write error to agent_logs/
        │
        ▼
[Write File Node: Update task status]
  - Marks task [x] Done or logs failure reason
```

---

## Part E — Windows Startup Integration

### Step E1: Create `tools/n8n_agent/start_agent_stack.ps1`

```powershell
# Start the full horAIzon offline AI agent stack
# Run this when you sit down at your computer or add to Windows startup

$repoRoot = "c:\horaizon-3.0"

Write-Host "[agent-stack] Starting horAIzon AI Agent Infrastructure..."

# 1. Start Ollama (if not already running)
$ollamaRunning = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if (-not $ollamaRunning) {
    Write-Host "[agent-stack] Starting Ollama..."
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Minimized
    Start-Sleep -Seconds 3
}

# 2. Start Docker containers (n8n + Qdrant)
Write-Host "[agent-stack] Starting Docker containers..."
Set-Location "$repoRoot\tools\n8n_agent"
docker compose up -d

# 3. Start idle monitor in background
Write-Host "[agent-stack] Starting idle monitor..."
Start-Process -FilePath "python" `
    -ArgumentList "$repoRoot\tools\n8n_agent\idle_monitor.py" `
    -WorkingDirectory $repoRoot `
    -WindowStyle Minimized

Write-Host ""
Write-Host "======================================"
Write-Host " Agent Stack Running!"
Write-Host "   n8n:    http://localhost:5678"
Write-Host "   Qdrant: http://localhost:6333"
Write-Host "======================================"
```

### Step E2: Add to Windows startup (optional)

```powershell
$startup = [System.Environment]::GetFolderPath("Startup")
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut("$startup\horaizon-agent-stack.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-WindowStyle Minimized -ExecutionPolicy Bypass -File c:\horaizon-3.0\tools\n8n_agent\start_agent_stack.ps1"
$shortcut.WorkingDirectory = "c:\horaizon-3.0"
$shortcut.Save()
Write-Host "Startup shortcut created."
```

---

## Part F — n8n Credentials Setup (first-time)

After `docker compose up`, open http://localhost:5678 and configure:

1. **Ollama Credential**:
   - Type: HTTP Header Auth
   - Name: `Local Ollama`
   - Base URL: `http://host.docker.internal:11434`

2. **Qdrant Credential**:
   - Type: Qdrant API
   - URL: `http://qdrant:6333`
   - API Key: (leave blank — local mode)

3. **Import workflows**: Use n8n's Import Workflow UI to load the JSON files from `tools/n8n_agent/workflows/`.

---

## Part G — Migrating from `overnight_planner.py`

Once the n8n multi-agent workflow is verified working end-to-end:

1. Rename `tools/overnight_planner.py` → `tools/overnight_planner.py.bak`
2. Update `start_n8n.ps1` docs to note the planner is now native n8n
3. Update `TASK_ORDER` comment in `overnight_agent.py`

> Until then, `overnight_planner.py` remains the fallback standalone planner.

---

## Acceptance Criteria

- [ ] `docker compose up -d` starts both `horaizon_n8n` and `horaizon_qdrant` cleanly
- [ ] n8n is accessible at http://localhost:5678 with correct credentials
- [ ] Qdrant collection `horaizon_codebase` is created and accepts vectors
- [ ] Indexer workflow runs and inserts architecture spec chunks into Qdrant
- [ ] Planner agent produces valid `---START_TASK---` / `---END_TASK---` formatted output
- [ ] Reviewer agent returns parseable JSON with `score` and `verdict` fields
- [ ] Tasks with `verdict: pass` and `score >= 7` land in `_architecture/tasks/proposed/`
- [ ] Tasks with `verdict: fail` land in `_architecture/tasks/review_needed/` with rejection reason appended
- [ ] No duplicate tasks generated (existing task list is injected into planner prompt)
- [ ] `idle_monitor.py` detects 15 minutes of idle and calls the webhook correctly
- [ ] Executor workflow receives webhook, runs `overnight_agent.py`, and marks task complete
- [ ] `start_agent_stack.ps1` starts all three services (Ollama, Docker, idle_monitor) in one command
- [ ] Full loop (index → plan → review → propose → execute) completes end-to-end with zero internet

---

## References

- `tools/overnight_planner.py` — standalone planner fallback (no n8n dependency)
- `tools/overnight_agent.py` — standalone executor (called by n8n executor workflow)
- `_architecture/contracts/hbp/hbp_v2_spec.md` — context for planner RAG queries
- `_architecture/specs/` — all module specs fed into Qdrant index
