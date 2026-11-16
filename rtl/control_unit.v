`timescale 1ns/1ps
// Phase-3 exact decoder: six arithmetic instructions only.
// LW/SW/BEQ/BNE deliberately remain illegal until phase-4 integration.
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
