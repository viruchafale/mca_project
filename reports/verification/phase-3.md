# Phase-3 verification evidence

The cumulative Icarus Verilog 13.0 run passed 145,292 HDL checks and ten software
encoding checks. The [manifest](phase-3-manifest.json) records the exact input
hashes and source working-tree state. Phase-3 source files were new/uncommitted
at that run; its base commit is 24082cc. The committed input hashes identify the
tested source without pretending that the new RTL existed in the base commit.

| Testbench | Checks | Scope |
|---|---:|---|
| Original six phase-2 suites | 13,223 | PC, ROM, fetch, registers, immediates, RAM |
| tb_alu | 503 | Five operations over 100 operand pairs each; three invalid selectors |
| tb_control_unit | 131,072 | Every opcode/funct3/funct7 combination with fixed nonzero register fields |
| tb_writeback_mux | 20 | Both inputs over ten data patterns |
| tb_rv32i_cpu | 104 | Seventeen executed arithmetic instructions, traces, final state, fault and reset |
| tb_cpu_faults | 370 | Ten unsupported-instruction/fetch scenarios and state preservation |
| Total | 145,292 | No claim of 145,292 executed instructions |

The decoder coverage count is exhaustive for those field combinations, not
exhaustive over all 32-bit words or all processor states. The ALU operand pairs
include zero, all ones, signed boundaries, alternating bits and other patterns.
The arithmetic program covers dependencies, rd=rs1, rd=x0, negative immediates,
32-bit wraparound and all six supported instructions.

The ten fault scenarios cover LW, SW, BEQ, BNE, unsupported R funct7, unsupported
immediate funct3, an unknown word, out-of-range fetch, unaligned fetch and fetch
after the last legal ROM word. No unsupported operation may write a register or
advance past the faulting instruction. Reset clears registers and sticky faults.

All nine RTL entry points compile with Verilog-2001 and their needed dependencies.
The three runner probes reject a fatal simulation, missing PASS summary and timeout.

## Reproduce

Run from the root with Python 3 and Icarus on PATH:

```bash
python3 tools/run_tests.py --wave --self-check
```

README documents custom IVERILOG/VVP/IVL_BASE paths. Output stays in ignored build/.
ALU, integrated CPU and fault benches generate new VCDs in wave mode. Decoder and
writeback unit benches use assertions/logs; they intentionally do not dump a VCD.
The original six suites also retain their waveforms.

An initial ALU bench run exposed a time-zero stimulus issue: already initialized
zero inputs did not produce an event for the first combinational check. The bench
now drives its first known inputs from uninitialized stimulus variables. The
subsequent complete regression passed; no artificial initial ALU state was added.

## What is and is not established

This milestone executes ADD/SUB/AND/OR/XOR/ADDI through the integrated core and
checks their register effects. It does not yet execute LW/SW/BEQ/BNE. An illegal
zero-word sentinel ends the arithmetic test; no HALT, ECALL or EBREAK was added.
Memory writeback selection is unit tested, but the CPU still selects ALU only.

Raw simulation time is not measured hardware frequency. Synthesis, timing and
FPGA utilization remain unmeasured. Pratyush's datapath/control documents are
task outlines pending his actual contribution. Phase-4 must inherit that accepted
contribution from phase-3 before adding memory/branch execution.
