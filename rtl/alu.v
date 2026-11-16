`timescale 1ns/1ps
// ALU codes shared with control_unit: ADD=0 SUB=1 AND=2 OR=3 XOR=4.
module alu (
    input wire [31:0] a, b,
    input wire [2:0] operation,
    output reg [31:0] result,
    output wire zero
);
    always @(*) begin
        case (operation)
            3'd0: result = a + b;
            3'd1: result = a - b;
            3'd2: result = a & b;
            3'd3: result = a | b;
            3'd4: result = a ^ b;
            default: result = 32'd0;
        endcase
    end
    assign zero = (result == 32'd0);
endmodule
