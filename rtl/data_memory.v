// 256 x 32-bit data RAM with checked byte addresses. Verilog-2001.
// Reads are asynchronous and writes occur on the rising edge.
// Reset suppresses writes and PRESERVES RAM. Unwritten words are unspecified.
`timescale 1ns/1ps
module data_memory (
    input wire clk,
    input wire reset,
    input wire mem_read,
    input wire mem_write,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output wire [31:0] read_data,
    output wire address_valid
);
    reg [31:0] words [0:255];

    assign address_valid = (address[31:10] == 22'd0)
                         && (address[1:0] == 2'b00);
    assign read_data = (mem_read && address_valid) ? words[address[9:2]] : 32'd0;

    always @(posedge clk) begin
        if (!reset && mem_write && address_valid)
            words[address[9:2]] <= write_data;
    end
endmodule
