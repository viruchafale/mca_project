`timescale 1ns/1ps
module tb_writeback_mux;
    reg select_memory=0;
    reg [31:0] alu_result=0,memory_data=0;
    wire [31:0] write_data;
    integer checks=0,i;
    writeback_mux dut(select_memory,alu_result,memory_data,write_data);
    initial begin
        for(i=0;i<10;i=i+1) begin
            alu_result=32'h80000000+i;memory_data=~alu_result;
            select_memory=0;#1;checks=checks+1;
            if(write_data!==alu_result)$fatal(1,"FAIL: ALU writeback");
            select_memory=1;#1;checks=checks+1;
            if(write_data!==memory_data)$fatal(1,"FAIL: memory writeback");
        end
        $display("PASS: tb_writeback_mux checks=%0d",checks);$finish;
    end
    initial begin #100;$fatal(1,"FAIL: writeback timeout");end
endmodule
