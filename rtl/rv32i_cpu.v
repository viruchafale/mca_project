`timescale 1ns/1ps
// Ten-instruction educational subset. Sticky causes: 01 fetch, 10 illegal,
// 11 invalid data access or taken misaligned branch. No privileged traps.
module rv32i_cpu #(
    parameter INIT_FILE="programs/full_isa.hex",
    parameter [31:0] RESET_PC=32'd0,
    parameter ARITHMETIC_ONLY=0
) (
    input wire clk,reset,
    output wire [31:0] debug_pc,debug_instruction,
    output wire debug_reg_write,
    output wire [4:0] debug_rd,
    output wire [31:0] debug_write_data,
    output reg fault,
    output reg [1:0] fault_cause,
    output wire debug_mem_read,debug_mem_write,
    output wire [31:0] debug_mem_address,debug_mem_write_data,debug_mem_read_data,
    output wire debug_branch_taken,
    output wire [31:0] debug_next_pc,
    output wire debug_execute
);
    wire fetch_valid,instruction_valid,decoded_write,alu_src_immediate;
    wire decoded_mem_read,decoded_mem_write,select_memory,data_valid,target_aligned;
    wire [1:0] imm_select,branch_mode;
    wire [2:0] alu_operation;
    wire [31:0] operand1,operand2,immediate,alu_operand2,alu_result;
    wire access_fault,branch_fault,advance;
    assign access_fault=(decoded_mem_read||decoded_mem_write)&&!data_valid;
    assign branch_fault=debug_branch_taken&&!target_aligned;
    assign advance=!fault&&fetch_valid&&instruction_valid&&!access_fault&&!branch_fault;
    assign debug_execute=advance&&!reset;
    assign debug_rd=debug_instruction[11:7];
    assign debug_reg_write=debug_execute&&decoded_write&&(debug_rd!=0);
    assign alu_operand2=alu_src_immediate?immediate:operand2;
    assign debug_mem_address=alu_result;
    assign debug_mem_write_data=operand2;
    assign debug_mem_read=debug_execute&&decoded_mem_read;
    assign debug_mem_write=debug_execute&&decoded_mem_write;
    pc #(.RESET_PC(RESET_PC)) u_pc(.clk(clk),.reset(reset),.enable(advance),
        .next_pc(debug_next_pc),.current_pc(debug_pc));
    instruction_memory #(.INIT_FILE(INIT_FILE)) u_imem(.address(debug_pc),
        .instruction(debug_instruction),.address_valid(fetch_valid));
    control_unit #(.ARITHMETIC_ONLY(ARITHMETIC_ONLY)) u_control(
        .instruction(debug_instruction),.instruction_valid(instruction_valid),
        .reg_write(decoded_write),.alu_src_immediate(alu_src_immediate),
        .alu_operation(alu_operation),.imm_select(imm_select),
        .mem_read(decoded_mem_read),.mem_write(decoded_mem_write),
        .select_memory(select_memory),.branch_mode(branch_mode));
    register_file u_register_file(.clk(clk),.reset(reset),.reg_write(debug_reg_write),
        .read_reg1(debug_instruction[19:15]),.read_reg2(debug_instruction[24:20]),
        .write_reg(debug_rd),.write_data(debug_write_data),
        .read_data1(operand1),.read_data2(operand2));
    immediate_generator u_immediate(.instruction(debug_instruction),.imm_select(imm_select),
        .immediate(immediate),.format_valid());
    alu u_alu(.a(operand1),.b(alu_operand2),.operation(alu_operation),.result(alu_result),.zero());
    data_memory u_dmem(.clk(clk),.reset(reset),.mem_read(debug_mem_read),
        .mem_write(debug_mem_write),.address(alu_result),.write_data(operand2),
        .read_data(debug_mem_read_data),.address_valid(data_valid));
    writeback_mux u_writeback(.select_memory(select_memory),.alu_result(alu_result),
        .memory_data(debug_mem_read_data),.write_data(debug_write_data));
    branch_unit u_branch(.pc(debug_pc),.immediate(immediate),.operand1(operand1),
        .operand2(operand2),.branch_mode(branch_mode),.taken(debug_branch_taken),
        .target_aligned(target_aligned),.next_pc(debug_next_pc));
    always @(posedge clk)begin
        if(reset)begin fault<=0;fault_cause<=0;end
        else if(!fault)begin
            if(!fetch_valid)begin fault<=1;fault_cause<=1;end
            else if(!instruction_valid)begin fault<=1;fault_cause<=2;end
            else if(access_fault||branch_fault)begin fault<=1;fault_cause<=3;end
        end
    end
endmodule
