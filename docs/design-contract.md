# Lead's design contract

Status: lead-prepared implementation specification and cumulative phase-2 behavior.
Assigned architecture explanations remain separate documentation work.

## Implemented in phase-1

`pc` has a 32-bit current_pc output. On a rising edge, reset selects RESET_PC;
otherwise enable loads next_pc; otherwise the PC holds. Reset is synchronous.
The future CPU chooses next_pc and gates enable during a fault.

`instruction_memory` contains 256 words. A byte address is valid only when upper
bits [31:10] are zero and bits [1:0] are zero. Words are selected by [9:2].
Valid unused locations contain ADDI x0,x0,0, hexadecimal 00000013.
Invalid reads return zero with address_valid low; zero is not advertised as RV32I NOP.
The future CPU must reject invalid fetches rather than retire that returned word.

INIT_FILE selects a readmemh image. An empty INIT_FILE provides a NOP-only ROM.
The default checked-in image contains all 256 words, avoiding short-file warnings.
A missing nonempty image prints ERROR and stops simulation; the runner rejects
any ERROR or missing PASS summary even if that simulator stop has exit status zero.

The fetch bench wires PC+4 to the PC input. Its boundary test reaches 0x400;
it exposes an invalid fetch. Sticky fault handling belongs to later CPU integration.

## Added in phase-2

The register file has two asynchronous reads, one synchronous enabled write and
active-high synchronous reset. Reset clears every register, x0 reads zero and
writes to x0 are ignored. Other registers need reset before their values are defined.

The immediate generator selects I (00), S (01) or B (10), sign-extends the result,
and returns immediate=0/format_valid=0 for selector 11. format_valid is not an
instruction legality signal. B output already includes its implicit low zero.

Data RAM uses the same byte-address checks as ROM: valid aligned words range
from 0 through 0x3fc. Reads are asynchronous and enabled by mem_read; stores are
clocked and require mem_write, a valid address and reset low. Reset preserves
all RAM contents. Unwritten words are unspecified. Invalid reads return zero,
invalid stores are ignored, and address_valid remains available for later CPU gating.

These are standalone module implementations. See [interfaces](phase-2-interfaces.md).
No instruction execution, hardware fault controller or processor top exists yet.

## Planned full processor

- Single-cycle, non-pipelined, separate 1 KiB instruction and data memories.
- ADD, SUB, AND, OR, XOR, ADDI, LW, SW, BEQ and BNE only.
- 32 registers, two asynchronous reads, one synchronous write, x0 protected.
- rd=instruction[11:7], rs1=instruction[19:15], rs2=instruction[24:20].
- I/S/B sign-extended immediates; normal next PC=PC+4.
- Taken branch target=current PC+B-immediate, with the encoded low zero already included.
- Asynchronous RAM read and rising-edge store; reset preserves initialized RAM data.
- Reset clears processor/register/fault state and suppresses writes.
- Diagnostic sticky fault holds the PC and suppresses writes after invalid instructions,
  invalid memory addresses or a taken misaligned branch. No privileged trap claim.
- Ideal no-stall CPI=1; clock-frequency claims require actual timing evidence.

Later phases integrate instruction execution and fault handling. Current tests
establish component behavior and encoding fields, not complete RV32I compliance.
