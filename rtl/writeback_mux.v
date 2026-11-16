`timescale 1ns/1ps
module writeback_mux (
    input wire select_memory,
    input wire [31:0] alu_result, memory_data,
    output wire [31:0] write_data
);
    assign write_data = select_memory ? memory_data : alu_result;
endmodule
