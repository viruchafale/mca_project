# Phase-2 verification evidence

Run date: 16 November 2026. Tool: Icarus Verilog 13.0 stable.
The source commit, clean/dirty state, complete input hashes, tool version and
captured logs are recorded in the [phase-2 manifest](phase-2-manifest.json).
The original phase-1 evidence remains unchanged as a historical record.

## Observed cumulative results

| Testbench | Passing HDL checks | Scope |
|---|---:|---|
| tb_pc | 10 | Original PC state, reset, enable and wraparound |
| tb_instruction_memory | 20 | Original ROM, padding, alignment and bounds |
| tb_fetch | 11 | Original PC/ROM composition |
| tb_register_file | 103 | All registers/both ports, x0, synchronous write/reset, priority and recovery |
| tb_immediate_generator | 12,294 | All representable I/S/B immediates, literal instruction examples and invalid selector |
| tb_data_memory | 785 | Every RAM word, overwrite, enables, invalid accesses, reset preservation and recovery |
| Total | 13,223 | Standalone component behavior; no CPU instruction execution |

The immediate total consists of 4096 I values, 4096 S values, 4096 even B offsets,
five independently specified instruction words and one invalid selector case.
Exhaustive bit-field coverage must not be presented as 12,294 executed instructions.

Five RTL tops compile independently as Verilog-2001. Verification benches compile
as SystemVerilog-2012. Simulation results use case comparisons to reject unknown
values where a defined result is expected. No bench initializes DUT registers or
RAM by writing internal arrays through hierarchy.

## Encoding checks and regression failure behavior

The independent Python field extractor checks ten hand-calculated words, one per
target instruction, against expected register fields and immediates in
programs/encoding-vectors.json. All ten checks pass. These are software encoding
checks, separate from the HDL total; the extractor is not an RTL control unit or
instruction-set execution simulator.

The runner's three subprocess probes reject intentional fatal failure, an exit
without a PASS summary and a simulation timeout. Additional isolated entry-point
checks verified that missing encoding input, an unsupported encoding and invalid
RTL each cause exit status 1 and do not leave a successful verification manifest.
These checks are also separate from the HDL total.

## Reproduce

From the project root with Python 3 and Icarus installed:

```bash
python3 tools/run_tests.py --wave --self-check
```

Use IVERILOG and VVP for custom executable paths, and IVL_BASE for a relocated
compiler's lib/ivl directory, as described in README.md. No tool binaries or
machine-specific executable paths are committed with the portable evidence.

Generated outputs are ignored under build/: verification.json, compilation logs,
simulation logs, executables and six VCD waveforms. Curated log copies and trace
hashes appear in the manifest. Raw VCD headers contain run metadata, so trace
hashes can differ on another run even when architectural checks agree.

## What to inspect in the new waveforms

| VCD | Signals and expected behavior |
|---|---|
| tb_register_file.vcd | reset, reg_write, write_reg, write_data, read ports; zero-register protection and edge-only writes |
| tb_immediate_generator.vcd | instruction, imm_select, immediate, format_valid; sign transitions and final invalid selector |
| tb_data_memory.vcd | address, address_valid, mem_read, mem_write, reset, read_data; invalid accesses and data preservation during reset |

RAM is initialized through ordinary writes. Its contents are unspecified until
written, and reset intentionally preserves them. Validity and read enable are
separate: a valid disabled read returns zero, and a reset does not require an
enabled read of previously initialized data to become zero.

## Limits and handoff

There is no ALU, exact RTL decoder, branch unit, writeback mux or CPU top in this
milestone. Component interfaces are verified, but ADDI, LW, SW and branches are
not yet integrated instruction executions. Synthesis, FPGA utilization and maximum
hardware frequency remain unmeasured.

The instruction-set files were initially task outlines. Viraj subsequently requested
one lead-prepared documentation commit containing references and worked examples;
Kaustubh's independent additions and own-account contribution remain pending.
Follow CONTRIBUTING.md. Phase-3 must
start from the accepted phase-2 tip including his real commit, not from phase-1.
