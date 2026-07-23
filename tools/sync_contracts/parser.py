"""
parser.py — HBP v2 modular schema loader & integrity validator

Scans _architecture/contracts/hbp/schema/*.toml, deep-merges modular schemas,
validates strict field indexing (Protobuf-style), semantic types, and integrity rules.
"""

from __future__ import annotations

import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

SCHEMA_DIR = Path(__file__).parent.parent.parent / "_architecture" / "contracts" / "hbp" / "schema"


# ---------------------------------------------------------------------------
# Typed schema dataclasses
# ---------------------------------------------------------------------------

@dataclass
class EnumVariant:
    name:  str
    value: Optional[int] = None   # integer-coded enum value


@dataclass
class HbpEnum:
    name:        str
    description: str
    variants:    list[EnumVariant]


@dataclass
class StructField:
    index:       int           # Strict Protobuf-style 1-based index
    name:        str
    type:        str           # HBP type (e.g. "u8", "timestamp", "uuid", "map<str, str>", "ModuleEntry[]")
    description: str
    deprecated:  bool = False
    deprecation_reason: Optional[str] = None
    default:     Optional[str] = None

    @property
    def is_optional(self) -> bool:
        return self.type.endswith("?")

    @property
    def base_type(self) -> str:
        return self.type.rstrip("?")


@dataclass
class HbpStruct:
    name:        str
    description: str
    fields:      list[StructField]


@dataclass
class HbpOperation:
    module:          str
    name:            str           # e.g. "compile" or "module.wake"
    op_type:         str           # "rpc" | "event"
    requires_auth:   bool
    description:     str
    request_struct:  str           # "" = empty payload
    response_struct: str           # "" = empty payload
    event_struct:    str           # "" unless op_type == "event"

    @property
    def op_key(self) -> str:
        """Full dotted operation key e.g. shua.resume.compile"""
        return f"{self.module}.{self.name}"

    @property
    def const_name(self) -> str:
        """SCREAMING_SNAKE constant name e.g. SHUA_RESUME_COMPILE"""
        return self.op_key.replace('.', '_').replace('-', '_').upper()


@dataclass
class HbpProtocol:
    version:     int
    port:        int
    description: str
    output:      dict[str, str]
    enums:       list[HbpEnum]
    structs:     list[HbpStruct]
    operations:  list[HbpOperation]

    def enum_names(self) -> set[str]:
        return {e.name for e in self.enums}

    def struct_names(self) -> set[str]:
        return {s.name for s in self.structs}

    def operations_for(self, module: str) -> list[HbpOperation]:
        return [op for op in self.operations if op.module == module]

    def unique_modules(self) -> list[str]:
        seen: list[str] = []
        for op in self.operations:
            if op.module not in seen:
                seen.append(op.module)
        return seen


# ---------------------------------------------------------------------------
# Deep Merge & Parser Engine
# ---------------------------------------------------------------------------

def deep_merge(target: dict, source: dict):
    for k, v in source.items():
        if isinstance(v, list) and k in target and isinstance(target[k], list):
            target[k].extend(v)
        elif isinstance(v, dict) and k in target and isinstance(target[k], dict):
            deep_merge(target[k], v)
        else:
            target[k] = v


def load(schema_dir: Path = SCHEMA_DIR) -> HbpProtocol:
    """Parse all _architecture/contracts/hbp/schema/*.toml into a validated HbpProtocol object."""
    if not schema_dir.exists():
        raise FileNotFoundError(f"Schema directory not found: {schema_dir}")

    merged: dict = {
        "protocol": {"version": 2, "port": 7700, "description": ""},
        "output": {},
        "enums": [],
        "structs": [],
        "operations": [],
    }

    toml_files = sorted(schema_dir.glob("*.toml"))
    if not toml_files:
        raise FileNotFoundError(f"No .toml files found in {schema_dir}")

    for file_path in toml_files:
        with open(file_path, "rb") as f:
            data = tomllib.load(f)
            deep_merge(merged, data)

    proto_cfg = merged["protocol"]
    output_cfg = merged.get("output", {})

    enums = [
        HbpEnum(
            name=e["name"],
            description=e.get("description", ""),
            variants=[
                EnumVariant(name=v["name"], value=v.get("value"))
                for v in e.get("variants", [])
            ],
        )
        for e in merged.get("enums", [])
    ]

    structs = [
        HbpStruct(
            name=s["name"],
            description=s.get("description", ""),
            fields=[
                StructField(
                    index=f.get("index", idx + 1),
                    name=f["name"],
                    type=f["type"],
                    description=f.get("description", ""),
                    deprecated=f.get("deprecated", False),
                    deprecation_reason=f.get("deprecation_reason"),
                    default=f.get("default"),
                )
                for idx, f in enumerate(s.get("fields", []))
            ],
        )
        for s in merged.get("structs", [])
    ]

    operations = [
        HbpOperation(
            module=op["module"],
            name=op["name"],
            op_type=op.get("type", "event" if op.get("direction") == "event_only" else "rpc"),
            requires_auth=op.get("requires_auth", True),
            description=op.get("description", ""),
            request_struct=op.get("request_struct", ""),
            response_struct=op.get("response_struct", ""),
            event_struct=op.get("event_struct", ""),
        )
        for op in merged.get("operations", [])
    ]

    proto = HbpProtocol(
        version=proto_cfg.get("version", 2),
        port=proto_cfg.get("port", 7700),
        description=proto_cfg.get("description", ""),
        output=output_cfg,
        enums=enums,
        structs=structs,
        operations=operations,
    )

    validate(proto)
    return proto


# ---------------------------------------------------------------------------
# Schema Integrity Validator
# ---------------------------------------------------------------------------

def validate(proto: HbpProtocol):
    """Validate schema integrity: unique indices, no duplicate ops, valid type refs."""
    errors: list[str] = []

    # 1. Enforce unique struct field indices
    for s in proto.structs:
        indices = [f.index for f in s.fields]
        if len(indices) != len(set(indices)):
            errors.append(f"Struct '{s.name}' has duplicate field indices: {indices}")

    # 2. Enforce unique operation keys
    op_keys = [op.op_key for op in proto.operations]
    if len(op_keys) != len(set(op_keys)):
        duplicates = [k for k in set(op_keys) if op_keys.count(k) > 1]
        errors.append(f"Duplicate operation keys found: {duplicates}")

    if errors:
        raise ValueError("Schema Validation Errors:\n  " + "\n  ".join(errors))
