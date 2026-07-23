"""
gen_workflow.py — Patches n8n_overnight_workflow.json to add:
  1. "Loop Over Topics"  (splitInBatches) — explicit 1-at-a-time topic loop
  2. "Loop Over Tasks"   (splitInBatches) — explicit 1-at-a-time task loop
  3. "Task Session Memory" (memoryBufferWindow) — per-task memory for executor
  4. Prompt fix for Planner + Reviewer LLM Chain nodes
  5. topicKey/filename reference fixes in Code nodes
"""
import json, copy

SRC = r'c:\horaizon-3.0\tools\n8n_overnight_workflow.json'

with open(SRC, 'r', encoding='utf-8-sig') as f:
    wf = json.load(f)

nodes = wf['nodes']
conns = wf['connections']

def find(name):
    return next(n for n in nodes if n['name'] == name)

# ── 1. Fix Planner LLM Chain ── add prompt expression ─────────────────────────
find('Planner LLM Chain')['parameters']['prompt'] = '={{ $json.plannerPrompt }}'

# ── 2. Fix Reviewer LLM Chain ── add prompt expression ────────────────────────
find('Reviewer LLM Chain')['parameters']['prompt'] = (
    "=You are a senior software architect reviewing a task spec for horAIzon 3.0.\n\n"
    "Rate it 1-10. Reply ONLY with valid JSON (no markdown fences, no extra text):\n"
    "{\"score\": 8, \"verdict\": \"pass\", \"reason\": \"Well-scoped and clear.\"}\n\n"
    "Rules:\n"
    "- verdict = \"pass\" when score >= 7\n"
    "- verdict = \"fail\" when score < 7\n\n"
    "TASK TO REVIEW:\n"
    "{{ $json.task_markdown }}"
)

# ── 3. Fix Parse + Write Task Files ── use loop node ref ──────────────────────
parse = find('Parse + Write Task Files')
parse['parameters']['jsCode'] = parse['parameters']['jsCode'].replace(
    "const topicKey = $('Load Context').first().json.topicKey;",
    "const topicKey = $('Loop Over Topics').item.json.topicKey;"
)

# ── 4. Fix Archive Completed Task ── use loop node ref ────────────────────────
archive = find('Archive Completed Task')
archive['parameters']['jsCode'] = archive['parameters']['jsCode'].replace(
    "const taskFile = $('Load Active Tasks').first().json.filename;",
    "const taskFile = $('Loop Over Tasks').item.json.filename;"
)

# ── 5. Fix Executor Agent text ── use loop node ref ───────────────────────────
executor = find('Executor AI Agent')
executor['parameters']['text'] = (
    "={{ 'Execute this task completely. Repo root: c:\\\\horaizon-3.0\\n\\n'"
    " + $(\"Loop Over Tasks\").item.json.content"
    " + '\\n\\nWhen done: use run_command to run git add -A then git commit with message"
    ": feat: complete ' + $(\"Loop Over Tasks\").item.json.taskId }}"
)

# ── 6. Add Loop Over Topics node ───────────────────────────────────────────────
loop_topics = {
    "parameters": {"batchSize": 1, "options": {}},
    "type": "n8n-nodes-base.splitInBatches",
    "typeVersion": 3,
    "position": [-1792, 16],
    "id": "loop-over-topics",
    "name": "Loop Over Topics"
}
nodes.append(loop_topics)

# ── 7. Add Loop Over Tasks node ────────────────────────────────────────────────
loop_tasks = {
    "parameters": {"batchSize": 1, "options": {}},
    "type": "n8n-nodes-base.splitInBatches",
    "typeVersion": 3,
    "position": [32, 16],
    "id": "loop-over-tasks",
    "name": "Loop Over Tasks"
}
nodes.append(loop_tasks)

# ── 8. Add Window Buffer Memory for Executor ───────────────────────────────────
memory = {
    "parameters": {
        "sessionIdType": "customKey",
        "sessionKey": "={{ $('Loop Over Tasks').item.json.taskId || 'default' }}",
        "contextWindowLength": 20
    },
    "type": "@n8n/n8n-nodes-langchain.memoryBufferWindow",
    "typeVersion": 1.3,
    "position": [368, 420],
    "id": "task-session-memory",
    "name": "Task Session Memory"
}
nodes.append(memory)

# ── 9. Rewire connections ──────────────────────────────────────────────────────

# Load Context → Loop Over Topics (was: → Planner LLM Chain)
conns['Load Context']['main'] = [[{"node": "Loop Over Topics", "type": "main", "index": 0}]]

# Loop Over Topics: output 0 (loop) → Planner, output 1 (done) → Load Active Tasks
conns['Loop Over Topics'] = {
    "main": [
        [{"node": "Planner LLM Chain", "type": "main", "index": 0}],   # loop
        [{"node": "Load Active Tasks",  "type": "main", "index": 0}]   # done
    ]
}

# Promote to Active → loop back to Loop Over Topics
conns['Promote to Active']['main'] = [[{"node": "Loop Over Topics", "type": "main", "index": 0}]]

# Flag for Review → loop back to Loop Over Topics
conns['Flag for Review']['main']   = [[{"node": "Loop Over Topics", "type": "main", "index": 0}]]

# Load Active Tasks → Loop Over Tasks (was: → Skip Manual Tasks?)
conns['Load Active Tasks']['main'] = [[{"node": "Loop Over Tasks", "type": "main", "index": 0}]]

# Loop Over Tasks: output 0 (loop) → Skip Manual Tasks?, output 1 (done) → [end]
conns['Loop Over Tasks'] = {
    "main": [
        [{"node": "Skip Manual Tasks?", "type": "main", "index": 0}],  # loop
        []                                                              # done (workflow ends)
    ]
}

# Skip Manual Tasks?: TRUE (don't skip) → Executor, FALSE (skip) → loop back
conns['Skip Manual Tasks?']['main'] = [
    [{"node": "Executor AI Agent",  "type": "main", "index": 0}],     # TRUE: execute
    [{"node": "Loop Over Tasks",    "type": "main", "index": 0}]      # FALSE: skip → next
]

# Archive Completed Task → loop back to Loop Over Tasks
conns.setdefault('Archive Completed Task', {})['main'] = [[{"node": "Loop Over Tasks", "type": "main", "index": 0}]]

# Task Session Memory → Executor AI Agent (ai_memory sub-node)
conns['Task Session Memory'] = {
    "ai_memory": [[{"node": "Executor AI Agent", "type": "ai_memory", "index": 0}]]
}

# ── 10. Write output ───────────────────────────────────────────────────────────
with open(SRC, 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"[gen_workflow] Done — {len(nodes)} nodes, workflow saved to:\n  {SRC}")
