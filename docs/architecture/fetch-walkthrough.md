# Fetch simulation walkthrough

Assigned owner: Viraj. This assistant-assisted walkthrough was prepared from a
fresh Icarus simulation and direct reading of its VCD at Viraj's request.
It is not a claim that Viraj has independently rehearsed or reviewed the design.

## Reproduction and source identity

The command was `python3 tools/run_tests.py --wave --self-check`, using Icarus
Verilog 13.0 stable. The clean source checkout at the run was
`d9c183d`, before these architecture documentation commits. RTL, testbench,
program and runner hashes are unchanged by the documentation work.

The portable [review record](../../reports/verification/phase-1-architecture-review.json)
contains the full source commit, run time, input hashes, simulator logs, generated
waveform hashes and samples below. Use the README's IVERILOG/VVP/IVL_BASE options
when the simulator is outside PATH. Generated raw traces remain in ignored build/.

## Observed checks

| Testbench | Passing HDL checks |
|---|---:|
| tb_pc | 10 |
| tb_instruction_memory | 20 |
| tb_fetch | 11 |
| Total | 41 |

The three runner self-checks separately rejected a fatal simulation, a clean exit
without a PASS summary, and a nonterminating simulation. They do not add to the
41 HDL checks. Both RTL modules also compiled under Verilog-2001.

## Read the actual fetch trace

The VCD declares a 1 ps timescale. The table converts timestamps to nanoseconds
and samples each timestamp after all recorded updates at that timestamp.
Open build/tb_fetch.vcd and select tb_fetch's address, instruction,
address_valid, reset, enable and clk signals.

| Time (ns) | Reset | Enable | PC/address | Instruction | Valid | Observation |
|---:|---:|---:|---|---|---:|---|
| 5 | 1 | 1 | 00000000 | 00500093 | 1 | First reset edge selects ROM word zero |
| 15 | 0 | 1 | 00000004 | 00a00113 | 1 | First enabled sequential update |
| 55 | 0 | 1 | 00000014 | 00418463 | 1 | Fetches a BEQ machine word |
| 65 | 0 | 1 | 00000018 | 002082b3 | 1 | Advances by four; does not execute BEQ |
| 75 | 0 | 1 | 0000001c | 00000063 | 1 | Fetches the final fixture word |
| 85 | 0 | 0 | 0000001c | 00000063 | 1 | Enable low holds the fetch address |
| 105 | 1 | 0 | 00000000 | 00500093 | 1 | Reset overrides hold and restarts fetching |
| 2665 | 0 | 1 | 00000400 | 00000000 | 0 | Out-of-range address is flagged, without aliasing |

The initial PC is unknown before the first synchronous reset edge. That is
expected here; the tests do not pretend the unreset register has a defined value.
The testbench checks results at falling edges, after rising-edge updates settle.

## What the trace establishes

The register updates at clock edges, the ROM responds to its address, hold and
reset interact as specified, and an invalid fetch is visible. The BEQ example
shows why fetched instruction bits must not be mistaken for executed behavior:
PC still moves from 0x14 to 0x18 because the bench supplies PC+4.

The trace does not establish branch decisions, arithmetic results, register-file
writes, load/store behavior, synthesized frequency or FPGA operation. A future
CPU must consume address_valid to gate writes and hold on faults; the phase-1
composition harness does not yet add that policy.

For interview preparation, first explain the table without reading the prose,
then locate the PC/ROM signals in the diagram and point to the corresponding RTL.
Human understanding and team sign-off remain separate from preparing this record.
