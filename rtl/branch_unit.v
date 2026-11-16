`timescale 1ns/1ps
module branch_unit (
    input wire [31:0] pc,immediate,operand1,operand2,
    input wire [1:0] branch_mode,
    output wire taken,target_aligned,
    output wire [31:0] next_pc
);
    wire [31:0] target;
    assign target=pc+immediate;
    assign taken=((branch_mode==1)&&(operand1==operand2)) ||
                 ((branch_mode==2)&&(operand1!=operand2));
    assign target_aligned=(target[1:0]==0);
    assign next_pc=taken?target:(pc+32'd4);
endmodule
