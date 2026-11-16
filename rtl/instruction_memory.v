// 256 x 32-bit asynchronous instruction ROM. Verilog-2001.
// A valid, unprogrammed word is ADDI x0,x0,0. Invalid fetches are flagged;
// the future CPU must gate state writes on address_valid, not execute the
// returned invalid word as though it were a supported instruction.
`timescale 1ns/1ps
module instruction_memory #(
    parameter INIT_FILE = "programs/fetch_smoke.hex"
) (
    input wire [31:0] address,
    output wire [31:0] instruction,
    output wire address_valid
);
    localparam [31:0] NOP = 32'h0000_0013;
    reg [31:0] words [0:255];
    integer i;
`ifndef SYNTHESIS
    integer image_file;
`endif
    assign address_valid = (address[31:10] == 22'd0)
                         && (address[1:0] == 2'b00);
    assign instruction = address_valid ? words[address[9:2]] : 32'h0000_0000;

    initial begin
        // Simulation supports partial images with NOP padding. For synthesis,
        // use exactly one initializer per word: a full 256-word image or NOPs.
        // Mixing procedural defaults and readmemh can mask the image in Yosys.
`ifndef SYNTHESIS
        for (i = 0; i < 256; i = i + 1)
            words[i] = NOP;
`else
        if (INIT_FILE == "")
            for (i = 0; i < 256; i = i + 1)
                words[i] = NOP;
`endif
        if (INIT_FILE != "") begin
`ifndef SYNTHESIS
            image_file = $fopen(INIT_FILE, "r");
            if (image_file == 0) begin
                $display("ERROR: cannot open instruction image: %0s", INIT_FILE);
                $finish;
            end
            $fclose(image_file);
`endif
            $readmemh(INIT_FILE, words);
        end
    end
endmodule
