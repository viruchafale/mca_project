#!/usr/bin/env python3
"""Check hand-calculated RV32I words by independent field extraction.
This validates encodings, not processor execution. No external Python packages.
"""
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {"ADD", "SUB", "AND", "OR", "XOR", "ADDI", "LW", "SW", "BEQ", "BNE"}


def signed(value, width):
    return value - (1 << width) if value & (1 << (width - 1)) else value


def decode(word):
    opcode, funct3, funct7 = word & 127, (word >> 12) & 7, word >> 25
    rd, rs1, rs2 = (word >> 7) & 31, (word >> 15) & 31, (word >> 20) & 31
    if opcode == 0x33:
        name = {(0, 0): "ADD", (0, 32): "SUB", (7, 0): "AND",
                (6, 0): "OR", (4, 0): "XOR"}.get((funct3, funct7))
        if name:
            return dict(name=name, rd=rd, rs1=rs1, rs2=rs2)
    if (opcode, funct3) in [(0x13, 0), (0x03, 2)]:
        return dict(name="ADDI" if opcode == 0x13 else "LW",
                    rd=rd, rs1=rs1, imm=signed(word >> 20, 12))
    if (opcode, funct3) == (0x23, 2):
        immediate = ((word >> 25) << 5) | ((word >> 7) & 31)
        return dict(name="SW", rs1=rs1, rs2=rs2, imm=signed(immediate, 12))
    if opcode == 0x63 and funct3 in [0, 1]:
        immediate = (((word >> 31) & 1) << 12) | (((word >> 7) & 1) << 11)
        immediate |= ((word >> 25) & 63) << 5
        immediate |= ((word >> 8) & 15) << 1
        return dict(name="BEQ" if funct3 == 0 else "BNE",
                    rs1=rs1, rs2=rs2, imm=signed(immediate, 13))
    raise ValueError("unsupported encoding: " + format(word, "08x"))


def main():
    try:
        vectors = json.loads((ROOT / "programs/encoding-vectors.json").read_text())
        if len(vectors) != len(REQUIRED) or {v["expected"]["name"] for v in vectors} != REQUIRED:
            raise ValueError("need exactly one vector for each target instruction")
        for vector in vectors:
            if not re.fullmatch(r"[0-9a-fA-F]{8}", vector["hex"]):
                raise ValueError("malformed 32-bit word")
            actual = decode(int(vector["hex"], 16))
            if actual != vector["expected"]:
                raise ValueError(str(vector) + " decoded as " + str(actual))
        print("PASS: instruction encodings checks=" + str(len(vectors)))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print("FAIL: instruction encoding check: " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
