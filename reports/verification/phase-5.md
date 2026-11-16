# Phase-5 verification

Fresh RTL regression: 276,741 HDL checks across 16 suites; ten known encoding
vectors; 38 reference instructions spanning ten operations and four branch
outcomes; all ten RTL tops compile as Verilog-2001. Fatal/no-summary/timeout
runner rejection probes passed. See [manifest](phase-5-manifest.json) for exact
input hashes, source base and dirty working-tree state at the run.

The only functional RTL edit is synthesis-specific ROM initialization. Simulation
behavior remains unchanged. A separate generated-netlist test passes 163 checks;
it is reported separately, not added to the historical RTL suite total.
See [synthesis evidence](../synthesis/phase-5.md).

Run `make verify` with Icarus and Yosys available. VCDs are real simulator outputs
under ignored build/. They may be regenerated; selected screenshots and the real
video require human submission preparation. No coverage of every program,
formal equivalence, device timing or hardware deployment is claimed.
