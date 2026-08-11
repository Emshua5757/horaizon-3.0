# TASK-018 — `shua_diary` JBC MCP Server & Ollama/Gemini Tool Calling Engine

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 3 |
| **Type** | AI-executable |
| **Language** | TypeScript (Node.js) |
| **Target** | `shua_modules/shua_diary/src/ai/` |
| **Blocks** | TASK-019 |
| **Prerequisites** | TASK-017 (`shua_diary` Backend), TASK-006 (Ollama Lifecycle), TASK-006B (Governor MCP Router), `_architecture/contracts/mcp/mcp_master_spec.md` |
| **References** | `_architecture/contracts/mcp/mcp_master_spec.md` |

---

## Architectural Directives (ADR-001 & MCP Architecture)

> [!IMPORTANT]
> **JBC IS NOW THE JOSH BLOCK COMPILER MCP SERVER.**
> - In 2.0, JBC was a custom string bytecode syntax requiring regex parsing (`JbcTranslator.ts`, `selfHealLine.ts`).
> - **In 3.0, JBC becomes a standard MCP Server (`JbcMcpServer`)**.
> - Instead of teaching models a custom bytecode string format, **JBC exposes native MCP Tools and Resources** using standard JSON schemas (`@modelcontextprotocol/sdk`).
> - Both local **Ollama** (via `shua_governor` AI Intent Router) and **Gemini** (cloud fallback) call these MCP tools directly via native LLM Function Calling!
> - **NO Python Subprocesses. NO N8n Webhooks.**

---

## JBC MCP Tools Exposed (`src/ai/jbc_mcp_tools.ts`)

| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| `diary_create_block` | `{ entry_id, block_type, content, lexo_rank? }` | Inserts a new native block widget (markdown, code, image, checklist, etc.) into an entry |
| `diary_update_block` | `{ block_id, content }` | Updates block content |
| `diary_delete_block` | `{ block_id }` | Deletes a block from an entry |
| `diary_reorder_blocks` | `{ entry_id, block_ids }` | Reorders blocks in an entry using LexoRank |
| `diary_synthesize_notes` | `{ raw_text, user_id }` | Converts raw text notes or voice note transcripts into structured entry blocks |
| `diary_analyze_entry` | `{ entry_id }` | Analyzes entry text for mood score (1-10), energy level, and key tags |

---

## JBC MCP Resources Exposed (`src/ai/jbc_mcp_resources.ts`)

| Resource URI | Description |
| :--- | :--- |
| `diary://entries/{id}` | Read entry title, metadata, and list of native blocks |
| `diary://entries/latest` | Read most recent entry for active user |
| `diary://mood/timeline` | Read mood score history and heatmap dataset |

---

## Key Modules & Components (`src/ai/`)

1. **`JbcMcpServer` (`src/ai/jbc_mcp_server.ts`)**:
   - Manages MCP JSON-RPC protocol over WebSocket / stdio. Registers all JBC tools and resources.
2. **`DiaryAiSession` (`src/ai/diary_ai_session.ts`)**:
   - Manages active user AI chat sessions, persistent model preferences, and provider switching.
3. **Ollama MCP Tool Provider (`src/ai/providers/ollama_mcp_provider.ts`)**:
   - Sends user chat prompts to Ollama with `diaryMcpTools` definitions; executes called tools via `JbcMcpServer`.
4. **Gemini MCP Tool Provider (`src/ai/providers/gemini_mcp_provider.ts`)**:
   - Cloud fallback tool calling provider.
5. **Background Analysis Worker (`src/ai/analysis_worker.ts`)**:
   - Asynchronous queue executing `diary_analyze_entry` in the background after entry edits.
6. **Monthly Synthesis Governor Job (`src/ai/monthly_synthesis.ts`)**:
   - Triggered on the 1st of each month via `shua_governor` Dream Loop scheduler to synthesize monthly summary entries.

---

## Tool Calling Engine & Loop Engineering (`src/ai/tool_loop_engine.ts`)

> [!TIP]
> **Pure Code Tool Loop (Zero N8n Dependency)**:
> Interactive tool calling is a synchronous low-latency cycle. Wrapping this in external N8n webhooks introduces unnecessary HTTP node roundtrips and Docker overhead. `shua_diary` executes tool loops directly in Node.js/TypeScript using the native `runToolLoop` engine.

```typescript
export async function runToolLoop(
  prompt: string,
  tools: McpTool[],
  options: ToolLoopOptions = { maxIterations: 5, model: "qwen2.5:4b" }
): Promise<ToolLoopResult> {
  // 1. Check SQLite Hash Cache
  const cacheKey = hashPayload(options.model, prompt);
  const cached = await getCachedInference(cacheKey);
  if (cached) return cached;

  // 2. Pre-segmentation pass (Fast heuristic/regex - non-LLM)
  const segments = preSegmentRawNotes(prompt);

  // 3. Prepare byte-identical static prompt prefix for Ollama KV-cache reuse
  let messages: ChatMessage[] = [
    { role: "system", content: DIARY_SYSTEM_PROMPT_STATIC },
    { role: "user", content: prompt }
  ];

  let iterations = 0;
  let retries = 0;

  while (iterations < options.maxIterations) {
    iterations++;

    // 4. Schema-constrained LLM Sampling via Ollama
    const response = await ollama.chat({
      model: options.model,
      messages,
      tools,
      format: "json", // Constrains sampling to valid JSON tool call schemas
    });

    if (!response.message.tool_calls?.length) {
      const result = { status: "completed", content: response.message.content };
      await setCachedInference(cacheKey, result);
      return result;
    }

    for (const call of response.message.tool_calls) {
      // 5. Pre-execution schema validation
      const validation = validateAgainstSchema(call.function.arguments, toolSchemas[call.function.name]);

      if (!validation.ok) {
        retries++;
        if (retries >= 2) {
          // 6. Confidence-Gated Fallback: Mark block unverified instead of full failure
          const fallbackResult = await executeToolWithFallback(call.function.name, call.function.arguments, { unverified: true });
          messages.push({ role: "assistant", tool_calls: [call] });
          messages.push({ role: "tool", tool_call_id: call.id, content: JSON.stringify(fallbackResult) });
          continue;
        }

        messages.push({ role: "assistant", tool_calls: [call] });
        messages.push({ role: "tool", tool_call_id: call.id, content: JSON.stringify({ error: true, validation: validation.errors }) });
        continue;
      }

      // 7. Execute MCP Tool Call & emit Telemetry
      const result = await executeMcpTool(call.function.name, call.function.arguments);
      emitTelemetryLog("info", "TAG_AI_INFERENCE", { tool: call.function.name, trace_id: generateTraceId() });

      messages.push({ role: "assistant", tool_calls: [call] });
      messages.push({ role: "tool", tool_call_id: call.id, content: JSON.stringify(result) });
    }
  }

  // 8. Circuit Breaker trigger on max iterations reached
  emitTelemetryLog("warn", "TAG_AI_INFERENCE", { warning: "Tool loop exceeded max iterations ceiling", iterations });
  return { status: "partial_success", content: "Completed available blocks with unverified flags." };
}
```

---

## RPC Endpoints Added to WebSocket Data API

- `diary.ai.chat`: Interactive streaming chat session with MCP tool execution.
- `diary.ai.generate_from_notes`: Synthesizes raw text or voice transcripts into entry blocks.
- `diary.ai.analyze`: Queues background sentiment and mood analysis.
- `diary.ai.monthly_synthesis`: Generates monthly synthesis entry.
- `diary.ai.get_config` / `diary.ai.save_config`: Persistent user AI model preferences.

---

## Acceptance Criteria

- [ ] `JbcMcpServer` implements MCP standard using `@modelcontextprotocol/sdk`
- [ ] Exposes all 6 `diary_*` MCP tools with JSON schemas
- [ ] Exposes `diary://` MCP resources
- [ ] `runToolLoop` engine enforces max iterations ceiling ($K=5$) and schema validation
- [ ] Incorporates confidence-gated fallback (`unverified: true`) on 2nd retry attempt
- [ ] Implements Ollama KV-cache optimization via byte-identical system prompt headers
- [ ] Caches deterministic tool outcomes in SQLite (`activity.db`)
- [ ] Emits structured `TAG_AI_INFERENCE` telemetry logs with `trace_id` for every tool execution
- [ ] Ollama provider executes MCP tool calls natively (zero regex string parsing)
- [ ] Gemini cloud fallback provider executes identical MCP tools
- [ ] Analysis worker processes queued jobs asynchronously
- [ ] Monthly synthesis triggers cleanly from governor scheduler
- [ ] Zero N8n or Python process dependencies
- [ ] `0` TypeScript compiler errors or warnings

