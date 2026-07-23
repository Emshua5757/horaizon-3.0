"""
parser.py — HBP v2 schema loader

Reads hbp_operations.toml and produces typed dataclass objects that
the language generators consume. No generator code lives here.
"""

from __future__ import annotations

import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

SCHEMA_PATH = Path(__file__).parent / "schema" / "hbp_operations.toml"


# ---------------------------------------------------------------------------
# Typed schema dataclasses
# ---------------------------------------------------------------------------

@dataclass
class EnumVariant:
    name:  str
    value: Optional[int] = None   # present for integer-coded enums


@dataclass
class HbpEnum:
    name:        str
    description: str
    variants:    list[EnumVariant]


@dataclass
class StructField:
    name:        str
    type:        str   # HBP canonical type string (e.g. "u8", "str?", "ModuleEntry[]")
    description: str


@dataclass
class HbpStruct:
    name:        str
    description: str
    fields:      list[StructField]


@dataclass
class HbpOperation:
    module:          str
    name:            str           # e.g. "compile" or "module.wake"
    direction:       str           # "request_response" | "event_only"
    description:     str
    request_struct:  str           # "" = empty payload
    response_struct: str           # "" = empty payload
    event_struct:    str           # "" unless direction == "event_only"

    @property
    def op_key(self) -> str:
        """Full dotted operation key e.g. shua.resume.compile"""
        return f"{self.module}.{self.name}"

    @property
    def const_name(self) -> str:
        """SCREAMING_SNAKE constant name e.g. SHUA_RESUME_COMPILE"""
        return self.op_key.replace('.', '_').upper()


@dataclass
class HbpProtocol:
    version:     int
    port:        int
    description: str
    output:      dict[str, str]
    enums:       list[HbpEnum]
    structs:     list[HbpStruct]
    operations:  list[HbpOperation]

    # ---- helpers ----

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
# Parser
# ---------------------------------------------------------------------------

def load(path: Path = SCHEMA_PATH) -> HbpProtocol:
    """Parse hbp_operations.toml into a typed HbpProtocol object."""
    with open(path, "rb") as f:
        raw = tomllib.load(f)

    proto = raw["protocol"]
    output_cfg = raw.get("output", {})

    enums = [
        HbpEnum(
            name=e["name"],
            description=e.get("description", ""),
            variants=[
                EnumVariant(name=v["name"], value=v.get("value"))
                for v in e.get("variants", [])
            ],
        )
        for e in raw.get("enums", [])
    ]

    structs = [
        HbpStruct(
            name=s["name"],
            description=s.get("description", ""),
            fields=[
                StructField(
                    name=f["name"],
                    type=f["type"],
                    description=f.get("description", ""),
                )
                for f in s.get("fields", [])
            ],
        )
        for s in raw.get("structs", [])
    ]

    operations = [
        HbpOperation(
            module=op["module"],
            name=op["name"],
            direction=op["direction"],
            description=op.get("description", ""),
            request_struct=op.get("request_struct", ""),
            response_struct=op.get("response_struct", ""),
            event_struct=op.get("event_struct", ""),
        )
        for op in raw.get("operations", [])
    ]

    return HbpProtocol(
        version=proto["version"],
        port=proto["port"],
        description=proto.get("description", ""),
        output=dict(output_cfg),
        enums=enums,
        structs=structs,
        operations=operations,
    )
