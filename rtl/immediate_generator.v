// RV32I I/S/B immediate generator. Verilog-2001.
// imm_select: 00=I, 01=S, 10=B, 11=invalid.
// format_valid describes the selector only; exact instruction validation
// belongs to the future control unit. B output already includes bit zero.
`timescale 1ns/1ps
module immediate_generator (
    input wire [31:0] instruction,
    input wire [1:0] imm_select,
    output reg [31:0] immediate,
    output reg format_valid
);
    always @(*) begin
        immediate = 32'd0;
        format_valid = 1'b1;
        case (imm_select)
            2'b00: immediate = {{20{instruction[31]}}, instruction[31:20]};
            2'b01: immediate = {{20{instruction[31]}}, instruction[31:25],
                               instruction[11:7]};
            2'b10: immediate = {{19{instruction[31]}}, instruction[31],
                               instruction[7], instruction[30:25],
                               instruction[11:8], 1'b0};
            default: begin
                immediate = 32'd0;
                format_valid = 1'b0;
            end
        endcase
    end
endmodule
