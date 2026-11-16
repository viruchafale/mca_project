`timescale 1ns/1ps
// Composition test only: PC+4 frontend, without an instruction decoder or CPU.
module tb_fetch;
    reg clk = 0, reset = 1, enable = 1;
    wire [31:0] address, instruction;
    wire address_valid;
    integer checks = 0;
    integer index;
    reg [31:0] expected [0:7];
    pc pc_state(clk, reset, enable, address + 32'd4, address);
    instruction_memory rom(address, instruction, address_valid);
    always #5 clk = ~clk;
    task check(input bit condition, input string label);
        begin
            checks = checks + 1;
            if (!condition) $fatal(1, "FAIL: %s PC=%08h instruction=%08h",
                                  label, address, instruction);
        end
    endtask
    initial begin
        expected[0]=32'h00500093; expected[1]=32'h00a00113;
        expected[2]=32'h002081b3; expected[3]=32'h00302023;
        expected[4]=32'h00002203; expected[5]=32'h00418463;
        expected[6]=32'h002082b3; expected[7]=32'h00000063;
        if ($test$plusargs("wave")) begin
            $dumpfile("build/tb_fetch.vcd"); $dumpvars(0, tb_fetch);
        end
        @(negedge clk);
        check(address === 0 && address_valid === 1 && instruction === expected[0],
              "reset exposes first ROM instruction");
        reset = 0;
        for (index=1; index<8; index=index+1) begin
            @(negedge clk);
            check(address === index*4 && instruction === expected[index] && address_valid === 1,
                  "sequential fetch order");
        end
        enable = 0;
        repeat (2) @(negedge clk);
        check(address === 28 && instruction === expected[7], "PC hold also holds fetch");
        reset = 1;
        @(negedge clk);
        check(address === 0 && instruction === expected[0], "reset restarts held fetch");
        reset = 0; enable = 1;
        repeat (256) @(negedge clk);
        check(address === 32'h400 && address_valid === 0 && instruction === 0,
              "fetch beyond ROM is invalid and does not alias");
        $display("PASS: tb_fetch checks=%0d", checks);
        $finish;
    end
    initial begin #10000; $fatal(1, "FAIL: fetch test timeout"); end
endmodule
