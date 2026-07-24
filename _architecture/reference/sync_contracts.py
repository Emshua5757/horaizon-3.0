#!/usr/bin/env python3
"""
tools/sync_contracts.py — Universal Schema Synchronization & Code Generation Tool
Version: 4.0.0 (SDUI-4 Renderer Paradigm)
Repository: horAIzon 2.0

Reads 'schemas/communication_contracts.json' and generates strongly-typed,
auto-formatted constant definition files across all 5 language targets in
the monorepo. Run this after any change to communication_contracts.json.

Usage:
    python sync_contracts.py              # Generate all language targets
    python sync_contracts.py --dart       # Generate Dart only
    python sync_contracts.py --python     # Generate Python only
    python sync_contracts.py --dry-run    # Print all outputs without writing files
    python sync_contracts.py --validate   # Validate schema integrity only

Design Rules (enforced in generated code):
    - All constants are immutable (final/const/static readonly/freeze/frozen)
    - All files have a DO-NOT-EDIT header with generation timestamp
    - Group comments are preserved from schema to generated file
    - Naming: SCREAMING_SNAKE_CASE for integer constants, PascalCase for classes
"""

import os
import sys
import json
import argparse
import subprocess
from datetime import datetime, timezone

# ─────────────────────────────────────────────────────────────
# PATHS — All relative to the monorepo root
# ─────────────────────────────────────────────────────────────

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCHEMA_DIR = os.path.join(REPO_ROOT, "schemas", "contracts")
STATE_FILE_PATH = os.path.join(REPO_ROOT, "tools", ".sync_state.json")

TARGET_OUTPUTS = {
    "dart":       os.path.join(REPO_ROOT, "client_flutter", "lib", "core", "network", "hbp_constants.g.dart"),
    "java":       os.path.join(REPO_ROOT, "shua_modules", "shua_gym_vision", "src", "HbpConstants.java"),
    "csharp":     os.path.join(REPO_ROOT, "shua_modules", "shua_crypto", "Models", "HbpConstants.cs"),
    "typescript": os.path.join(REPO_ROOT, "shua_modules", "shua_diary", "src", "models", "HbpConstants.ts"),
    "python":     os.path.join(REPO_ROOT, "core_backend", "app", "core", "hbp_constants.py"),
    "go":         os.path.join(REPO_ROOT, "shua_modules", "shua_resume", "pkg", "models", "hbp_constants.go"),
}

GEN_TIMESTAMP = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


# ─────────────────────────────────────────────────────────────
# SCHEMA LOADER & VALIDATOR
# ─────────────────────────────────────────────────────────────

def deep_merge(target: dict, source: dict):
    for k, v in source.items():
        if isinstance(v, dict) and k in target and isinstance(target[k], dict):
            deep_merge(target[k], v)
        else:
            target[k] = v

def load_schema() -> dict:
    """Reads and deep-merges all modular schemas from schemas/contracts/."""
    if not os.path.exists(SCHEMA_DIR):
        raise FileNotFoundError(f"[ERROR] Schema directory not found: {SCHEMA_DIR}\n  Run from monorepo root or check path.")
    
    merged_schema = {}
    for filename in sorted(os.listdir(SCHEMA_DIR)):
        if filename.endswith(".json"):
            filepath = os.path.join(SCHEMA_DIR, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                data = json.load(f)
                deep_merge(merged_schema, data)
    return merged_schema


def validate_schema(schema: dict) -> list[str]:
    """
    Validates schema integrity. Returns a list of error strings.
    Checks: required top-level keys, duplicate integer IDs within namespaces,
    key/value type consistency, reserved ID ranges.
    """
    errors = []
    required_keys = ["_meta", "hbp_frame", "rpc_methods", "sdui_spec",
                     "high_frequency_telemetry", "database_tables", "module_registry",
                     "log_levels", "log_tags"]
    for key in required_keys:
        if key not in schema:
            errors.append(f"Missing required top-level key: '{key}'")

    # Check for duplicate integer IDs in rpc_methods
    rpc = {k: v for k, v in schema.get("rpc_methods", {}).get("mappings", {}).items()
           if not k.startswith("_")}
    seen_ids = {}
    for method, id_val in rpc.items():
        if not isinstance(id_val, int):
            errors.append(f"rpc_methods.mappings['{method}'] must be an int, got {type(id_val).__name__}")
            continue
        if id_val in seen_ids:
            errors.append(f"Duplicate RPC ID {id_val}: '{method}' conflicts with '{seen_ids[id_val]}'")
        seen_ids[id_val] = method

    # Check for duplicate widget type IDs
    widgets = schema.get("sdui_spec", {}).get("widget_types", {})
    seen_widgets = {}
    for name, wid in widgets.items():
        if name.startswith("_"):
            continue
        if wid in seen_widgets:
            errors.append(f"Duplicate SDUI widget ID {wid}: '{name}' conflicts with '{seen_widgets[wid]}'")
        seen_widgets[wid] = name

    # Check label/value collision in sdui_spec properties
    for cat in ["node_structure", "behavior_axes", "content_keys"]:
        props = {k: v for k, v in schema.get("sdui_spec", {}).get(cat, {}).items() if not k.startswith("_")}
        seen = {}
        for prop, pid in props.items():
            if pid in seen:
                errors.append(f"Duplicate {cat} ID {pid}: '{prop}' conflicts with '{seen[pid]}'")
            seen[prop] = pid

    # Validate log levels
    log_levels = schema.get("log_levels", {})
    seen_levels = {}
    for name, lid in log_levels.items():
        if name.startswith("_"):
            continue
        if not isinstance(lid, int) or lid <= 0:
            errors.append(f"log_levels['{name}'] must be a positive int, got {lid}")
            continue
        if lid in seen_levels:
            errors.append(f"Duplicate log level value {lid}: '{name}' conflicts with '{seen_levels[lid]}'")
        seen_levels[lid] = name

    # Validate log tags (must be power of two)
    log_tags = schema.get("log_tags", {})
    seen_tags = {}
    for name, tag_val in log_tags.items():
        if name.startswith("_"):
            continue
        if not isinstance(tag_val, int) or tag_val <= 0:
            errors.append(f"log_tags['{name}'] must be a positive int, got {tag_val}")
            continue
        if (tag_val & (tag_val - 1)) != 0:
            errors.append(f"log_tags['{name}'] must be a power of two flag (got {tag_val})")
            continue
        if tag_val in seen_tags:
            errors.append(f"Duplicate log tag value {tag_val}: '{name}' conflicts with '{seen_tags[tag_val]}'")
        seen_tags[tag_val] = name

    return errors


# ─────────────────────────────────────────────────────────────
# UTILITY
# ─────────────────────────────────────────────────────────────

def _ensure_dir(filepath: str):
    """Creates parent directories if they don't exist."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)


def _write_or_print(filepath: str, content: str, dry_run: bool, lang: str):
    """Writes content to file, or prints to stdout if dry_run is True."""
    if dry_run:
        print(f"\n{'='*70}")
        print(f"  DRY RUN — {lang.upper()} → {os.path.relpath(filepath, REPO_ROOT)}")
        print(f"{'='*70}")
        print(content)
    else:
        _ensure_dir(filepath)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        rel = os.path.relpath(filepath, REPO_ROOT)
        print(f"  [OK] {lang.upper():<12} -> {rel}")


def _rpc_methods(schema: dict) -> dict:
    """Returns only integer-valued RPC method entries (strips _group_* comments)."""
    return {k: v for k, v in schema["rpc_methods"]["mappings"].items()
            if not k.startswith("_") and isinstance(v, int)}


def _to_screaming_snake(name: str) -> str:
    """
    'shua.diary.log_entry' → 'SHUA_DIARY_LOG_ENTRY'
    'STREAM_CHUNK' → 'STREAM_CHUNK'
    """
    return name.upper().replace(".", "_").replace("-", "_")


def _to_pascal_case(name: str) -> str:
    """
    'shua.diary.log_entry' → 'ShuaDiaryLogEntry'
    'STREAM_CHUNK' → 'StreamChunk'
    """
    s = name.replace(".", "_").replace("-", "_")
    parts = s.split("_")
    return "".join(p.capitalize() for p in parts if p)


# ─────────────────────────────────────────────────────────────
# GENERATOR: DART
# ─────────────────────────────────────────────────────────────

def generate_dart(schema: dict, dry_run: bool):
    """
    Generates: client_flutter/lib/core/network/hbp_constants.g.dart
    
    Pattern:
        abstract final class HbpMessageType { static const int HANDSHAKE = 0x00; ... }
        abstract final class HbpRpcMethod   { static const int CORE_CHAT_SEND_MESSAGE = 10; ... }
        abstract final class HbpWidget      { static const int COLUMN = 1; ... }
        abstract final class HbpLayout      { static const int TYPE = 0; ... }
        abstract final class HbpDbTable     { static const int USERS = 1; ... }
        abstract final class HbpModule      { static const int CORE_CHAT = 0; ... }
        abstract final class HbpIntent      { static const int CHAT = 0; ... }
    """
    lines = [
        "// AUTO-GENERATED FILE — DO NOT EDIT MANUALLY.",
        f"// Generated by tools/sync_contracts.py on {GEN_TIMESTAMP}",
        "// Source: schemas/communication_contracts.json",
        "// To update: modify the source schema and re-run sync_contracts.py",
        "",
        "// ignore_for_file: constant_identifier_names",
        "",
        "import 'package:flutter/material.dart';",
        "",
    ]

    # HBP Message Types
    lines += ["/// HBP frame message type constants (Byte 3 of the 12-byte header).",
              "abstract final class HbpMessageType {"]
    for name, hex_val in schema["hbp_frame"]["message_types"].items():
        if name.startswith("_"):
            continue
        int_val = int(hex_val, 16)
        lines.append(f"  static const int {_to_screaming_snake(name)} = {int_val}; // {hex_val}")
    lines += ["}", ""]

    # HBP Error Categories
    lines += ["/// HBP error category constants (Byte 0 of the 0x03 Error payload).",
              "abstract final class HbpErrorCategory {"]
    for name, hex_val in schema["hbp_frame"]["error_categories"].items():
        if name.startswith("_"):
            continue
        int_val = int(hex_val, 16)
        lines.append(f"  static const int {_to_screaming_snake(name)} = {int_val}; // {hex_val}")
    lines += ["}", ""]

    # RPC Methods
    lines += ["/// Integer RPC method IDs (Key `0` of 0x01 REQUEST payload).",
              "abstract final class HbpRpcMethod {"]
    rpc_entries = _rpc_methods(schema)
    for name, id_val in rpc_entries.items():
        lines.append(f"  static const int {_to_screaming_snake(name)} = {id_val};")
    lines.append("")
    lines.append("  /// Zero-maintenance O(1) lookup: RPC integer ID → wire method name string.")
    lines.append("  /// Auto-generated from communication_contracts.json — do NOT edit manually.")
    lines.append("  /// Usage: HbpRpcMethod.names[methodId] in SduiEventDispatcher.")
    lines.append("  static const Map<int, String> names = {")
    for name, id_val in sorted(rpc_entries.items(), key=lambda x: x[1]):
        lines.append(f"    {id_val}: '{name}',")
    lines.append("  };")
    lines += ["}", ""]

    # RPC Param Keys
    lines += ["/// Integer parameter keys (inside Key `1` params map of 0x01 REQUEST).",
              "abstract final class HbpParamKey {"]
    param_keys = schema["rpc_request_keys"]["param_keys"]
    for name, id_val in param_keys.items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {id_val};")
    lines += ["}", ""]

    # SDUI Widgets
    lines += ["/// SDUI widget type integer IDs (Key `1` of SDUI payload).",
              "abstract final class HbpWidget {"]
    for name, wid in schema["sdui_spec"]["widget_types"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {wid};")
    lines += ["}", ""]

    # SDUI Node Structure
    lines += ["/// SDUI core node structure integer keys.",
              "abstract final class HbpNode {"]
    for name, pid in schema["sdui_spec"]["node_structure"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {pid};")
    lines += ["}", ""]

    # SDUI Behavior Axes
    lines += ["/// SDUI behavior axis integer keys.",
              "abstract final class HbpBehavior {"]
    for name, pid in schema["sdui_spec"]["behavior_axes"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {pid};")
    lines += ["}", ""]

    # SDUI Content Keys
    lines += ["/// SDUI content integer keys.",
              "abstract final class HbpContent {"]
    for name, pid in schema["sdui_spec"]["content_keys"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {pid};")
    lines += ["}", ""]

    # SDUI Action Types
    lines += ["/// SDUI action type integer IDs.",
              "abstract final class HbpActionType {"]
    for name, aid in schema["sdui_spec"]["action_types"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {aid};")
    lines += ["}", ""]

    # ── V4 Enum Value Classes ─────────────────────────────────────
    def _emit_dart_enum_class(class_name: str, doc: str, values_dict: dict) -> list:
        block = [f"/// {doc}", f"abstract final class {class_name} {{"]
        for name, val in values_dict.items():
            if name.startswith("_"):
                continue
            block.append(f"  static const int {_to_screaming_snake(name)} = {val};")
        block += ["}", ""]
        return block

    sdui = schema["sdui_spec"]

    lines += _emit_dart_enum_class("HbpDisplayMode",
        "Values for behavior key 100 (display_mode) on MarkdownEditor.",
        sdui.get("display_mode_values", {}))

    lines += _emit_dart_enum_class("HbpInteractiveMode",
        "Values for behavior key 95 (interactive_mode). Universal across all stateful primitives.",
        sdui.get("interactive_mode_values", {}))

    lines += _emit_dart_enum_class("HbpLayoutDir",
        "Values for behavior key 10 (layout_direction) on Container.",
        sdui.get("layout_direction_values", {}))

    lines += _emit_dart_enum_class("HbpAlignment",
        "Values for main_axis_alignment (11) and cross_axis_alignment (12) on Container.",
        sdui.get("alignment_values", {}))

    lines += _emit_dart_enum_class("HbpOverflow",
        "Values for behavior key 15 (overflow) on Container.",
        sdui.get("overflow_values", {}))

    lines += _emit_dart_enum_class("HbpClipBehavior",
        "Values for behavior key 26 (clip_behavior) on Container.",
        sdui.get("clip_behavior_values", {}))

    lines += _emit_dart_enum_class("HbpInputType",
        "Values for behavior key 41 (input_type) on TextInput.",
        sdui.get("input_type_values", {}))

    lines += _emit_dart_enum_class("HbpKeyboardType",
        "Values for behavior key 42 (keyboard_type) on TextInput.",
        sdui.get("keyboard_type_values", {}))

    lines += _emit_dart_enum_class("HbpListStyle",
        "Values for behavior key 60 (list_style) on ListEditor.",
        sdui.get("list_style_values", {}))

    lines += _emit_dart_enum_class("HbpBulletStyle",
        "Values for behavior key 61 (bullet_style) on ListEditor.",
        sdui.get("bullet_style_values", {}))

    lines += _emit_dart_enum_class("HbpScrollDir",
        "Values for behavior key 50 (scroll_direction) on ListView and GridView.",
        sdui.get("scroll_direction_values", {}))

    lines += _emit_dart_enum_class("HbpOrdinalMode",
        "Values for behavior key 119 (ordinal_mode) on OrdinalSlider.",
        sdui.get("ordinal_mode_values", {}))

    lines += _emit_dart_enum_class("HbpSliderMode",
        "Values for behavior key 122 (slider_mode) on Slider.",
        sdui.get("slider_mode_values", {}))

    lines += _emit_dart_enum_class("HbpPickerMode",
        "Values for behavior key 135 (picker_mode) on DatePicker and TimePicker.",
        sdui.get("picker_mode_values", {}))

    lines += _emit_dart_enum_class("HbpProgressMode",
        "Values for behavior key 123 (progress_mode) on ProgressBar. null value = indeterminate.",
        sdui.get("progress_mode_values", {}))

    lines += _emit_dart_enum_class("HbpButtonVariant",
        "Values for behavior key 112 (button_variant) on Button.",
        sdui.get("button_variant_values", {}))

    lines += _emit_dart_enum_class("HbpChipMode",
        "Values for behavior key 113 (chip_mode) on Chip.",
        sdui.get("chip_mode_values", {}))

    lines += _emit_dart_enum_class("HbpMountAnim",
        "Values for behavior keys 80 (mount_anim) and 81 (exit_anim) on Container.",
        sdui.get("mount_anim_values", {}))

    lines += _emit_dart_enum_class("HbpAnimCurve",
        "Values for behavior key 83 (anim_curve) on Container.",
        sdui.get("anim_curve_values", {}))

    lines += _emit_dart_enum_class("HbpSyncStrategy",
        "Values for behavior key 90 (sync_strategy) on ListView and GridView.",
        sdui.get("sync_strategy_values", {}))

    lines += _emit_dart_enum_class("HbpShimmerType",
        "Values for behavior key 91 (shimmer_type) on ShimmerLoader and ListView.",
        sdui.get("shimmer_type_values", {}))

    lines += _emit_dart_enum_class("HbpShimmerAnim",
        "Values for behavior key 92 (shimmer_anim_style) on ShimmerLoader.",
        sdui.get("shimmer_anim_style_values", {}))

    lines += _emit_dart_enum_class("HbpTextStyle",
        "Values for behavior key 103 (text_style). Maps to Flutter TextTheme slots.",
        sdui.get("text_style_values", {}))

    lines += _emit_dart_enum_class("HbpTextAlign",
        "Values for behavior key 102 (text_align) on MarkdownEditor and TextInput.",
        sdui.get("text_align_values", {}))

    lines += _emit_dart_enum_class("HbpColorToken",
        "Named color token indices (0-99). Values >= 0xFF000000 are raw ARGB.",
        sdui.get("color_tokens", {}))

    lines += _emit_dart_enum_class("HbpCodeLang",
        "Values for behavior key 110 (code_language) on CodeEditor. 20 syntax rulesets.",
        sdui.get("code_language_values", {}))

    # Database Tables
    lines += ["/// Integer table IDs for 0x11 STATE_SYNC delta payloads.",
              "abstract final class HbpDbTable {"]
    for name, tid in schema["database_tables"]["mappings"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {tid};")
    lines += ["}", ""]

    # Module Registry
    lines += ["/// S.H.U.A. module integer IDs.",
              "abstract final class HbpModule {"]
    for name, mid in schema["module_registry"]["modules"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {mid};")
    lines += ["}", ""]

    # Platform Types
    lines += ["/// Device platform type integer IDs.",
              "abstract final class HbpPlatform {"]
    for name, pid in schema["module_registry"]["platform_types"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {pid};")
    lines += ["}", ""]

    # Intent Classification
    lines += ["/// LLM intent classification output integer IDs.",
              "abstract final class HbpIntent {"]
    for name, iid in schema["intent_classification"]["intents"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {iid};")
    lines += ["}", ""]

    # Log Levels
    lines += ["/// Predefined HBP logging levels as compact integers.",
              "abstract final class HbpLogLevel {"]
    for name, lid in schema["log_levels"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {lid};")
    lines += ["}", ""]

    # Log Tags
    lines += ["/// 24-bit predefined system log tag bitmask flags.",
              "abstract final class HbpLogTag {"]
    for name, tag_val in schema["log_tags"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  static const int {_to_screaming_snake(name)} = {tag_val};")
    lines += ["}", ""]

    # Dynamic Theme Resolver Mapping HbpColorToken to Flutter ColorScheme slots
    lines += [
        "/// Helper to map HbpColorToken integer values to Material ColorScheme colors.",
        "Color? resolveHbpColorToken(BuildContext context, int token) {",
        "  final cs = Theme.of(context).colorScheme;",
        "  return switch (token) {",
    ]
    color_tokens = schema["sdui_spec"]["color_tokens"]
    for name, tid in color_tokens.items():
        if name.startswith("_"):
            continue
        const_name = _to_screaming_snake(name)
        if name == "transparent":
            lines.append(f"    HbpColorToken.{const_name} => Colors.transparent,")
        else:
            parts = name.split('_')
            camel_name = parts[0] + ''.join(x.title() for x in parts[1:])
            lines.append(f"    HbpColorToken.{const_name} => cs.{camel_name},")
    lines += [
        "    _ => null,",
        "  };",
        "}",
        ""
    ]

    content = "\n".join(lines) + "\n"
    _write_or_print(TARGET_OUTPUTS["dart"], content, dry_run, "dart")


# ─────────────────────────────────────────────────────────────
# GENERATOR: JAVA
# ─────────────────────────────────────────────────────────────

def generate_java(schema: dict, dry_run: bool):
    """
    Generates: shua_modules/shua_gym_vision/src/HbpConstants.java
    Pattern: public final class HbpConstants { public static final int X = Y; }
    """
    lines = [
        "// AUTO-GENERATED FILE — DO NOT EDIT MANUALLY.",
        f"// Generated by tools/sync_contracts.py on {GEN_TIMESTAMP}",
        "// Source: schemas/communication_contracts.json",
        "",
        "package com.horaizon.gym;",
        "",
        "/** HBP protocol constants auto-generated from communication_contracts.json. */",
        "public final class HbpConstants {",
        "",
        "    // Prevent instantiation",
        "    private HbpConstants() {}",
        "",
        "    // ── HBP Message Types ───────────────────────────────────────",
    ]
    for name, hex_val in schema["hbp_frame"]["message_types"].items():
        if name.startswith("_"):
            continue
        int_val = int(hex_val, 16)
        lines.append(f"    public static final int MSG_{_to_screaming_snake(name)} = {int_val};")

    lines += ["", "    // ── RPC Method IDs ─────────────────────────────────────────"]
    for name, id_val in _rpc_methods(schema).items():
        lines.append(f"    public static final int RPC_{_to_screaming_snake(name)} = {id_val};")

    lines += ["", "    // ── SDUI Widget Types ──────────────────────────────────────"]
    for name, wid in schema["sdui_spec"]["widget_types"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public static final int WIDGET_{_to_screaming_snake(name)} = {wid};")

    lines += ["", "    // ── Telemetry: Gym Pose Keypoint Indices ───────────────────"]
    keypoints = schema["high_frequency_telemetry"]["gym_vision_pose"]["body_layout"]["keypoint_map"]
    for idx, joint_name in keypoints.items():
        const_name = joint_name.upper().replace(" ", "_")
        lines.append(f"    public static final int POSE_{const_name} = {idx};")

    lines += ["", "    // ── Module IDs ─────────────────────────────────────────────"]
    for name, mid in schema["module_registry"]["modules"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public static final int MODULE_{_to_screaming_snake(name)} = {mid};")

    lines += ["", "    // ── Database Table IDs ─────────────────────────────────────"]
    for name, tid in schema["database_tables"]["mappings"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public static final int TABLE_{_to_screaming_snake(name)} = {tid};")

    lines += ["", "    // ── Log Levels ─────────────────────────────────────────────"]
    for name, lid in schema["log_levels"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public static final int LOG_LEVEL_{_to_screaming_snake(name)} = {lid};")

    lines += ["", "    // ── Log Tags ───────────────────────────────────────────────"]
    for name, tag_val in schema["log_tags"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public static final int LOG_TAG_{_to_screaming_snake(name)} = {tag_val};")

    lines.append("}")
    content = "\n".join(lines) + "\n"
    _write_or_print(TARGET_OUTPUTS["java"], content, dry_run, "java")


# ─────────────────────────────────────────────────────────────
# GENERATOR: C#
# ─────────────────────────────────────────────────────────────

def generate_csharp(schema: dict, dry_run: bool):
    """
    Generates: shua_modules/shua_crypto/Models/HbpConstants.cs
    Pattern: public static class HbpConstants { public const int X = Y; }
    """
    lines = [
        "// AUTO-GENERATED FILE — DO NOT EDIT MANUALLY.",
        f"// Generated by tools/sync_contracts.py on {GEN_TIMESTAMP}",
        "// Source: schemas/communication_contracts.json",
        "",
        "namespace ShuaCrypto.Models;",
        "",
        "/// <summary>HBP protocol constants auto-generated from communication_contracts.json.</summary>",
        "public static class HbpConstants",
        "{",
        "    // ── HBP Message Types ───────────────────────────────────────",
    ]
    for name, hex_val in schema["hbp_frame"]["message_types"].items():
        if name.startswith("_"):
            continue
        int_val = int(hex_val, 16)
        lines.append(f"    public const int MSG_{_to_screaming_snake(name)} = {int_val};")

    lines += ["", "    // ── RPC Method IDs ─────────────────────────────────────────"]
    for name, id_val in _rpc_methods(schema).items():
        lines.append(f"    public const int RPC_{_to_screaming_snake(name)} = {id_val};")

    lines += ["", "    // ── SDUI Widget Types ──────────────────────────────────────"]
    for name, wid in schema["sdui_spec"]["widget_types"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public const int WIDGET_{_to_screaming_snake(name)} = {wid};")

    lines += ["", "    // ── Module IDs ─────────────────────────────────────────────"]
    for name, mid in schema["module_registry"]["modules"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public const int MODULE_{_to_screaming_snake(name)} = {mid};")

    lines += ["", "    // ── Database Table IDs ─────────────────────────────────────"]
    for name, tid in schema["database_tables"]["mappings"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public const int TABLE_{_to_screaming_snake(name)} = {tid};")

    lines += ["", "    // ── Intent Classification IDs ──────────────────────────────"]
    for name, iid in schema["intent_classification"]["intents"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public const int INTENT_{_to_screaming_snake(name)} = {iid};")

    lines += ["", "    // ── Log Levels ─────────────────────────────────────────────"]
    for name, lid in schema["log_levels"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public const int LOG_LEVEL_{_to_screaming_snake(name)} = {lid};")

    lines += ["", "    // ── Log Tags ───────────────────────────────────────────────"]
    for name, tag_val in schema["log_tags"].items():
        if name.startswith("_"):
            continue
        lines.append(f"    public const int LOG_TAG_{_to_screaming_snake(name)} = {tag_val};")

    lines.append("}")
    content = "\n".join(lines) + "\n"
    _write_or_print(TARGET_OUTPUTS["csharp"], content, dry_run, "csharp")


# ─────────────────────────────────────────────────────────────
# GENERATOR: TYPESCRIPT
# ─────────────────────────────────────────────────────────────

def generate_typescript(schema: dict, dry_run: bool):
    """
    Generates: shua_modules/shua_diary/src/models/HbpConstants.ts
    Pattern: export const HBP_MSG = Object.freeze({ HANDSHAKE: 0x00, ... } as const)
    Using `as const` + Object.freeze gives TS compile-time literal type narrowing.
    """
    lines = [
        "// AUTO-GENERATED FILE — DO NOT EDIT MANUALLY.",
        f"// Generated by tools/sync_contracts.py on {GEN_TIMESTAMP}",
        "// Source: schemas/communication_contracts.json",
        "",
    ]

    # Message Types
    lines += ["/** HBP frame message type byte constants. */",
              "export const HBP_MSG = Object.freeze({"]
    for name, hex_val in schema["hbp_frame"]["message_types"].items():
        if name.startswith("_"):
            continue
        int_val = int(hex_val, 16)
        lines.append(f"  {_to_screaming_snake(name)}: {int_val},  // {hex_val}")
    lines += ["} as const);", ""]

    # RPC Methods
    lines += ["/** Integer RPC method IDs. */",
              "export const HBP_RPC = Object.freeze({"]
    for name, id_val in _rpc_methods(schema).items():
        lines.append(f"  {_to_screaming_snake(name)}: {id_val},")
    lines += ["} as const);", ""]

    # SDUI Widgets
    lines += ["/** SDUI widget type integer IDs. */",
              "export const HBP_WIDGET = Object.freeze({"]
    for name, wid in schema["sdui_spec"]["widget_types"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  {_to_screaming_snake(name)}: {wid},")
    lines += ["} as const);", ""]

    # Node Structure
    lines += ["/** SDUI core node structure integer keys. */",
              "export const HBP_NODE = Object.freeze({"]
    for name, pid in schema["sdui_spec"]["node_structure"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  {_to_screaming_snake(name)}: {pid},")
    lines += ["} as const);", ""]

    # Behavior Axes
    lines += ["/** SDUI behavior axis integer keys. */",
              "export const HBP_BEHAVIOR = Object.freeze({"]
    for name, pid in schema["sdui_spec"]["behavior_axes"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  {_to_screaming_snake(name)}: {pid},")
    lines += ["} as const);", ""]

    # Content Keys
    lines += ["/** SDUI content integer keys. */",
              "export const HBP_CONTENT = Object.freeze({"]
    for name, pid in schema["sdui_spec"]["content_keys"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  {_to_screaming_snake(name)}: {pid},")
    lines += ["} as const);", ""]

    # Module IDs
    lines += ["/** S.H.U.A. module integer IDs. */",
              "export const HBP_MODULE = Object.freeze({"]
    for name, mid in schema["module_registry"]["modules"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  {_to_screaming_snake(name)}: {mid},")
    lines += ["} as const);", ""]

    # Intent IDs
    lines += ["/** LLM intent classifier output IDs. */",
              "export const HBP_INTENT = Object.freeze({"]
    for name, iid in schema["intent_classification"]["intents"].items():
        if name.startswith("_"):
            continue
        lines.append(f"  {_to_screaming_snake(name)}: {iid},")
    lines += ["} as const);", ""]

    # V4 Enum Value Objects for TypeScript
    def _emit_ts_const(const_name: str, doc: str, values_dict: dict) -> list:
        block = [f"/** {doc} */", f"export const {const_name} = Object.freeze({{"]  
        for name, val in values_dict.items():
            if name.startswith("_"):
                continue
            block.append(f"  {_to_screaming_snake(name)}: {val},")
        block += ["}  as const);", ""]
        return block

    sdui = schema["sdui_spec"]

    lines += _emit_ts_const("HBP_DISPLAY_MODE",   "Values for display_mode (100) on MarkdownEditor.",          sdui.get("display_mode_values", {}))
    lines += _emit_ts_const("HBP_INTERACTIVE",    "Values for interactive_mode (95). Universal stateful.",      sdui.get("interactive_mode_values", {}))
    lines += _emit_ts_const("HBP_LAYOUT_DIR",     "Values for layout_direction (10) on Container.",             sdui.get("layout_direction_values", {}))
    lines += _emit_ts_const("HBP_ALIGNMENT",      "Values for main/cross axis alignment (11/12) on Container.", sdui.get("alignment_values", {}))
    lines += _emit_ts_const("HBP_OVERFLOW",       "Values for overflow (15) on Container.",                     sdui.get("overflow_values", {}))
    lines += _emit_ts_const("HBP_INPUT_TYPE",     "Values for input_type (41) on TextInput.",                   sdui.get("input_type_values", {}))
    lines += _emit_ts_const("HBP_LIST_STYLE",     "Values for list_style (60) on ListEditor.",                  sdui.get("list_style_values", {}))
    lines += _emit_ts_const("HBP_ORDINAL_MODE",   "Values for ordinal_mode (119) on OrdinalSlider.",            sdui.get("ordinal_mode_values", {}))
    lines += _emit_ts_const("HBP_SLIDER_MODE",    "Values for slider_mode (122) on Slider.",                    sdui.get("slider_mode_values", {}))
    lines += _emit_ts_const("HBP_PICKER_MODE",    "Values for picker_mode (135) on DatePicker and TimePicker.", sdui.get("picker_mode_values", {}))
    lines += _emit_ts_const("HBP_PROGRESS_MODE",  "Values for progress_mode (123) on ProgressBar.",             sdui.get("progress_mode_values", {}))
    lines += _emit_ts_const("HBP_BUTTON_VARIANT", "Values for button_variant (112) on Button.",                 sdui.get("button_variant_values", {}))
    lines += _emit_ts_const("HBP_CHIP_MODE",      "Values for chip_mode (113) on Chip.",                        sdui.get("chip_mode_values", {}))
    lines += _emit_ts_const("HBP_MOUNT_ANIM",     "Values for mount_anim (80) / exit_anim (81) on Container.",  sdui.get("mount_anim_values", {}))
    lines += _emit_ts_const("HBP_SYNC_STRATEGY",  "Values for sync_strategy (90) on ListView/GridView.",        sdui.get("sync_strategy_values", {}))
    lines += _emit_ts_const("HBP_SHIMMER_TYPE",   "Values for shimmer_type (91) on ShimmerLoader.",             sdui.get("shimmer_type_values", {}))
    lines += _emit_ts_const("HBP_TEXT_STYLE",     "Values for text_style (103). Flutter TextTheme slots.",      sdui.get("text_style_values", {}))
    lines += _emit_ts_const("HBP_COLOR_TOKEN",    "Named color token indices 0-99. >= 0xFF000000 = raw ARGB.",  sdui.get("color_tokens", {}))
    lines += _emit_ts_const("HBP_CODE_LANG",      "Values for code_language (110) on CodeEditor.",              sdui.get("code_language_values", {}))

    # Log Levels
    lines += _emit_ts_const("HBP_LOG_LEVEL",      "Predefined HBP logging levels as compact integers.",         schema.get("log_levels", {}))

    # Log Tags
    lines += _emit_ts_const("HBP_LOG_TAG",        "24-bit predefined system log tag bitmask flags.",           schema.get("log_tags", {}))

    # Derived type unions for TypeScript type safety
    lines += [
        "// ── Derived TypeScript type unions ────────────────────────────────",
        "export type HbpMessageTypeValue  = typeof HBP_MSG[keyof typeof HBP_MSG];",
        "export type HbpRpcMethodValue    = typeof HBP_RPC[keyof typeof HBP_RPC];",
        "export type HbpWidgetTypeValue   = typeof HBP_WIDGET[keyof typeof HBP_WIDGET];",
        "export type HbpWidgetName        = keyof typeof HBP_WIDGET;",
        "export type HbpModuleValue       = typeof HBP_MODULE[keyof typeof HBP_MODULE];",
        "export type HbpIntentValue       = typeof HBP_INTENT[keyof typeof HBP_INTENT];",
        "export type HbpLogLevelValue     = typeof HBP_LOG_LEVEL[keyof typeof HBP_LOG_LEVEL];",
        "export type HbpLogTagValue       = typeof HBP_LOG_TAG[keyof typeof HBP_LOG_TAG];",
        "export type HbpDisplayModeValue  = typeof HBP_DISPLAY_MODE[keyof typeof HBP_DISPLAY_MODE];",
        "export type HbpListStyleValue    = typeof HBP_LIST_STYLE[keyof typeof HBP_LIST_STYLE];",
        "",
    ]

    content = "\n".join(lines) + "\n"
    _write_or_print(TARGET_OUTPUTS["typescript"], content, dry_run, "typescript")


# ─────────────────────────────────────────────────────────────
# Primitives
# ─────────────────────────────────────────────────────────────
def request_primitive(primitive_name: str, category: str, is_human: bool = False):
    try:
        import re
        schema = load_schema()
        # 1. Locate the dictionary we want to modify inside the schema
        sdui_spec = schema.get("sdui_spec", {})
        if category not in sdui_spec:
            print(f"  [ERROR] Category '{category}' does not exist in sdui_spec.")
            sys.exit(1)
            
        target_dict = sdui_spec[category]
        
        # 2. Strict Naming Validation
        if not re.match(r"^[A-Z][a-zA-Z0-9]*$", primitive_name):
            print(f"  [ERROR] Invalid primitive name '{primitive_name}'. Must start with a capital letter and contain only alphanumeric characters (PascalCase).")
            sys.exit(1)
            
        if len(primitive_name) < 3:
            print("  [ERROR] Primitive name must be at least 3 characters long.")
            sys.exit(1)
            
        banned_terms = {
            'test', 'temp', 'tmp', 'data', 'widget', 'block', 'thing', 'stuff',
            'debug', 'demo', 'example', 'custom', 'placeholder', 'dummy', 'item', 'value'
        }
        if primitive_name.lower() in banned_terms:
            print(f"  [ERROR] Banned vague name: '{primitive_name}'. Do not use vague placeholder names in the master schema.")
            sys.exit(1)
            
        # 3. Check for duplicates
        if primitive_name in target_dict:
            print(f"  [ERROR] '{primitive_name}' already exists in {category} with ID {target_dict[primitive_name]}.")
            sys.exit(1)
            
        # 4. Find the correct range allocation
        if is_human:
            # Human range [0, 199]
            ids_in_range = [val for key, val in target_dict.items() if not key.startswith("_") and isinstance(val, int) and 0 <= val <= 199]
            new_id = max(ids_in_range) + 1 if ids_in_range else 1
            if new_id > 199:
                print(f"  [FATAL] Human/Core range 0-199 is full! Cannot assign ID {new_id}.")
                sys.exit(1)
        else:
            # AI range [200, 255]
            ids_in_range = [val for key, val in target_dict.items() if not key.startswith("_") and isinstance(val, int) and 200 <= val <= 255]
            new_id = max(ids_in_range) + 1 if ids_in_range else 200
            if new_id > 255:
                print(f"  [FATAL] AI/Reserved range 200-255 is full! Cannot assign ID {new_id}.")
                sys.exit(1)
            if new_id < 200:
                print(f"  [FATAL] AI request validation error: calculated ID {new_id} is in human range.")
                sys.exit(1)
            
        print(f"  [ALLOCATION] Assigning ID {new_id} to '{primitive_name}'...")
        # 5. Rate Limiting Check
        state_file = STATE_FILE_PATH
        today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        
        state = {"date": today_str, "count": 0}
        if os.path.exists(state_file):
            with open(state_file, "r") as f:
                saved_state = json.load(f)
                # If it's the same day, grab the count
                if saved_state.get("date") == today_str:
                    state["count"] = saved_state.get("count", 0)
        
        if state["count"] >= 3:
            print("  [RATE LIMIT] You have exceeded the 3 primitives/day limit. Wait until tomorrow.")
            sys.exit(1)

        # 6. Apply the change to the schema
        target_dict[primitive_name] = new_id
        schema["_meta"]["last_updated"] = today_str
        
        # 7. Write the updated JSON back to the master file
        with open(SCHEMA_PATH, "w", encoding="utf-8") as f:
            json.dump(schema, f, indent=2)
            
        # 8. Update rate limit state
        state["count"] += 1
        with open(state_file, "w") as f:
            json.dump(state, f)
            
        print(f"  [SUCCESS] Added {primitive_name} = {new_id} to {category}.")
        
        # 9. Trigger the generation of all 5 languages
        print("  [SYNC] Running global compiler sync...")
        generate_dart(schema, False)
        generate_python(schema, False)
        generate_java(schema, False)
        generate_csharp(schema, False)
        generate_typescript(schema, False)
        
        # 10. Auto-Commit to Git
        try:
            print("  [GIT] Committing new primitive...")
            subprocess.run(["git", "add", SCHEMA_PATH], check=True)
            subprocess.run(["git", "commit", "-m", f"chore(contracts): add {primitive_name} primitive"], check=True)
        except Exception as e:
            print(f"  [GIT ERROR] Could not auto-commit: {e}")
            
    except Exception as e:
        print(f"  [FATAL] request_primitive failed: {e}")
        sys.exit(1)


def delete_primitive(primitive_name: str, category: str):
    try:
        schema = load_schema()
        sdui_spec = schema.get("sdui_spec", {})
        if category not in sdui_spec:
            print(f"  [ERROR] Category '{category}' does not exist in sdui_spec.")
            sys.exit(1)
            
        target_dict = sdui_spec[category]
        if primitive_name not in target_dict:
            print(f"  [ERROR] '{primitive_name}' does not exist in {category}.")
            sys.exit(1)
            
        del target_dict[primitive_name]
        
        # Update last_updated meta
        today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        schema["_meta"]["last_updated"] = today_str
        
        # Write schema back
        with open(SCHEMA_PATH, "w", encoding="utf-8") as f:
            json.dump(schema, f, indent=2)
            
        print(f"  [SUCCESS] Deleted {primitive_name} from {category}.")
        
        # Trigger global compiler sync
        print("  [SYNC] Running global compiler sync...")
        generate_dart(schema, False)
        generate_python(schema, False)
        generate_java(schema, False)
        generate_csharp(schema, False)
        generate_typescript(schema, False)
        
        # Auto-Commit to Git
        try:
            print("  [GIT] Committing deleted primitive...")
            subprocess.run(["git", "add", SCHEMA_PATH], check=True)
            subprocess.run(["git", "commit", "-m", f"chore(contracts): delete {primitive_name} primitive"], check=True)
        except Exception as e:
            print(f"  [GIT ERROR] Could not auto-commit: {e}")
            
    except Exception as e:
        print(f"  [FATAL] delete_primitive failed: {e}")
        sys.exit(1)



# ─────────────────────────────────────────────────────────────
# GENERATOR: PYTHON
# ─────────────────────────────────────────────────────────────

def generate_python(schema: dict, dry_run: bool):
    """
    Generates: core_backend/app/core/hbp_constants.py
    Pattern: Frozen dataclass-style using simple module-level constants grouped
    into namespace classes. Python does not have true compile-time constants,
    so we use __slots__-less classes with class-level attributes and a
    __setattr__ override to enforce immutability at runtime.
    """
    lines = [
        "# AUTO-GENERATED FILE — DO NOT EDIT MANUALLY.",
        f"# Generated by tools/sync_contracts.py on {GEN_TIMESTAMP}",
        "# Source: schemas/communication_contracts.json",
        '"""',
        "HBP protocol constants for the FastAPI core backend.",
        "All classes are runtime-immutable via __setattr__ override.",
        '"""',
        "from __future__ import annotations",
        "",
        "",
        "class _ImmutableNamespace:",
        '    """Base class that prevents attribute mutation after class definition."""',
        "    def __setattr__(self, name: str, value: object) -> None:",
        '        raise AttributeError(f"HBP constants are immutable. Cannot set \'{name}\'.")',
        "",
        "",
    ]

    def _write_class(class_name: str, comment: str, items: dict, prefix: str = ""):
        block = [
            f"class {class_name}(_ImmutableNamespace):",
            f'    """{comment}"""',
        ]
        for name, val in items.items():
            if name.startswith("_"):
                continue
            const_name = f"{prefix}{_to_screaming_snake(name)}" if prefix else _to_screaming_snake(name)
            if isinstance(val, str) and val.startswith("0x"):
                int_val = int(val, 16)
                block.append(f"    {const_name}: int = {int_val}  # {val}")
            elif isinstance(val, int):
                block.append(f"    {const_name}: int = {val}")
        block += ["", ""]
        return block

    lines += _write_class(
        "HbpMessageType",
        "HBP frame message type byte constants (Byte 3 of the 12-byte header).",
        schema["hbp_frame"]["message_types"]
    )
    lines += _write_class(
        "HbpErrorCategory",
        "HBP error category constants (Byte 0 of the 0x03 Error payload).",
        schema["hbp_frame"]["error_categories"]
    )
    lines += _write_class(
        "HbpRpcMethod",
        "Integer RPC method IDs (Key `0` of 0x01 REQUEST payload).",
        _rpc_methods(schema)
    )

    param_keys = {k: v for k, v in schema["rpc_request_keys"]["param_keys"].items()
                  if not k.startswith("_")}
    lines += _write_class(
        "HbpParamKey",
        "Integer parameter keys inside the 0x01 REQUEST params map.",
        param_keys
    )

    resp_statuses = schema["rpc_response_keys"]["status_values"]
    lines += _write_class(
        "HbpResponseStatus",
        "Integer status values in 0x02 RESPONSE payloads.",
        resp_statuses
    )

    widget_types = {k: v for k, v in schema["sdui_spec"]["widget_types"].items()
                    if not k.startswith("_")}
    lines += _write_class(
        "HbpWidget",
        "SDUI widget type integer IDs (Key `1` of SDUI payload).",
        widget_types
    )

    node_props = {k: v for k, v in schema["sdui_spec"]["node_structure"].items()
                  if not k.startswith("_")}
    lines += _write_class(
        "HbpNode",
        "SDUI core node structure integer keys.",
        node_props
    )

    behavior_props = {k: v for k, v in schema["sdui_spec"]["behavior_axes"].items()
                      if not k.startswith("_")}
    lines += _write_class(
        "HbpBehavior",
        "SDUI behavior axis integer keys.",
        behavior_props
    )

    content_props = {k: v for k, v in schema["sdui_spec"]["content_keys"].items()
                     if not k.startswith("_")}
    lines += _write_class(
        "HbpContent",
        "SDUI content integer keys.",
        content_props
    )

    action_types = {k: v for k, v in schema["sdui_spec"]["action_types"].items()
                    if not k.startswith("_")}
    lines += _write_class(
        "HbpActionType",
        "SDUI action type integer IDs.",
        action_types
    )

    db_tables = {k: v for k, v in schema["database_tables"]["mappings"].items()
                 if not k.startswith("_")}
    lines += _write_class(
        "HbpDbTable",
        "Integer table IDs for 0x11 STATE_SYNC delta payloads.",
        db_tables
    )

    modules = {k: v for k, v in schema["module_registry"]["modules"].items()
               if not k.startswith("_")}
    lines += _write_class(
        "HbpModule",
        "S.H.U.A. module integer IDs.",
        modules
    )

    platforms = {k: v for k, v in schema["module_registry"]["platform_types"].items()
                 if not k.startswith("_")}
    lines += _write_class(
        "HbpPlatform",
        "Device platform type integer IDs.",
        platforms
    )

    intents = {k: v for k, v in schema["intent_classification"]["intents"].items()
               if not k.startswith("_")}
    lines += _write_class(
        "HbpIntent",
        "LLM intent classification output integer IDs.",
        intents
    )

    log_levels = {k: v for k, v in schema["log_levels"].items()
                  if not k.startswith("_")}
    lines += _write_class(
        "HbpLogLevel",
        "Predefined HBP logging levels as compact integers.",
        log_levels
    )

    log_tags = {k: v for k, v in schema["log_tags"].items()
                if not k.startswith("_")}
    lines += _write_class(
        "HbpLogTag",
        "24-bit predefined system log tag bitmask flags.",
        log_tags
    )

    # Gym pose keypoints as a plain dict (not class) — used by the inference service
    lines += [
        "# Gym Vision pose keypoint index → joint name mapping",
        "# Used by the shua_gym_vision service to unpack the 212-byte binary pose buffer.",
        "GYM_POSE_KEYPOINTS: dict[int, str] = {",
    ]
    keypoints = schema["high_frequency_telemetry"]["gym_vision_pose"]["body_layout"]["keypoint_map"]
    for idx, name in keypoints.items():
        lines.append(f"    {idx}: \"{name}\",")
    lines += ["}", ""]

    # Container name registry as a plain dict — used by cgroups_monitor.py
    lines += [
        "# Docker container name registry",
        "# Used by cgroups_monitor.py to resolve module IDs to container names.",
        "CONTAINER_NAMES: dict[str, str] = {",
    ]
    container_names = schema["module_registry"]["container_names"]
    for key, container in container_names.items():
        if not key.startswith("_"):
            lines.append(f"    \"{key}\": \"{container}\",")
    lines += ["}", ""]

    content = "\n".join(lines) + "\n"
    _write_or_print(TARGET_OUTPUTS["python"], content, dry_run, "python")


# ─────────────────────────────────────────────────────────────
# GENERATOR: GO
# ─────────────────────────────────────────────────────────────

def generate_go(schema: dict, dry_run: bool):
    """
    Generates: shua_modules/shua_resume_builder/pkg/models/hbp_constants.go
    """
    lines = [
        "// AUTO-GENERATED FILE — DO NOT EDIT MANUALLY.",
        f"// Generated by tools/sync_contracts.py on {GEN_TIMESTAMP}",
        "// Source: schemas/communication_contracts.json",
        "// To update: modify the source schema and re-run sync_contracts.py",
        "",
        "package models",
        "",
        "const (",
    ]

    def _write_block(comment: str, items: dict, prefix: str):
        block = [f"\t// {comment}"]
        for name, val in items.items():
            if name.startswith("_"):
                continue
            const_name = f"{prefix}{_to_pascal_case(name)}"
            if isinstance(val, str) and val.startswith("0x"):
                int_val = int(val, 16)
                block.append(f"\t{const_name} = {int_val} // {val}")
            else:
                block.append(f"\t{const_name} = {val}")
        block.append("")
        return block

    lines += _write_block(
        "HBP frame message type byte constants (Byte 3 of the 12-byte header).",
        schema["hbp_frame"]["message_types"],
        "HbpMessageType"
    )
    lines += _write_block(
        "HBP error category constants (Byte 0 of the 0x03 Error payload).",
        schema["hbp_frame"]["error_categories"],
        "HbpErrorCategory"
    )
    lines += _write_block(
        "Integer RPC method IDs (Key `0` of 0x01 REQUEST payload).",
        _rpc_methods(schema),
        "HbpRpcMethod"
    )

    param_keys = {k: v for k, v in schema["rpc_request_keys"]["param_keys"].items() if not k.startswith("_")}
    lines += _write_block(
        "Integer parameter keys inside the 0x01 REQUEST params map.",
        param_keys,
        "HbpParamKey"
    )

    resp_statuses = schema["rpc_response_keys"]["status_values"]
    lines += _write_block(
        "Integer status values in 0x02 RESPONSE payloads.",
        resp_statuses,
        "HbpResponseStatus"
    )

    widget_types = {k: v for k, v in schema["sdui_spec"]["widget_types"].items() if not k.startswith("_")}
    lines += _write_block(
        "SDUI widget type integer IDs.",
        widget_types,
        "HbpWidget"
    )

    node_props = {k: v for k, v in schema["sdui_spec"]["node_structure"].items() if not k.startswith("_")}
    lines += _write_block(
        "SDUI core node structure integer keys.",
        node_props,
        "HbpNode"
    )

    behavior_props = {k: v for k, v in schema["sdui_spec"]["behavior_axes"].items() if not k.startswith("_")}
    lines += _write_block(
        "SDUI behavior axis integer keys.",
        behavior_props,
        "HbpBehavior"
    )

    content_props = {k: v for k, v in schema["sdui_spec"]["content_keys"].items() if not k.startswith("_")}
    lines += _write_block(
        "SDUI content integer keys.",
        content_props,
        "HbpContent"
    )

    action_types = {k: v for k, v in schema["sdui_spec"]["action_types"].items() if not k.startswith("_")}
    lines += _write_block(
        "SDUI action type integer IDs.",
        action_types,
        "HbpActionType"
    )

    db_tables = {k: v for k, v in schema["database_tables"]["mappings"].items() if not k.startswith("_")}
    lines += _write_block(
        "Integer table IDs for 0x11 STATE_SYNC delta payloads.",
        db_tables,
        "HbpDbTable"
    )

    modules = {k: v for k, v in schema["module_registry"]["modules"].items() if not k.startswith("_")}
    lines += _write_block(
        "S.H.U.A. module integer IDs.",
        modules,
        "HbpModule"
    )

    platforms = {k: v for k, v in schema["module_registry"]["platform_types"].items() if not k.startswith("_")}
    lines += _write_block(
        "Device platform type integer IDs.",
        platforms,
        "HbpPlatform"
    )

    intents = {k: v for k, v in schema["intent_classification"]["intents"].items() if not k.startswith("_")}
    lines += _write_block(
        "LLM intent classification output integer IDs.",
        intents,
        "HbpIntent"
    )

    log_levels = {k: v for k, v in schema["log_levels"].items() if not k.startswith("_")}
    lines += _write_block(
        "Predefined HBP logging levels as compact integers.",
        log_levels,
        "HbpLogLevel"
    )

    log_tags = {k: v for k, v in schema["log_tags"].items() if not k.startswith("_")}
    lines += _write_block(
        "24-bit predefined system log tag bitmask flags.",
        log_tags,
        "HbpLogTag"
    )

    lines += [")", ""]
    content = "\n".join(lines) + "\n"
    _write_or_print(TARGET_OUTPUTS["go"], content, dry_run, "go")


# ─────────────────────────────────────────────────────────────
# MAIN EXECUTOR
# ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="horAIzon 2.0 — Universal Schema Synchronization Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Example: python sync_contracts.py --dart --python --dry-run"
    )
    parser.add_argument("--dart",       action="store_true", help="Generate Dart constants")
    parser.add_argument("--java",       action="store_true", help="Generate Java constants")
    parser.add_argument("--csharp",     action="store_true", help="Generate C# constants")
    parser.add_argument("--typescript", action="store_true", help="Generate TypeScript constants")
    parser.add_argument("--python",     action="store_true", help="Generate Python constants")
    parser.add_argument("--go",         action="store_true", help="Generate Go constants")
    parser.add_argument("--dry-run",    action="store_true", help="Print output without writing files")
    parser.add_argument("--validate",   action="store_true", help="Validate schema integrity only")
    parser.add_argument("--request-primitive", type=str, help="Name of the new primitive to add (e.g. VideoPlayer)")
    parser.add_argument("--delete-primitive", type=str, help="Name of the primitive to delete (e.g. VideoPlayer)")
    parser.add_argument("--category", type=str, help="Category in sdui_spec (e.g. widget_types, layout_properties)")
    parser.add_argument("--request", action="store_true", help="Request primitive as a human developer (range 0-199)")
    args = parser.parse_args()

    # Check if the user passed the --request-primitive flag
    if args.request_primitive:
        if not args.category:
            print("  [ERROR] You must provide a --category (e.g. widget_types) when requesting a primitive.")
            sys.exit(1)
            
        # Call your new function!
        request_primitive(args.request_primitive, args.category, is_human=args.request)
        
        # We don't want to run the normal generation unless the function succeeds, 
        # so you might want to call generate_all from inside request_primitive() once it finishes.
        return

    # Check if the user passed the --delete-primitive flag
    if args.delete_primitive:
        if not args.category:
            print("  [ERROR] You must provide a --category (e.g. widget_types) when deleting a primitive.")
            sys.exit(1)
            
        # Call delete_primitive
        delete_primitive(args.delete_primitive, args.category)
        return


    # If no specific language flags, generate all
    generate_all = not any([args.dart, args.java, args.csharp, args.typescript, args.python, args.go])

    print("-" * 60)
    print("  horAIzon 2.0 -- Contract Sync Daemon")
    print(f"  Schema: {os.path.relpath(SCHEMA_DIR, REPO_ROOT)} (modular directory)")
    print(f"  Time:   {GEN_TIMESTAMP}")
    print("-" * 60)

    try:
        schema = load_schema()
        print(f"  [OK] Schema v{schema['_meta']['schema_version']} loaded.")
    except Exception as e:
        print(f"  [FATAL] {e}")
        sys.exit(1)

    # Validate
    errors = validate_schema(schema)
    if errors:
        print(f"\n  [SCHEMA ERRORS] Found {len(errors)} issue(s):")
        for err in errors:
            print(f"    ✗ {err}")
        if args.validate:
            sys.exit(1)
        print("  [WARNING] Proceeding with generation despite errors.")
    else:
        print("  [OK] Schema validation passed. No duplicate IDs or type errors.")

    if args.validate:
        print("  [DONE] Validation complete.")
        return

    print()
    if args.dry_run:
        print("  [DRY RUN] No files will be written.\n")

    try:
        if generate_all or args.dart:
            generate_dart(schema, args.dry_run)
        if generate_all or args.java:
            generate_java(schema, args.dry_run)
        if generate_all or args.csharp:
            generate_csharp(schema, args.dry_run)
        if generate_all or args.typescript:
            generate_typescript(schema, args.dry_run)
        if generate_all or args.python:
            generate_python(schema, args.dry_run)
        if generate_all or args.go:
            generate_go(schema, args.dry_run)
    except Exception as e:
        print(f"\n  [ERROR] Generation failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

    print()
    print("-" * 60)
    print("  [DONE] All codebase constants are in sync.")
    if not args.dry_run:
        print("  Commit scope: chore(contracts): sync-hbp-constants")
    print("-" * 60)


if __name__ == "__main__":
    main()
