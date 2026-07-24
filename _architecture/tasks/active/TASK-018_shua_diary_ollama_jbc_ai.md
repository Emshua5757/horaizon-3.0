# TASK-018 — `shua_diary` Ollama AI Session & Block Mutation Engine

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 3 |
| **Type** | AI-executable |
| **Language** | TypeScript (Node.js) |
| **Target** | `shua_modules/shua_diary/src/ai/` |
| **Blocks** | TASK-019 |
| **Prerequisites** | TASK-017 (`shua_diary` Backend), TASK-006 (Ollama Lifecycle & AI Router) |
| **References** | `_architecture/reference/shua_diary.md` |

---

## Architectural Directives (ADR-001 & horAIzon 3.0 Clean Stack)

> [!IMPORTANT]
> **NO Python Subprocesses. NO N8n Webhooks.**
> - 2.0 `N8nJbcProvider` is **dropped** (unnecessary external webhook dependency).
> - 2.0 `PythonSemanticsAnalyzerProvider` is **dropped** (fragile Python process on ARM).
> - **AI Strategy**: Pure Ollama (via `shua_governor` AI Intent Router) for all JBC block mutations, note generation, embeddings (`nomic-embed-text`), and sentiment analysis.
> - Cloud Fallback: Gemini provider when cloud AI is explicitly requested.

---

## Key Modules & Components (`src/ai/`)

1. **`DiaryAiSession` (`src/ai/diary_ai_session.ts`)**:
   - Manages active user AI sessions, persistent config, and provider instantiation.
2. **Ollama JBC / Block Mutation Engine (`src/ai/providers/ollama_jbc_provider.ts`)**:
   - Converts natural language instructions into structured block mutation commands (`create_block`, `update_block`, `delete_block`, `reorder_block`).
3. **Diary Generator Provider (`src/ai/providers/ollama_generator_provider.ts`)**:
   - Synthesizes raw text notes or voice note audio transcripts into structured diary entries.
4. **Sentiment & Mood Analyzer (`src/ai/providers/ollama_analyzer_provider.ts`)**:
   - Analyzes entry text to extract mood scores (1-10), energy levels, and key themes.
5. **Background Analysis Worker (`src/ai/analysis_worker.ts`)**:
   - Asynchronous worker queue processing entry analysis in the background without blocking RPC responses.
6. **Monthly Synthesis Governor Job (`src/ai/monthly_synthesis.ts`)**:
   - Triggered on the 1st of each month via `shua_governor` Dream Loop scheduler to generate monthly summary entries.
7. **Gemini Fallback Providers**:
   - `GeminiJbcProvider`, `GeminiGeneratorProvider`, `GeminiAnalyzerProvider`.

---

## RPC Endpoints Added to WebSocket API

- `diary.ai.jbc_chat`: Streaming / single-shot JBC block mutation execution.
- `diary.ai.generate_from_notes`: Synthesizes raw notes or transcripts into entry blocks.
- `diary.ai.analyze`: Queues background sentiment and mood analysis.
- `diary.ai.monthly_synthesis`: Generates monthly synthesis entry.
- `diary.ai.get_config` / `diary.ai.save_config`: Persistent user AI preferences.

---

## Acceptance Criteria

- [ ] AI session initializes cleanly in Node.js backend with persistent config
- [ ] JBC block compiler converts natural language to structured block ops
- [ ] Sentiment & mood analyzer computes scores and updates entry metadata
- [ ] Analysis worker processes queued jobs asynchronously
- [ ] Monthly synthesis triggers cleanly from governor scheduler
- [ ] Zero N8n or Python process dependencies
- [ ] `0` TypeScript compiler errors or warnings
