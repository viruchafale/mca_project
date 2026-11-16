# Phase-1 verification evidence

Run date: 16 November 2026. Verified source commit:
`50ef08030dbde3ed9210f4514b8b715f19fac360` (clean working tree at run).
Tool: Icarus Verilog 13.0 stable. RTL compiled as Verilog-2001;
verification benches use SystemVerilog-2012.

## Observed results

| Suite | Passing checks | What was verified |
|---|---:|---|
| tb_pc | 10 | Synchronous reset/priority, configurable reset address, edge-only updates, enable/hold, 32-bit wraparound |
| tb_instruction_memory | 20 | Eight explicit program words, NOP padding, last word, invalid/unaligned addresses, no aliasing, recovery, empty-image initialization |
| tb_fetch | 11 | Real PC/ROM composition, sequential fetch, hold, reset restart and out-of-range indication |
| Total | 41 | Fetch-path milestone only |

Both RTL tops also compiled independently with `-g2001 -Wall`.
No compilation warnings were observed in this run.

The runner's three actual subprocess probes confirmed rejection of an intentional
fatal simulation, exit without a PASS summary, and a simulation timeout.
Two additional isolated entry-point checks confirmed exit status 1 and a failed
manifest for missing input and invalid RTL. These five runner checks are separate
from the 41 HDL checks and do not inflate the HDL count.

## Reproduce and inspect

From the project root, with Python 3 and Icarus Verilog on PATH:

```bash
python3 tools/run_tests.py --wave --self-check
```

For a relocated Icarus package, use the documented IVERILOG, VVP and IVL_BASE
environment variables. The verification tool was prepared outside the repository;
no downloaded compiler binaries or machine-specific paths are committed.

The run creates `build/verification.json`, per-bench logs and three actual VCDs:
`build/tb_pc.vcd`, `build/tb_instruction_memory.vcd`, `build/tb_fetch.vcd`.
Raw traces/executables are ignored. The portable
[manifest](phase-1-manifest.json) records source/input hashes, tool version,
results and generated trace hashes. Simulator date/time metadata can change VCD
bytes on rerun; architectural checks, not byte-identical VCDs, define correctness.

Committed simulator logs:

- [PC](phase-1-tb_pc.log)
- [ROM](phase-1-tb_instruction_memory.log)
- [Composed fetch](phase-1-tb_fetch.log)

In the fetch VCD, inspect reset, enable, address, instruction and address_valid.
Reset exposes PC 0; enabled edges advance by four; disabling enable holds PC 0x1c;
reset restarts at zero; after the ROM boundary address_valid becomes zero.
The sequence is testbench-driven PC+4: it does not execute the fixture's branch.

## Limits and handoff

No instruction execution, complete RV32I CPU, synthesis, hardware maximum clock
frequency or FPGA result is claimed. Raw simulator waveforms exist; screenshots
and captions for the team's verification documentation remain real member work.

The original phase-1 implementation/evidence was published at 2fe6adb. Under the
corrected member order, Viraj owns the three architecture documents, which remain
assigned outlines. His lead implementation commits are genuine existing work;
the architecture handoff still precedes phase-2. This mapping correction awaits publication.
