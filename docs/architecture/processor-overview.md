# Processor overview

Phase-1 architecture documentation, assigned to Viraj. Prepared with assistant
support at Viraj's request from the checked-in RTL and actual simulation results.
This records the implementation; it does not claim a personal interview rehearsal
or independent human review has already happened.

## Objective and present scope

The final objective is a compact single-cycle processor implementing ADD, SUB,
AND, OR, XOR, ADDI, LW, SW, BEQ and BNE from RV32I. Phase-1 establishes the fetch
foundation: a program counter and a separate instruction ROM. The current branch
does not execute any instruction, including those in its sample ROM.

| Component | Present behavior | Status |
|---|---|---|
| `rtl/pc.v` | Stores a 32-bit address with synchronous reset and enable | Implemented and tested |
| `rtl/instruction_memory.v` | Fetches a 32-bit word from a 256-word asynchronous ROM | Implemented and tested |
| `tb/tb_fetch.sv` | Connects the modules and supplies PC+4 | Simulation-only integration harness |
| Register file, decoder, immediates, ALU, data RAM, branches, writeback, CPU top | Complete instruction execution | Planned for phases 2-4 |
| Synthesis, measured hardware timing and FPGA deployment | Hardware implementation evidence | Not performed in phase-1 |

## Fetch operation

The PC presents a byte address to instruction memory. Every instruction occupies
four bytes, so word-aligned sequential addresses are 0, 4, 8 and so on. ROM index
`address[9:2]` selects the corresponding word, after range and alignment checks.
The fetched word appears combinationally; the ROM has no clock input.

On a rising edge, the PC applies the following priority:

1. If `reset=1`, load `RESET_PC`, normally zero.
2. Otherwise, if `enable=1`, load the supplied `next_pc`.
3. Otherwise retain the current address.

The PC module does not calculate PC+4. The composition testbench supplies
`address + 32'd4` as `next_pc`. Later integration will supply either PC+4 or a
branch target and will hold the PC when a diagnostic fault occurs.

Reset is synchronous: asserting it between edges does not immediately alter the
PC. At the next rising edge it overrides enable and the next-address input.

## Instruction ROM

The ROM holds 256 x 32 bits, or 1 KiB. Its address space is 0x000-0x3ff; valid
word starting addresses are 0x000, 0x004, ..., 0x3fc. Nonzero address bits [31:10]
or low address bits [1:0] make a fetch invalid.

An invalid fetch returns `instruction=0` and `address_valid=0`. Zero is an invalid
word for this project's intended subset, not a RISC-V NOP. A future CPU must
use the validity signal to prevent retirement or writes on that fetch.

Valid unused words are padded with `00000013`, the encoding of ADDI x0,x0,0.
`INIT_FILE` selects a hexadecimal image; an empty parameter selects a NOP-only
ROM. The normal image supplies all 256 words, with eight fixture instructions
and 248 NOPs. No register or memory result is produced by fetching that image.

## Single-cycle execution planned for later phases

In the completed design, fetch, decode, operand reads, ALU operation, optional
data-memory read and writeback selection will settle within one clock period.
Architectural state changes on the rising edge. These are functional steps of
one instruction, not five pipeline stages or five clock cycles.

The planned Harvard organization gives instructions and data separate memories,
so an instruction fetch and an LW/SW access do not compete for one memory port.
Only the instruction side exists now. The planned register file protects x0;
the planned decoder accepts exact supported encodings; the planned branch path
uses current PC plus the sign-extended B immediate.

## Evidence and explanation checklist

The phase-1 regression passes 10 PC checks, 20 ROM checks and 11 composition checks.
Those 41 checks establish fetch-state behavior, not ISA execution or FPGA speed.
See the [block diagram](block-diagram.md), [design decisions](design-decisions.md),
[original verification evidence](../../reports/verification/phase-1.md) and
[design contract](../design-contract.md).

For the interview, explain why PC+4 is external to the PC register, why reset
has priority over enable, how byte addresses become word indices, and why a
fetched BEQ does not branch in this phase.
