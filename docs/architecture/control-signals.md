# Control signals — Pratyush's Phase-3 assignment

Status: awaiting Pratyush's independently reviewed tables and examples.

Build a table for instruction_valid, reg_write, alu_src_immediate and
alu_operation for every implemented instruction. Record ALU codes 0-4.
Explain final debug_reg_write gating with reset, fault, fetch validity and x0.

Trace when PC advances, when it holds, and when fault_cause becomes 01 or 10.
Use the actual CPU bench and waveform to explain signal values before/after a
rising edge. Record only review/test runs actually performed; no CPU memory or
branch execution claim is supported yet.
