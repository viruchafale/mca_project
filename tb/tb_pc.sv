`timescale 1ns/1ps
module tb_pc;
    reg clk = 0;
    reg reset = 0;
    reg enable = 0;
    reg [31:0] next_pc = 0;
    wire [31:0] current_pc, alternate_pc;
    integer checks = 0;
    pc dut(clk, reset, enable, next_pc, current_pc);
    pc #(.RESET_PC(32'h80)) alternate(clk, reset, enable, next_pc, alternate_pc);
    task check(input bit condition, input string label);
        begin
            checks = checks + 1;
            if (!condition) $fatal(1, "FAIL: %s", label);
        end
    endtask
    task tick;
        begin #4; clk = 1; #1; clk = 0; #5; end
    endtask
    initial begin
        if ($test$plusargs("wave")) begin
            $dumpfile("build/tb_pc.vcd"); $dumpvars(0, tb_pc);
        end
        reset = 1; enable = 1; next_pc = 32'h44; tick();
        check(current_pc === 0, "reset takes priority over enable");
        check(alternate_pc === 32'h80, "parameterized reset address");
        reset = 0; next_pc = 4; #1;
        check(current_pc === 0, "next_pc cannot change PC without an edge");
        tick(); check(current_pc === 4, "PC advances to supplied next address");
        next_pc = 8; tick(); check(current_pc === 8, "consecutive advance");
        enable = 0; next_pc = 32'h100; tick();
        check(current_pc === 8, "disabled PC holds");
        reset = 1; #1;
        check(current_pc === 8, "reset is synchronous");
        tick(); check(current_pc === 0, "reset works with enable low");
        reset = 0; enable = 1; next_pc = 32'hffff_fffc; tick();
        check(current_pc === 32'hffff_fffc, "full-width next address");
        next_pc = current_pc + 32'd4; tick();
        check(current_pc === 0, "32-bit increment wraps");
        $display("PASS: tb_pc checks=%0d", checks);
        $finish;
    end
    initial begin #1000; $fatal(1, "FAIL: PC test timeout"); end
endmodule
