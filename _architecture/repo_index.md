# horAIzon 3.0 - Repository Index
Generated: 2026-07-22T19:04:38
Files: 45

> Inject as first context file so 8b models can reason about the full repo.

---

| File | Lang | Size | Summary | Key Symbols |
| :--- | :--- | ---: | :--- | :--- |
| `tools/__init__.py` | Python | 0.0k | tools package |  |
| `tools/n8n_overnight_workflow.json` | JSON | 5.5k | "name": "horAIzon — Overnight Loop Engineering", |  |
| `tools/overnight_agent.py` | Python | 16.7k | overnight_agent.py — horAIzon 3.0 autonomous coding agent | find_task_file, get_task_status, mark_task_status, get_task_title, read_task_content, check_ollama, check_aider, build_aider_message |
| `tools/overnight_planner.py` | Python | 8.2k | overnight_planner.py — horAIzon 3.0 Local Spec & Task Generator | get_existing_tasks, call_ollama, parse_and_save_tasks, main |
| `tools/repo_index.py` | Python | 4.7k | ﻿#!/usr/bin/env python3 |  |
| `tools/schedule_overnight.ps1` | PowerShell | 2.4k | schedule_overnight.ps1 |  |
| `tools/setup_overnight_agent.py` | Python | 7.2k | setup_overnight_agent.py — One-time setup for the horAIzon overnight agent. | run, detect_vram_gb, recommend_model, step_install_aider, step_check_ollama, step_pull_model, step_write_aider_config, step_smoke_test |
| `tools/start_n8n.ps1` | PowerShell | 1.5k | ﻿# start_n8n.ps1 |  |
| `tools/toggle_view.py` | Python | 3.4k | import os | main |
| `tools/sync_contracts/__init__.py` | Python | 0.3k | from tools.sync_contracts import parser |  |
| `tools/sync_contracts/__main__.py` | Python | 4.6k | __main__.py — CLI entry point for sync_contracts. | resolve_output_root, main |
| `tools/sync_contracts/parser.py` | Python | 4.3k | parser.py — HBP v2 schema loader | EnumVariant, HbpEnum, StructField, HbpStruct, HbpOperation, HbpProtocol, load |
| `tools/sync_contracts/generators/__init__.py` | Python | 0.5k | from tools.sync_contracts.generators.dart_gen       import DartGenerator |  |
| `tools/sync_contracts/generators/base.py` | Python | 3.3k | base.py — Abstract base class for all HBP v2 language generators. | BaseGenerator |
| `tools/sync_contracts/generators/dart_gen.py` | Python | 7.8k | dart_gen.py — Generates Dart HBP v2 contract files. | DartGenerator, _camel, _snake |
| `tools/sync_contracts/generators/go_gen.py` | Python | 4.0k | go_gen.py — Generates Go HBP v2 contract files. | GoGenerator, _snake, _pascal |
| `tools/sync_contracts/generators/python_gen.py` | Python | 6.8k | python_gen.py — Generates Python HBP v2 contract files. | PythonGenerator, _snake, _upper |
| `tools/sync_contracts/generators/rust_gen.py` | Python | 5.0k | rust_gen.py — Generates Rust HBP v2 contract files. | RustGenerator, _snake |
| `tools/sync_contracts/generators/typescript_gen.py` | Python | 4.5k | typescript_gen.py — Generates TypeScript HBP v2 contract files. | TypeScriptGenerator, _snake, _camel |
| `tools/sync_contracts/schema/hbp_operations.toml` | TOML | 13.3k | ============================================================================= |  |
| `_architecture/contracts/hbp/hbp_v2_spec.md` | Markdown | 10.1k | HBP v2 — horAIzon Binary Protocol Specification |  |
| `_architecture/decisions/ADR-001_native_over_sdui.md` | Markdown | 4.9k | ADR-001 — Native Flutter over SDUI-4 |  |
| `_architecture/progress/week_01_2026-07-21.md` | Markdown | 4.3k | Week 01 Progress — 2026-07-21 |  |
| `_architecture/reference/client_flutter.md` | Markdown | 193.6k | ﻿# Repository Export |  |
| `_architecture/reference/horAIzon_2_0_full_topology.md` | Markdown | 599.9k | ﻿# Repository Export |  |
| `_architecture/reference/shua_code_visualizer.md` | Markdown | 31.0k | ﻿# Repository Export |  |
| `_architecture/reference/shua_diary.md` | Markdown | 84.5k | ﻿# Repository Export |  |
| `_architecture/reference/shua_governor.md` | Markdown | 31.5k | ﻿# Repository Export |  |
| `_architecture/reference/shua_resume.md` | Markdown | 18.7k | ﻿# Repository Export |  |
| `_architecture/specs/client_flutter/client_flutter_spec.md` | Markdown | 10.6k | client_flutter — Specification |  |
| `_architecture/specs/shua_governor/shua_governor_spec.md` | Markdown | 12.4k | shua_governor — Specification |  |
| `_architecture/tasks/active/TASK-001_pi5_ssh_and_cleanup.md` | Markdown | 4.9k | TASK-001 — Pi5 SSH Setup + horAIzon 2.0 Cleanup |  |
| `_architecture/tasks/active/TASK-002_vscode_workspace_setup.md` | Markdown | 4.6k | TASK-002 — VSCode Workspace Setup |  |
| `_architecture/tasks/active/TASK-003_governor_cargo_scaffold.md` | Markdown | 7.8k | TASK-003 — `shua_governor` Cargo Scaffold |  |
| `_architecture/tasks/active/TASK-004_governor_hbp_broker.md` | Markdown | 14.4k | TASK-004 — `shua_governor` HBP v2 Frame + WebSocket Broker |  |
| `_architecture/tasks/active/TASK-005_governor_process_registry.md` | Markdown | 12.1k | TASK-005 — `shua_governor` Process Registry + cgroups v2 |  |
| `_architecture/tasks/active/TASK-006_governor_ollama_ai_dreamloop.md` | Markdown | 13.9k | TASK-006 — `shua_governor` Ollama Lifecycle + AI Router + Dream Loop |  |
| `_architecture/tasks/active/TASK-007_governor_config_systemd_deploy.md` | Markdown | 8.7k | TASK-007 — `shua_governor` config.toml + systemd Deploy to Pi5 |  |
| `_architecture/tasks/active/TASK-008_flutter_project_scaffold.md` | Markdown | 6.8k | TASK-008 — `client_flutter` Project Scaffold + pubspec |  |
| `_architecture/tasks/active/TASK-009_flutter_hbp_client.md` | Markdown | 14.4k | TASK-009 — `client_flutter` HBP v2 Client |  |
| `_architecture/tasks/active/TASK-010_flutter_router_splash_theme.md` | Markdown | 13.2k | TASK-010 — `client_flutter` GoRouter + SplashScreen + Theme System |  |
| `_architecture/tasks/active/TASK-011_flutter_dashboard_governor_screens.md` | Markdown | 20.5k | TASK-011 — `client_flutter` DashboardScreen + GovernorScreens |  |
| `_architecture/tasks/active/TASK-012_flutter_settings_connection_banner.md` | Markdown | 13.4k | TASK-012 — `client_flutter` SettingsScreen + Connection Banner |  |
| `_architecture/tasks/active/TASK-013_local_ai_agent_infrastructure.md` | Markdown | 13.6k | TASK-013 — Local AI Agent Infrastructure (n8n + Ollama + RAG Pipeline) |  |
| `_architecture/tasks/proposed/TASK-014_shua_aspnet_portal.md` | Markdown | 3.6k | ﻿# TASK-014 — C# ASP.NET Core Interview Prep Portal (shua_portal) |  |
