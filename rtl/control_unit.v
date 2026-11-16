`timescale 1ns/1ps
// Exact ten-instruction decoder; optional legacy arithmetic-only mode.
// ARITHMETIC_ONLY=1 retains the historical phase-3 regression contract.
module control_unit #(parameter ARITHMETIC_ONLY=0) (
    input wire [31:0] instruction,
    output reg instruction_valid,
    output reg reg_write,
    output reg alu_src_immediate,
    output reg [2:0] alu_operation,
    output reg [1:0] imm_select,
    output reg mem_read,mem_write,select_memory,
    output reg [1:0] branch_mode
);
    always @(*) begin
        instruction_valid = 1'b0;
        reg_write = 1'b0;
        alu_src_immediate = 1'b0;
        alu_operation = 3'd0;
        imm_select=0;mem_read=0;mem_write=0;select_memory=0;branch_mode=0;
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
            7'h03: if(!ARITHMETIC_ONLY && instruction[14:12]==2)begin
                instruction_valid=1;reg_write=1;alu_src_immediate=1;mem_read=1;select_memory=1;
            end
            7'h23: if(!ARITHMETIC_ONLY && instruction[14:12]==2)begin
                instruction_valid=1;alu_src_immediate=1;imm_select=1;mem_write=1;
            end
            7'h63: if(!ARITHMETIC_ONLY)begin
                case(instruction[14:12])
                    0:begin instruction_valid=1;imm_select=2;branch_mode=1;alu_operation=1;end
                    1:begin instruction_valid=1;imm_select=2;branch_mode=2;alu_operation=1;end
                    default:begin end
                endcase
            end
            default: begin end
        endcase
    end
endmodule
