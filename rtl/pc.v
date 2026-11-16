// RV32I program-counter state. Verilog-2001; active-high synchronous reset.
`timescale 1ns/1ps
module pc #(
    parameter [31:0] RESET_PC = 32'h0000_0000
) (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [31:0] next_pc,
    output reg [31:0] current_pc
);
    always @(posedge clk) begin
        if (reset)
            current_pc <= RESET_PC;
        else if (enable)
            current_pc <= next_pc;
    end
endmodule
