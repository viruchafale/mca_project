# Exact Arithmetic Instruction Decoding and Control Logic

This document details the exact instruction decoding logic implemented in `rtl/control_unit.v` for Phase 3 of the single-cycle RV32I processor. It covers the six supported arithmetic instructions (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `ADDI`), exact bitfield matching, rejection of unsupported instructions, prevention of unintended register writes and latch inference, and the relationship between decoder validity and datapath execution.

---

## 1. Supported Instruction Subset and RTL Decoding Tables

The Phase-3 control unit implements exact, non-speculative decoding for six integer arithmetic instructions:

| Instruction | Format | Opcode `[6:0]` | Funct3 `[14:12]` | Funct7 `[31:25]` | `instruction_valid` | `reg_write` | `alu_src_immediate` | `alu_operation [2:0]` | ALU Operation |
|---|---|---|---|---|---|---|---|---|---|
| `ADD` | R-type | `7'b0110011` (`7'h33`) | `3'b000` | `7'b0000000` (`7'h00`) | `1'b1` | `1'b1` | `1'b0` | `3'd0` | Addition (`a + b`) |
| `SUB` | R-type | `7'b0110011` (`7'h33`) | `3'b000` | `7'b0100000` (`7'h20`) | `1'b1` | `1'b1` | `1'b0` | `3'd1` | Subtraction (`a - b`) |
| `AND` | R-type | `7'b0110011` (`7'h33`) | `3'b111` | `7'b0000000` (`7'h00`) | `1'b1` | `1'b1` | `1'b0` | `3'd2` | Bitwise AND (`a & b`) |
| `OR` | R-type | `7'b0110011` (`7'h33`) | `3'b110` | `7'b0000000` (`7'h00`) | `1'b1` | `1'b1` | `1'b0` | `3'd3` | Bitwise OR (`a \| b`) |
| `XOR` | R-type | `7'b0110011` (`7'h33`) | `3'b100` | `7'b0000000` (`7'h00`) | `1'b1` | `1'b1` | `1'b0` | `3'd4` | Bitwise XOR (`a ^ b`) |
| `ADDI` | I-type | `7'b0010011` (`7'h13`) | `3'b000` | *None* (`imm[11:0]`) | `1'b1` | `1'b1` | `1'b1` | `3'd0` | Addition (`a + imm`) |

Every other combination of opcode, funct3, and funct7 drives `instruction_valid = 1'b0` and `reg_write = 1'b0`.

---

## 2. RTL Implementation Structure

The complete decoder logic in `rtl/control_unit.v` is implemented as a single combinational block:

```verilog
module control_unit (
    input wire [31:0] instruction,
    output reg instruction_valid,
    output reg reg_write,
    output reg alu_src_immediate,
    output reg [2:0] alu_operation
);
    always @(*) begin
        instruction_valid = 1'b0;
        reg_write = 1'b0;
        alu_src_immediate = 1'b0;
        alu_operation = 3'd0;
        case (instruction[6:0])
            7'h33: begin
                case ({instruction[31:25], instruction[14:12]})
                    10'b0000000_000: begin instruction_valid=1'b1; alu_operation=3'd0; end
                    10'b0100000_000: begin instruction_valid=1'b1; alu_operation=3'd1; end
                    10'b0000000_111: begin instruction_valid=1'b1; alu_operation=3'd2; end
                    10'b0000000_110: begin instruction_valid=1'b1; alu_operation=3'd3; end
                    10'b0000000_100: begin instruction_valid=1'b1; alu_operation=3'd4; end
                    default: begin end
                endcase
                reg_write = instruction_valid;
            end
            7'h13: begin
                if (instruction[14:12] == 3'b000) begin
                    instruction_valid = 1'b1;
                    reg_write = 1'b1;
                    alu_src_immediate = 1'b1;
                end
            end
            default: begin end
        endcase
    end
endmodule
```

---

## 3. Detailed Decoding Mechanics

### ADD vs. SUB Differentiation
`ADD` and `SUB` share identical major opcode (`7'h33`) and identical `funct3` (`3'b000`). They are distinguished solely by bit 30 of the instruction (`instruction[30]`), which forms part of the 7-bit `funct7` field:
- `ADD`: `funct7 = 7'b0000000` (`instruction[30] = 0`). The 10-bit concatenation `{funct7, funct3}` evaluates to `10'b0000000_000`, selecting `alu_operation = 3'd0`.
- `SUB`: `funct7 = 7'b0100000` (`instruction[30] = 1`). The 10-bit concatenation evaluates to `10'b0100000_000`, selecting `alu_operation = 3'd1`.

If an R-type instruction presents `funct3 = 3'b000` with any other `funct7` pattern (for example `7'b0000001`, which encodes `MUL` in the RV32M extension), it matches neither pattern and drops into `default: begin end`.

### ADDI Immediate Decoding vs. Funct7 Constraints
In I-type arithmetic instructions such as `ADDI`:
- Bits `[31:20]` constitute the 12-bit two's-complement immediate value, spanning $[-2048, +2047]$.
- There is **no funct7 field** in the standard I-format layout.
- If the control unit incorrectly required `instruction[31:25] == 7'b0000000` for `ADDI`, every negative immediate (where sign bit `instruction[31] = 1`) and every positive immediate $\ge 32$ (where bits `[31:25]` are non-zero) would be rejected as an illegal instruction.
- The RTL correctly inspects only `opcode == 7'h13` and `instruction[14:12] == 3'b000`. Bits `[31:20]` remain completely unconstrained at the decoder and pass directly to `u_immediate`, allowing the entire signed 12-bit immediate dynamic range.

---

## 4. Worked Instruction Bitfield Walkthroughs

### 1. Legal `ADD x3, x1, x2` (Hex: `0x002081b3`)
```text
Bit slice:
[31:25] funct7 = 7'b0000000
[24:20] rs2    = 5'b00010 (x2)
[19:15] rs1    = 5'b00001 (x1)
[14:12] funct3 = 3'b000
[11:7]  rd     = 5'b00011 (x3)
[6:0]   opcode = 7'b0110011 (7'h33)
```
- Opcode `7'h33` enters the R-type case.
- `{funct7, funct3} = 10'b0000000_000` matches the first case arm.
- Decoded controls: `instruction_valid = 1`, `reg_write = 1`, `alu_src_immediate = 0`, `alu_operation = 3'd0`.

### 2. Legal `SUB x4, x1, x2` (Hex: `0x40208233`)
```text
Bit slice:
[31:25] funct7 = 7'b0100000
[24:20] rs2    = 5'b00010 (x2)
[19:15] rs1    = 5'b00001 (x1)
[14:12] funct3 = 3'b000
[11:7]  rd     = 5'b00100 (x4)
[6:0]   opcode = 7'b0110011 (7'h33)
```
- Opcode `7'h33` enters the R-type case.
- `{funct7, funct3} = 10'b0100000_000` matches the second case arm.
- Decoded controls: `instruction_valid = 1`, `reg_write = 1`, `alu_src_immediate = 0`, `alu_operation = 3'd1`.

### 3. Legal Negative `ADDI x8, x4, -3` (Hex: `0xffd20413`)
```text
Bit slice:
[31:20] imm    = 12'b1111_1111_1101 (12'hffd = -3)
[19:15] rs1    = 5'b00100 (x4)
[14:12] funct3 = 3'b000
[11:7]  rd     = 5'b01000 (x8)
[6:0]   opcode = 7'b0010011 (7'h13)
```
- Opcode `7'h13` matches the OP-IMM branch.
- `instruction[14:12] == 3'b000` matches `ADDI`.
- Bits `[31:25]` (`7'b1111111`) are not checked against zero.
- Decoded controls: `instruction_valid = 1`, `reg_write = 1`, `alu_src_immediate = 1`, `alu_operation = 3'd0`.

---

## 5. Rejection of Unsupported Instructions

The Phase-3 processor strictly limits execution to the six supported operations. Instructions outside this subset are rejected combinationally:

| Instruction / Encoding | Opcode `[6:0]` | Funct3 `[14:12]` | Funct7 `[31:25]` | Rejection Mechanism in RTL |
|---|---|---|---|---|
| `MUL x1, x2, x3` (`0x023100b3`) | `7'h33` | `3'b000` | `7'b0000001` (`7'h01`) | Matches opcode `7'h33`, but `{7'b0000001, 3'b000}` does not match any valid R-type arm. Falls to `default: begin end`. |
| `SLLI x1, x2, 1` (`0x00111093`) | `7'h13` | `3'b001` | `7'b0000000` (`imm[11:5]`) | Matches opcode `7'h13`, but `instruction[14:12] == 3'b001 != 3'b000`. The `if` condition fails. |
| `LW x1, 0(x2)` (`0x00012083`) | `7'h03` | `3'b010` | *None* | Opcode `7'h03` is not handled in `case (instruction[6:0])`. Drops to major `default: begin end`. |
| `SW x1, 0(x2)` (`0x00112023`) | `7'h23` | `3'b010` | *None* | Opcode `7'h23` drops to major `default: begin end`. |
| `BEQ x1, x2, 0` (`0x00208063`) | `7'h63` | `3'b000` | *None* | Opcode `7'h63` drops to major `default: begin end`. |
| `BNE x1, x2, 0` (`0x00209063`) | `7'h63` | `3'b001` | *None* | Opcode `7'h63` drops to major `default: begin end`. |
| Sentinel zero word (`0x00000000`) | `7'h00` | `3'b000` | `7'b0000000` | Opcode `7'h00` drops to major `default: begin end`. |

When an instruction is rejected:
- `instruction_valid = 1'b0`
- `reg_write = 1'b0`
- `alu_src_immediate = 1'b0`
- `alu_operation = 3'd0`

---

## 6. Safety Properties and Safe Defaults

### Prevention of Inferred Latches
In Verilog-2001 combinational processes (`always @(*)`), every output register must receive an assignment under every conditional branch. Failing to do so causes synthesis tools to infer asynchronous transparent latches, which are unacceptable in synchronous digital design.
`control_unit.v` prevents latches by explicitly defining default values at the top of the `always` block before any `case` or `if` statements:
```verilog
instruction_valid = 1'b0;
reg_write = 1'b0;
alu_src_immediate = 1'b0;
alu_operation = 3'd0;
```

### Prevention of Unintended Writes on Unsupported Instructions
The ALU RTL (`rtl/alu.v`) defaults to addition for operation `3'd0` and returns `32'd0` for unmapped codes. If the control unit only drove `alu_operation = 3'd0` without clearing `reg_write`, an unsupported instruction (such as an illegal opcode or unsupported funct7) would compute `operand1 + operand2` and write that spurious result into `registers[rd]`!
By guaranteeing that unhandled instructions leave `reg_write = 1'b0` and `instruction_valid = 1'b0`:
1. `advance` evaluates to `1'b0` (`advance = !fault && fetch_valid && instruction_valid`).
2. `debug_reg_write` evaluates to `1'b0` (`debug_reg_write = advance && decoded_write && !reset && (debug_rd != 0)`).
3. The register file write enable remains low, completely protecting architectural state from corrupted writeback data.

### Decoder Validity vs. Immediate Generator `format_valid`
It is essential to distinguish `control_unit.instruction_valid` from `immediate_generator.format_valid`:
- `immediate_generator.v` evaluates only `imm_select`:
  ```verilog
  case (imm_select)
      2'b00: ... format_valid = 1'b1;
      2'b01: ... format_valid = 1'b1;
      2'b10: ... format_valid = 1'b1;
      default: format_valid = 1'b0;
  endcase
  ```
  `format_valid` merely indicates that the 2-bit selection input is valid (`00`, `01`, or `10`). In `rv32i_cpu.v`, `imm_select` is hardwired to `2'b00`, so `format_valid` is permanently `1'b1` regardless of the fetched instruction.
- The immediate generator has **no knowledge of opcodes, funct3, or funct7**.
- Exact instruction validation is the sole duty of `control_unit.instruction_valid`.
