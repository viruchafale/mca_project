# Phase-5 synthesis and resource observations

Measured using Yosys 0.71 via yowasp-yosys 0.71.0.0.post1285.
The exact run identity, input hashes and output hashes are in
[manifest](phase-5-manifest.json); the complete [log](phase-5-synthesis.log)
and [statistics](phase-5-stat.json) are retained. Sources were the working-tree
Phase-5 snapshot on accepted c90f577, not that parent commit alone.

## Reproduce

```bash
make verify
```

Requires Python 3, Icarus and Yosys. YOSYS can select yowasp-yosys.
The synthesis script is synth/generic.ys. Run from repository root. All generated
netlists and executables stay in ignored build/synthesis/.
ROM images for synthesis must contain exactly 256 eight-digit hex words.
The runner checks the default full_isa image before launching the tool.

## Measured generic implementation

| Quantity | Count |
|---|---:|
| Hierarchical cell total, including module instances | 22704 |
| Hierarchical module instances included above | 9 |
| Leaf generic cells (subtract instances) | 22695 |
| Generic flip-flop cells | 9251 |
| Mux cells | 9555 |
| Residual processes/memories | 0 / 0 |
| Inferred latch types | 0 |

The RAM contributes 8,192 enabled DFF cells and a large asynchronous read mux.
The register file contributes 1,024 synchronous-reset enabled DFF cells. PC/fault
state adds 35. These are generic bit cells, not LUTs, BRAMs or ASIC area units.
ROM constants are optimized for the fixed program, so counts depend on that image.
The implementation is not board-mapped or placed/routed.

| Module (parameterized names retained) | Cells in module |
|---|---:|
| rv32i_cpu | 57 |
| branch_unit | 327 |
| writeback_mux | 32 |
| $paramodpcRESET_PC=32'00000000000000000000000000000000 | 32 |
| alu | 620 |
| data_memory | 16740 |
| immediate_generator | 30 |
| register_file | 4586 |
| $paramod$8fc95d078a9274df1b7576e88fad4b50d59ea9a1instruction_memory | 230 |
| $paramodcontrol_unitARITHMETIC_ONLY=s32'00000000000000000000000000000000 | 50 |

Module-local counts include instances in the top; do not double-count them when
summing leaf cells. No timing library, clock constraints or device was supplied.
No Fmax, timing slack, power, physical area or FPGA utilization is available.
The RTL single-cycle model has CPI=1 for valid execution with zero-wait memories;
simulation clock settings are not a measurement of achievable hardware speed.

## ROM synthesis defect and regression

An initial structural synthesis passed but its ROM became all NOPs because the
procedural initialization loop masked readmemh contents. The port-only netlist
test failed immediately on instruction one (00000013 instead of 04000093).
Phase-5 removes the overlapping NOP defaults only for synthesis with a nonempty
image; simulation still supports partial-image NOP padding. For an empty filename,
synthesis initializes NOPs. This flow requires complete images when a file is used.
Only the corrected run is presented as the final successful resource result.

After correction, structural check -assert passed and the generated netlist
passed 163 port-observable checks over the 38-instruction reference trace,
including load/store values, write enables and branch next-PC decisions.
See [netlist check](phase-5-netlist-check.json) and [log](phase-5-netlist-simulation.log).
It has no hierarchical register/RAM access and is not a formal equivalence proof.
The full RTL regression separately passed 276,741 checks and runner probes.

## Hardware deployment boundary

No board was specified. An actual deployment requires target selection, pin/clock
constraints, reset conditioning and timing analysis. Asynchronous RAM reads may
map to distributed logic rather than synchronous block RAM. Adapting to a
synchronous RAM changes the single-cycle memory contract and must be reverified.
Do not invent constraints or claim a bitstream/hardware demo from this generic run.
