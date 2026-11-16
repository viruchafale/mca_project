`timescale 1ns/1ps
module tb_instruction_memory;
    reg [31:0] address = 0;
    wire [31:0] instruction, nop_instruction;
    wire valid, nop_valid;
    integer checks = 0;
    instruction_memory dut(address, instruction, valid);
    instruction_memory #(.INIT_FILE("")) padding_only(address, nop_instruction, nop_valid);
    task expect_word(input [31:0] addr, input bit expected_valid,
                     input [31:0] expected_word);
        begin
            address = addr; #1;
            checks = checks + 1;
            if (valid !== expected_valid || instruction !== expected_word)
                $fatal(1, "FAIL: addr=%08h valid=%b word=%08h expected=%08h",
                       addr, valid, instruction, expected_word);
        end
    endtask
    initial begin
        if ($test$plusargs("wave")) begin
            $dumpfile("build/tb_instruction_memory.vcd"); $dumpvars(0, tb_instruction_memory);
        end
        expect_word(0, 1, 32'h00500093);
        expect_word(4, 1, 32'h00a00113);
        expect_word(8, 1, 32'h002081b3);
        expect_word(12, 1, 32'h00302023);
        expect_word(16, 1, 32'h00002203);
        expect_word(20, 1, 32'h00418463);
        expect_word(24, 1, 32'h002082b3);
        expect_word(28, 1, 32'h00000063);
        expect_word(32, 1, 32'h00000013);
        expect_word(32'h3fc, 1, 32'h00000013);
        expect_word(1, 0, 0);
        expect_word(2, 0, 0);
        expect_word(3, 0, 0);
        expect_word(32'h3fd, 0, 0);
        expect_word(32'h400, 0, 0);
        expect_word(32'h404, 0, 0);
        expect_word(32'h80000000, 0, 0);
        expect_word(32'hfffffffc, 0, 0);
        expect_word(0, 1, 32'h00500093);
        checks = checks + 1;
        if (nop_valid !== 1 || nop_instruction !== 32'h13)
            $fatal(1, "FAIL: empty-image ROM must initialize to RV32I NOP");
        $display("PASS: tb_instruction_memory checks=%0d", checks);
        $finish;
    end
    initial begin #1000; $fatal(1, "FAIL: instruction ROM test timeout"); end
endmodule
