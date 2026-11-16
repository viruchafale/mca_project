# Phase-4 Waveform Evidence and Walkthrough

**Document Owner:** Bhargav (Phase 4 Verification and Simulation Lead)<br>
**Target Commit:** `e63f8d26ab8afe7e9f75c3b32ba865f6452c7679` (published Phase-4 baseline)<br>
**Branch:** `phase-4`<br>
**Evidence Source:** Genuine value-change dump (VCD) files generated under `build/` during reproduction run on 2026-11-16.<br>
**Inspection Methodology:** Direct programmatic VCD signal analysis and timestamp verification using Python; graphical GTKWave screenshots marked pending personal interactive session.

---

## 1. Introduction and Signal Semantics

This walkthrough documents five critical architectural behaviors of the Single-Cycle RV32I Processor by inspecting actual signal transitions from the simulation waveforms.

### 1.1 Key Interface and Debug Signals

All signal names match the RTL port declarations in `rtl/rv32i_cpu.v`:

- `clk`, `reset`: System clock and active-high synchronous reset.
- `debug_pc [31:0]`: Architectural program counter for the current instruction cycle.
- `debug_instruction [31:0]`: 32-bit instruction word fetched from instruction ROM.
- `debug_execute`: Master qualification signal. Asserted high (`1`) only when `reset` is low, no prior sticky fault exists, and no current cycle fault (fetch, decode, data alignment, or branch target alignment) is present.
- `debug_reg_write`: Qualified register file write-enable. High only when `debug_execute = 1`, decoded `reg_write = 1`, and `debug_rd != 5'd0`.
- `debug_rd [4:0]`, `debug_write_data [31:0]`: Destination register and writeback value.
- `debug_mem_read`, `debug_mem_write`: Qualified memory read/write enables. Gated by `debug_execute`.
- `debug_mem_address [31:0]`, `debug_mem_write_data [31:0]`, `debug_mem_read_data [31:0]`: RAM byte address and data busses.
- `debug_branch_taken`, `debug_next_pc [31:0]`: Evaluated branch decision and target address for the upcoming cycle.
- `fault`, `fault_cause [1:0]`: Latched diagnostic fault indicator and 2-bit diagnostic reason code.

> [!IMPORTANT]
> **Understanding `debug_execute` and Control Gating:**
> Combinational decode proposals (such as raw ALU operations or undecoded memory writes) must not be interpreted as executed instructions. An instruction only retires and commits architectural state if `debug_execute = 1` at the rising clock edge. If a fault or reset occurs, `debug_execute` forces write enables low before the edge, guaranteeing side-effect suppression.

---

## 2. Walkthrough Case 1: Store Word (`SW`) Followed by Load Word (`LW`)

- **Suite & VCD:** `tb_full_isa.sv` $\rightarrow$ `build/tb_full_isa.vcd`
- **Assembly Context:**
  ```assembly
  0x00: addi x1, x0, 64   # x1 = 64 (0x040, RAM base pointer)
  0x04: addi x2, x0, 7    # x2 = 7 (test value)
  0x08: sw   x2, 0(x1)    # Store word 7 to mem[64]
  0x0c: lw   x3, 0(x1)    # Load word from mem[64] into x3
  ```

### Waveform Observation and Timing

```
Time:          20 ns        25 ns (SW Edge)   30 ns        35 ns (LW Edge)   40 ns
clk:           ____/‾‾\________/‾‾\_____________/‾‾\________/‾‾\_____________/‾‾\
debug_pc:      [   0x04   ][       0x08        ][       0x0c        ][   0x10   ]
debug_insn:    [  ADDI x2 ][      SW x2        ][      LW x3        ][   BEQ    ]
debug_execute: 11111111111111111111111111111111111111111111111111111111111111111
mem_write:     00000000000011111111111111111111000000000000000000000000000000000
mem_read:      00000000000000000000000000000000111111111111111111110000000000000
mem_addr:      [   0x07   ][      0x040        ][      0x040        ][   0x00   ]
store_data:    [   0x00   ][      0x007        ][      0x000        ][   0x07   ]
reg_write:     11111111111100000000000000000000111111111111111111110000000000000
debug_rd:      [   x02    ][       x00         ][       x03         ][   x08    ]
write_data:    [   0x07   ][      0x040        ][      0x007        ][   0x00   ]
```

### Transition Analysis
1. **At $t = 25.0\,\text{ns}$ (`SW` Cycle commit):**
   - `debug_pc = 0x00000008`, `debug_instruction = 0x0020a023`.
   - The ALU computes effective address $\text{rs1} + \text{offset} = 64 + 0 = 64$ (`0x040`).
   - `debug_mem_write = 1`, `debug_mem_read = 0`, `debug_reg_write = 0`.
   - Store data `debug_mem_write_data = 7` is presented to `data_memory`.
   - On the rising clock edge at $25.0\,\text{ns}$, `u_dmem.words[16]` is clocked with value `7`.
2. **At $t = 35.0\,\text{ns}$ (`LW` Cycle commit):**
   - `debug_pc = 0x0000000c`, `debug_instruction = 0x0000a183`.
   - The ALU computes effective address $64 + 0 = 64$ (`0x040`).
   - `debug_mem_read = 1`, `debug_mem_write = 0`.
   - `data_memory` performs an asynchronous read: `debug_mem_read_data` immediately reflects `0x00000007`.
   - `writeback_mux` selects memory data (`select_memory = 1`).
   - Destination is `debug_rd = 5'd3` (`x3`) with `debug_reg_write = 1` and `debug_write_data = 7`.
   - On the rising clock edge at $35.0\,\text{ns}$, register `x3` is updated with `7`.

**Conclusion:** Matches expected single-cycle RAW (read-after-write) memory semantics: synchronous store followed by asynchronous load and synchronous register writeback.

---

## 3. Walkthrough Case 2: Taken and Not-Taken Branches (`BEQ` and `BNE`)

- **Suite & VCD:** `tb_full_isa.sv` $\rightarrow$ `build/tb_full_isa.vcd`
- **Assembly Context:**
  ```assembly
  0x10: beq x2, x3, equal   # x2=7, x3=7 -> Taken to 0x18
  0x14: addi x4, x0, 99     # Skipped (poison)
  0x18: equal: addi x4, x0, 1
  0x1c: bne x2, x3, poison  # x2=7, x3=7 -> Not Taken, fall through to 0x20
  ```

### Waveform Observation and Timing

| Simulation Time | `debug_pc` | Instruction | Register Operands | `debug_branch_taken` | `debug_next_pc` | Architectural Action |
|---|---|---|---|---:|---|---|
| **$t = 45.0\,\text{ns}$** | `0x00000010` | `BEQ x2, x3, +8` | $x2 = 7$, $x3 = 7$ | **`1`** | **`0x00000018`** | Condition $7 == 7$ holds. Target $\text{0x10} + 8 = \text{0x18}$ selected. |
| **$t = 55.0\,\text{ns}$** | `0x00000018` | `ADDI x4, x0, 1` | $x0 = 0, \text{imm} = 1$ | `0` | `0x0000001c` | PC jumps directly to `0x18`. Poison at `0x14` skipped. |
| **$t = 65.0\,\text{ns}$** | `0x0000001c` | `BNE x2, x3, +100` | $x2 = 7$, $x3 = 7$ | **`0`** | **`0x00000020`** | Condition $7 \neq 7$ fails. Next PC falls through to sequential $\text{PC} + 4$. |
| **$t = 75.0\,\text{ns}$** | `0x00000020` | `ADDI x5, x0, 3` | $x0 = 0, \text{imm} = 3$ | `0` | `0x00000024` | Core executes sequential instruction at `0x20`. |

### Transition Analysis
- For `BEQ` at $45.0\,\text{ns}$, the branch comparator evaluates equality. Because both registers contain `7`, `debug_branch_taken` asserts high. The branch unit computes $\text{0x10} + 8 = \text{0x18}$, which is loaded into the PC on the $45.0\,\text{ns}$ edge.
- For `BNE` at $65.0\,\text{ns}$, the branch comparator evaluates inequality. Because operands are equal, `debug_branch_taken` remains low. The multiplexer selects $\text{PC} + 4 = \text{0x20}$, avoiding the poison target.

---

## 4. Walkthrough Case 3: Backward Loop Execution

- **Suite & VCD:** `tb_full_isa.sv` $\rightarrow$ `build/tb_full_isa.vcd`
- **Assembly Context:**
  ```assembly
  0x20: addi x5, x0, 3      # Loop counter x5 = 3
  0x24: addi x6, x0, 0      # Accumulator x6 = 0
  0x28: loop: add x6, x6, x5
  0x2c: addi x5, x5, -1
  0x30: bne x5, x0, loop    # Backward branch (displacement = -8)
  ```

### Waveform Trace Across Loop Cycles

```
Iter 1:
  t =  95.0 ns | pc=0x28 insn=ADD  x6,x6,x5 | x6=0, x5=3 -> wd=3 (x6 updated to 3)
  t = 105.0 ns | pc=0x2c insn=ADDI x5,x5,-1 | x5=3, imm=-1 -> wd=2 (x5 updated to 2)
  t = 115.0 ns | pc=0x30 insn=BNE  x5,x0    | x5=2 != 0 -> taken=1, next_pc=0x28 (BACKWARD JUMP)

Iter 2:
  t = 125.0 ns | pc=0x28 insn=ADD  x6,x6,x5 | x6=3, x5=2 -> wd=5 (x6 updated to 5)
  t = 135.0 ns | pc=0x2c insn=ADDI x5,x5,-1 | x5=2, imm=-1 -> wd=1 (x5 updated to 1)
  t = 145.0 ns | pc=0x30 insn=BNE  x5,x0    | x5=1 != 0 -> taken=1, next_pc=0x28 (BACKWARD JUMP)

Iter 3 (Exit):
  t = 155.0 ns | pc=0x28 insn=ADD  x6,x6,x5 | x6=5, x5=1 -> wd=6 (x6 updated to 6)
  t = 165.0 ns | pc=0x2c insn=ADDI x5,x5,-1 | x5=1, imm=-1 -> wd=0 (x5 updated to 0)
  t = 175.0 ns | pc=0x30 insn=BNE  x5,x0    | x5=0 == 0 -> taken=0, next_pc=0x34 (FALL-THROUGH EXIT)

Post-Loop:
  t = 185.0 ns | pc=0x34 insn=SW   x6,-4(x1)| Stores final sum 6 to mem[60]
```

### Transition Analysis
- The B-type immediate decoder reconstructs the negative branch offset: bits $[12|10:5|4:1|11]$ decode to `0xfffffffc` ($-4$ halfwords = $-8$ bytes).
- At $\text{PC} = \text{0x30}$, the target is $\text{0x30} - 8 = \text{0x28}$.
- On the first two iterations, $x5 \neq 0$, causing `debug_branch_taken = 1` and jumping backward to `0x28`.
- On iteration 3, $x5$ reaches $0$. `debug_branch_taken` drops to $0$, and `debug_next_pc` selects $\text{0x34}$, exiting the loop with accumulator $x6 = 6$ ($3 + 2 + 1$).

---

## 5. Walkthrough Case 4: Fault Pre-Edge Side-Effect Suppression and Sticky Hold

- **Suite & VCD:** `tb_full_faults.sv` $\rightarrow$ `build/tb_full_faults.vcd`
- **Scenario:** Misaligned Store Word (`START = 0x000`, `BAD_PC = 0x008`)

### Signal Progression
1. **Pre-Fault State ($t = 25.0\,\text{ns}$):**
   - Core is executing at `pc = 0x004`. `debug_execute = 1`, `fault = 0`, `cause = 00`.
2. **Fault Cycle ($t = 34.0\,\text{ns}$ to $35.0\,\text{ns}$):**
   - Core advances to `pc = 0x008` where an instruction attempts an unaligned store (`addr = 0x002`).
   - `data_memory` asserts `access_fault = 1` because `addr[1:0] != 2'b00`.
   - **Combinational Gating:** `debug_execute` immediately falls to `0`. Consequently, `debug_mem_write` and `debug_reg_write` are forced to `0`.
   - Memory word 0 (`u_dmem.words[0]`) remains intact at `1`.
3. **Latched Sticky Fault ($t = 35.0\,\text{ns}$ clock edge):**
   - `fault` latches to `1`.
   - `fault_cause` latches to `2'b11` (decimal 3: data address/alignment fault).
   - PC enable is deasserted: `u_pc.enable = 0`.
4. **Sticky Hold ($t = 35.0\,\text{ns}$ to $145.0\,\text{ns}$):**
   - Over subsequent cycles ($t = 45, 55, 65\,\text{ns}$), the PC remains frozen at `0x008`.
   - All write enables remain clamped at `0`. Following instructions (such as writes to `x31`) are skipped.
5. **Reset Recovery ($t = 145.0\,\text{ns}$):**
   - Active-high `reset` is applied. PC returns to `RESET_PC` (`0x000`), `fault` clears to `0`, and initialized RAM survives.

---

## 6. Walkthrough Case 5: Synchronous CPU Reset During Pending Store

- **Suite & VCD:** `tb_cpu_reset_memory.sv` $\rightarrow$ `build/tb_cpu_reset_memory.vcd`
- **Context:** RAM word 0 already contains `11`. At `pc = 0x00c`, a store instruction attempts to overwrite word 0 with `22`.

### Signal Progression
1. **Store Pending ($t = 34.0\,\text{ns}$):**
   - `debug_pc = 0x00c`, `debug_instruction = SW x1, 0(x0)`.
   - `debug_mem_write = 1`, `debug_mem_address = 0x000`, `debug_mem_write_data = 22`.
   - If the clock edge occurs with `mem_write = 1`, word 0 will be overwritten with `22`.
2. **Reset Assertion Before Edge ($t = 40.0\,\text{ns}$):**
   - Testbench drives `reset = 1` exactly 5 ns before the rising edge.
   - Combinational logic gates memory write: `debug_mem_write` drops from `1` to `0` immediately at $t = 40.0\,\text{ns}$.
3. **Clock Edge with Reset Active ($t = 45.0\,\text{ns}$):**
   - Rising clock edge arrives while `reset = 1`.
   - Because `debug_mem_write = 0`, the store is cancelled!
   - RAM verification: `dut.u_dmem.words[0]` retains original value `11`.
   - Processor registers: `u_register_file.registers[1]` clears to `0`, `pc` resets to `0x000`.
4. **Post-Reset Valid Store ($t = 85.0\,\text{ns}$):**
   - After reset deassertion, the processor re-executes normally. At $t = 85.0\,\text{ns}$, a subsequent valid store completes, successfully writing `22` to word 0.

---

## 7. Submission Artifacts Status

- **Waveform Inspection:** Successfully performed via programmatic VCD analysis of genuine simulation dumps.
- **GTKWave Graphical Screenshots:** Marked as **Pending**. If graphical image artifacts (`.png`) are required for the final Phase-5 college submission or academic report, they will be captured interactively in GTKWave by Bhargav and committed under `docs/verification/waveforms/`.
