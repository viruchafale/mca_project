`timescale 1ns/1ps
module tb_data_memory;
    reg clk=0, reset=0, mem_read=0, mem_write=0;
    reg [31:0] address=0, write_data=0;
    wire [31:0] read_data;
    wire address_valid;
    integer checks=0, i;
    reg [31:0] bad_addresses [0:8];
    data_memory dut(clk,reset,mem_read,mem_write,address,write_data,read_data,address_valid);
    task check(input bit condition, input string label);
        begin
            checks=checks+1;
            if (!condition) $fatal(1,"FAIL: %s addr=%08h data=%08h valid=%b",
                                   label,address,read_data,address_valid);
        end
    endtask
    task tick;
        begin #4; clk=1; #1; clk=0; #5; end
    endtask
    initial begin
        if ($test$plusargs("wave")) begin
            $dumpfile("build/tb_data_memory.vcd"); $dumpvars(0,tb_data_memory);
        end
        #1; check(read_data===0 && address_valid===1,
                  "disabled read returns zero even before RAM initialization");
        // Initialize all RAM through its public write port, not hierarchy/reset.
        for(i=0;i<256;i=i+1) begin
            address=i*4; write_data=32'h10000000+i; mem_write=1; tick();
        end
        mem_write=0; mem_read=1;
        for(i=0;i<256;i=i+1) begin
            address=i*4; #1;
            check(read_data===(32'h10000000+i) && address_valid===1,
                  "all aligned words read back through asynchronous port");
        end
        address=4; mem_write=1; write_data=32'hcafebabe; #1;
        check(read_data===32'h10000001,"simultaneous read/write shows old data before edge");
        tick(); check(read_data===32'hcafebabe,"new data visible after write edge");
        mem_write=0; write_data=32'hdeadbeef; tick();
        check(read_data===32'hcafebabe,"disabled store does not overwrite RAM");
        bad_addresses[0]=1; bad_addresses[1]=2; bad_addresses[2]=3;
        bad_addresses[3]=32'h3fd; bad_addresses[4]=32'h400;
        bad_addresses[5]=32'h404; bad_addresses[6]=32'hfffffffc;
        bad_addresses[7]=32'h80000000; bad_addresses[8]=32'h3ff;
        for(i=0;i<9;i=i+1) begin
            address=bad_addresses[i]; mem_write=1; write_data=32'hbad0bad0; tick();
            check(read_data===0 && address_valid===0,"invalid access is flagged and read returns zero");
        end
        mem_write=0;
        for(i=0;i<256;i=i+1) begin
            address=i*4; #1;
            if(i==1) check(read_data===32'hcafebabe,"invalid stores preserve overwritten word");
            else check(read_data===(32'h10000000+i),"invalid stores cannot alias any RAM word");
        end
        address=4; mem_read=0; #1;
        check(read_data===0 && address_valid===1,"read enable is independent of address validity");
        mem_read=1; reset=1; mem_write=1; write_data=32'hdeadbeef; #1;
        check(read_data===32'hcafebabe,"asserting reset preserves existing read data");
        tick(); check(read_data===32'hcafebabe,"reset suppresses a simultaneous write");
        reset=0; mem_write=0;
        for(i=0;i<256;i=i+1) begin
            address=i*4; #1;
            if(i==1) check(read_data===32'hcafebabe,"reset preserves overwritten word");
            else check(read_data===(32'h10000000+i),"reset preserves all initialized RAM words");
        end
        address=12; mem_write=1; write_data=123; tick(); mem_write=0; #1;
        check(read_data===123,"store/read works after reset");
        $display("PASS: tb_data_memory checks=%0d",checks); $finish;
    end
    initial begin #20000; $fatal(1,"FAIL: data memory test timeout"); end
endmodule
