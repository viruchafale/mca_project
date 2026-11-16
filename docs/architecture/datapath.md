# Datapath — Pratyush's Phase-3 assignment

Status: awaiting Pratyush's substantive contribution and own-account commit.
This outline was prepared by the lead.

Draw the implemented rv32i_cpu connections using actual port/signal names.
Trace ADD x3,x1,x2 and ADDI with a negative immediate from ROM to the register
write port. Identify combinational paths and rising-edge state updates.

Explain operand selection, fixed rd position, writeback, x0 suppression and
dependencies between consecutive instructions. Distinguish the connected ALU
writeback path from the mux's currently unused memory input.

Use docs/phase-3-interfaces.md and the actual RTL. Do not draw connected branch
or data-memory execution paths as implemented before phase-4.
