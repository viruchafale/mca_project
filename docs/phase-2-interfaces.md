# Phase-2 module interfaces

Lead implementation documentation. These modules were added on top of the
published phase-1 tip 28f4abb. They are standalone units, not an executing CPU.

## Register file

Source: rtl/register_file.v. Storage: 32 registers of 32 bits.

| Port | Width | Meaning |
|---|---:|---|
| clk | 1 | Rising-edge state updates |
| reset | 1 | Synchronously clears all registers; highest priority |
| reg_write | 1 | Enables a write when reset is low |
| read_reg1, read_reg2 | 5 each | Independent read addresses |
| write_reg | 5 | Write address |
| write_data | 32 | Value stored at the next enabled rising edge |
| read_data1, read_data2 | 32 each | Asynchronous read values |

x0 reads as zero even before reset and ignores writes. Other register contents
are unspecified before reset. Reset clears all 32 storage entries; no testbench
hierarchical writes are used to make it appear correct. When reading and writing
the same register, the old value is read before the edge and the new value after
the nonblocking write settles. This is not a pipeline forwarding network.

## Immediate generator

Source: rtl/immediate_generator.v. Input instruction is 32 bits; imm_select is
2 bits. Outputs are a 32-bit immediate and one-bit format_valid.

| imm_select | Format | Fields used | Signed output range |
|---|---|---|---|
| 00 | I | instruction[31:20] | -2048 to 2047 |
| 01 | S | instruction[31:25], instruction[11:7] | -2048 to 2047 |
| 10 | B | instruction[31], [7], [30:25], [11:8], low zero | -4096 to 4094, steps of two |
| 11 | Invalid selector | none | immediate=0, format_valid=0 |

The sign bit is instruction[31]. B output is already a byte displacement with
bit zero appended. Later branch logic must add it to the current PC without
shifting it again.

format_valid reports whether the selector is supported. It does not mean that
the instruction opcode, funct3 or funct7 is legal. Exact instruction decoding
belongs to phase-3. Phase-4 must reject a taken branch target that is not
four-byte aligned; the immediate generator correctly represents offsets such
as +2 even though that target would need an alignment fault without compressed
instructions. Its entire encoding range is tested independently of the 1 KiB ROM.

## Data memory

Source: rtl/data_memory.v. Storage: 256 words of 32 bits, separate from ROM.

| Port | Width | Meaning |
|---|---:|---|
| clk | 1 | Rising-edge store |
| reset | 1 | Suppresses stores; preserves RAM contents |
| mem_read | 1 | Enables asynchronous read |
| mem_write | 1 | Enables store when address is valid and reset is low |
| address | 32 | Byte address |
| write_data | 32 | Store value |
| read_data | 32 | Word value, or zero for disabled/invalid read |
| address_valid | 1 | Range/alignment result independent of enables |

Valid word addresses are 0,4,...,0x3fc. Low bits [1:0] must be zero and upper
bits [31:10] must be zero. Invalid stores are ignored, so 0x400 cannot alias
word zero. A future CPU must observe address_valid and implement its diagnostic
fault policy; this standalone memory does not halt a processor.

There is no power-up or reset clear of RAM. Unwritten contents are unspecified.
The testbench initializes every word through the public write port. Reset can
leave mem_read enabled: existing data remains visible. Reset blocks a simultaneous
store and preserves all initialized words.

If mem_read and mem_write are both high, the old value is visible before the
rising edge; the new value appears after the write settles. Only aligned word
operations are implemented; no byte-enable interface is advertised.

## Verification and limits

The three new suites check 103 register-file cases, 12,294 immediate cases and
785 RAM cases. The immediate count includes every I and S value (4096 each),
every even B displacement (4096), five literal instruction examples and one
invalid selector. These are component checks, not executed CPU instructions.

The independent Python field extractor checks ten hand-calculated instruction
words against literal register/immediate expectations. It is not a hardware
decoder, assembler or instruction-set simulator.

See [phase-2 evidence](../reports/verification/phase-2.md). CPU arithmetic,
branch decisions, LW/SW integration, synthesis and hardware timing remain future work.
