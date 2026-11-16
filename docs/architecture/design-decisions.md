# Architecture design decisions

Assigned owner: Viraj. Prepared with assistant support by tracing the current RTL
and benches. Decisions below distinguish existing behavior from later design work.

## 1. Synchronous reset with highest priority

`pc.v` updates only inside `always @(posedge clk)`. Reset therefore takes effect
on a rising edge, even if it is asserted earlier. Its first conditional branch
selects RESET_PC before checking enable. This allows reset to restart a held PC.

This simple priority is explicit and testable. It does not imply external board
reset buttons can be connected without considering synchronization/debouncing.
Board-specific reset circuitry is outside the present milestone.

Evidence: `tb_pc` checks reset priority, reset with enable low and no immediate
change between edges. `tb_fetch` checks restart after a hold.

## 2. Separate PC storage from next-address selection

The PC accepts next_pc rather than calculating its own increment. Phase-1's
composition bench supplies PC+4; later CPU integration can select a branch
target without changing the register module.

The enable input supports a hold. It is verified now, but no diagnostic fault
controller drives it yet. Exposing address_valid does not itself stop the PC.

## 3. Byte addresses with checked word indexing

The external address counts bytes. A 32-bit instruction uses four bytes, so
aligned starting addresses differ by four. Selecting bits [9:2] converts the
address into an index from 0 to 255 for the 1 KiB ROM.

Both checks are necessary:

| Check | Reason |
|---|---|
| `address[1:0] == 0` | Rejects unaligned instruction addresses |
| `address[31:10] == 0` | Rejects addresses beyond ROM instead of aliasing them |

For example, using [9:2] alone would map address 0x400 to word zero. The actual
ROM rejects it. Address 0x3fc is the last valid word; 0x3fd is unaligned and
0x400 is outside the memory. The tests exercise both failures and subsequent
recovery to a valid read.

## 4. Distinguish NOP padding from invalid fetches

Unprogrammed valid locations contain `00000013`, ADDI x0,x0,0. That will be
harmless when the later CPU implements ADDI and x0 protection.

Invalid addresses instead expose address_valid=0 and return zero. The future
CPU must suppress execution/writes on the invalid flag. Returning a valid NOP
for every bad fetch would hide a faulty PC or memory boundary condition.
The current fetch bench observes the flag but does not implement that CPU policy.

## 5. Asynchronous instruction read

The ROM output is a continuous combinational assignment. This lets fetching
participate in the completed processor's single clock period. Only the PC is
clocked in the implemented fetch path.

This interface choice constrains later synthesis: mapping depends on the chosen
device and memory resources. No block-RAM utilization, maximum clock frequency
or FPGA fit is claimed before a real synthesis/timing run.

## 6. Predictable program initialization

The initial block fills all words with NOP and optionally loads INIT_FILE.
An empty filename intentionally creates a NOP-only ROM. The default fixture has
exactly 256 words, so it is a complete memory image rather than a short file.

Simulation checks that a nonempty file can be opened. Its ERROR message or a
missing PASS summary causes the runner to fail, even if the simulator's early
stop exits successfully. This guard is excluded under SYNTHESIS; a future
synthesis flow still has to supply the correct image path.

## 7. Separate instruction and future data storage

The final Harvard design gives fetch and load/store operations separate memories.
Instruction ROM is present; data RAM is planned for phase-2. The planned RAM
preserves data across processor reset, avoiding a requirement to clear every RAM
word simultaneously. Its actual implementation and tests remain future work.

## 8. Use evidence appropriate to the milestone

The 41 passing HDL checks cover PC, ROM and their testbench composition. They
do not prove register writes, branches, LW/SW, a complete CPU or instruction CPI.
The 10 ns simulation clock stimulates behavior; it is not measured hardware
timing. The waveform contains fetched machine words, not execution results.

The [verification record](../../reports/verification/phase-1.md) and
[design contract](../design-contract.md) provide the reproducible evidence and
the boundaries for later integration.
