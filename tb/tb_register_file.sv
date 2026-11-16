`timescale 1ns/1ps
module tb_register_file;
    reg clk=0, reset=0, reg_write=0;
    reg [4:0] read_reg1=0, read_reg2=0, write_reg=0;
    reg [31:0] write_data=0;
    wire [31:0] read_data1, read_data2;
    integer checks=0, i;
    register_file dut(clk, reset, reg_write, read_reg1, read_reg2,
                      write_reg, write_data, read_data1, read_data2);
    task check(input bit condition, input string label);
        begin
            checks=checks+1;
            if (!condition) $fatal(1, "FAIL: %s read1=%08h read2=%08h",
                                   label, read_data1, read_data2);
        end
    endtask
    task tick;
        begin #4; clk=1; #1; clk=0; #5; end
    endtask
    initial begin
        if ($test$plusargs("wave")) begin
            $dumpfile("build/tb_register_file.vcd"); $dumpvars(0,tb_register_file);
        end
        #1; check(read_data1===0 && read_data2===0, "x0 reads zero before reset");
        reset=1; reg_write=1; write_reg=5; write_data=32'hdeadbeef; tick();
        reset=0; reg_write=0;
        for(i=0;i<32;i=i+1) begin
            read_reg1=i; read_reg2=31-i; #1;
            check(read_data1===0 && read_data2===0, "reset clears both read ports");
        end
        for(i=1;i<32;i=i+1) begin
            reg_write=1; write_reg=i; write_data=32'ha0000000+i; tick();
        end
        reg_write=0;
        for(i=1;i<32;i=i+1) begin
            read_reg1=i; read_reg2=32-i; #1;
            check(read_data1===(32'ha0000000+i) &&
                  read_data2===(32'ha0000000+32-i), "both ports read all written registers");
        end
        reg_write=1; write_reg=0; write_data=32'hffffffff; tick();
        read_reg1=0; read_reg2=0; #1;
        check(read_data1===0 && read_data2===0, "x0 discards writes");
        reg_write=0; write_reg=7; write_data=32'hdeadbeef; tick();
        read_reg1=7; #1; check(read_data1===32'ha0000007, "disabled write preserves state");
        read_reg1=3; #1; read_reg1=11; #1;
        check(read_data1===32'ha000000b, "asynchronous read follows address without clock");
        read_reg1=6; read_reg2=6; #1;
        reg_write=1; write_reg=6; write_data=read_data1+32'd7; #1;
        check(read_data1===32'ha0000006, "same-register update reads old value before edge");
        tick(); check(read_data1===32'ha000000d && read_data2===32'ha000000d,
                      "both ports see new value after write edge");
        reset=1; write_data=32'hbad0bad0; #1;
        check(read_data1===32'ha000000d, "reset does not clear registers between edges");
        tick(); reset=0; reg_write=0;
        for(i=0;i<32;i=i+1) begin
            read_reg1=i; read_reg2=31-i; #1;
            check(read_data1===0 && read_data2===0, "reset overrides simultaneous write");
        end
        reg_write=1; write_reg=31; write_data=42; tick();
        reg_write=0; read_reg1=31; #1;
        check(read_data1===42, "normal operation resumes after reset");
        $display("PASS: tb_register_file checks=%0d",checks); $finish;
    end
    initial begin #10000; $fatal(1,"FAIL: register file test timeout"); end
endmodule
