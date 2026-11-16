`timescale 1ns/1ps
// Arithmetic-only phase-3 CPU. All state changes occur on the rising edge.
// Sticky diagnostics: cause 01 invalid fetch, 10 unsupported instruction.
// This is a teaching fault hold, not a privileged RISC-V trap mechanism.
module rv32i_cpu #(
    parameter INIT_FILE = "programs/arithmetic_smoke.hex",
    parameter [31:0] RESET_PC = 32'd0
) (
    input wire clk, reset,
    output wire [31:0] debug_pc, debug_instruction,
    output wire debug_reg_write,
    output wire [4:0] debug_rd,
    output wire [31:0] debug_write_data,
    output reg fault,
    output reg [1:0] fault_cause
);
    wire fetch_valid, instruction_valid, decoded_write, alu_src_immediate;
    wire [2:0] alu_operation;
    wire [31:0] operand1, operand2, immediate, alu_operand2, alu_result;
    wire advance;
    assign advance = !fault && fetch_valid && instruction_valid;
    assign debug_rd = debug_instruction[11:7];
    assign debug_reg_write = advance && decoded_write && !reset && (debug_rd != 5'd0);
    assign alu_operand2 = alu_src_immediate ? immediate : operand2;

    pc #(.RESET_PC(RESET_PC)) u_pc (
        .clk(clk), .reset(reset), .enable(advance),
        .next_pc(debug_pc + 32'd4), .current_pc(debug_pc));
    instruction_memory #(.INIT_FILE(INIT_FILE)) u_imem (
        .address(debug_pc), .instruction(debug_instruction), .address_valid(fetch_valid));
    control_unit u_control (
        .instruction(debug_instruction), .instruction_valid(instruction_valid),
        .reg_write(decoded_write), .alu_src_immediate(alu_src_immediate),
        .alu_operation(alu_operation));
    register_file u_register_file (
        .clk(clk), .reset(reset), .reg_write(debug_reg_write),
        .read_reg1(debug_instruction[19:15]), .read_reg2(debug_instruction[24:20]),
        .write_reg(debug_rd), .write_data(debug_write_data),
        .read_data1(operand1), .read_data2(operand2));
    immediate_generator u_immediate (
        .instruction(debug_instruction), .imm_select(2'b00),
        .immediate(immediate), .format_valid());
    alu u_alu (.a(operand1), .b(alu_operand2), .operation(alu_operation),
               .result(alu_result), .zero());
    // Memory input remains disconnected from RAM until phase-4 load/store integration.
    writeback_mux u_writeback (.select_memory(1'b0), .alu_result(alu_result),
                              .memory_data(32'd0), .write_data(debug_write_data));
    always @(posedge clk) begin
        if (reset) begin
            fault <= 1'b0;
            fault_cause <= 2'b00;
        end else if (!fault) begin
            if (!fetch_valid) begin
                fault <= 1'b1;
                fault_cause <= 2'b01;
            end else if (!instruction_valid) begin
                fault <= 1'b1;
                fault_cause <= 2'b10;
            end
        end
    end
endmodule
