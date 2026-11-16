`timescale 1ns/1ps
module tb_rv32i_cpu;
    reg clk=0,reset=1;
    wire [31:0] pc,instruction,write_data;
    wire wr,fault;
    wire [4:0] rd;
    wire [1:0] cause;
    integer checks=0,i;
    integer destinations[0:16];
    reg [31:0] results[0:16],final_values[0:31];
    rv32i_cpu dut(.clk(clk),.reset(reset),.debug_pc(pc),.debug_instruction(instruction),
        .debug_reg_write(wr),.debug_rd(rd),.debug_write_data(write_data),
        .fault(fault),.fault_cause(cause));
    task check(input bit condition,input string label);
        begin checks=checks+1;if(!condition)$fatal(1,"FAIL: %s pc=%h instruction=%h",label,pc,instruction);end
    endtask
    task tick;
        begin #4;clk=1;#1;clk=0;#5;end
    endtask
    initial begin
        if($test$plusargs("wave"))begin
            $dumpfile("build/tb_rv32i_cpu.vcd");$dumpvars(0,tb_rv32i_cpu);
        end
        destinations[0]=1;results[0]=5;destinations[1]=2;results[1]=10;
        destinations[2]=3;results[2]=15;destinations[3]=4;results[3]=-32'd5;
        destinations[4]=5;results[4]=0;destinations[5]=6;results[5]=15;
        destinations[6]=7;results[6]=15;destinations[7]=8;results[7]=-32'd8;
        destinations[8]=0;results[8]=123;destinations[9]=1;results[9]=4;
        destinations[10]=9;results[10]=14;destinations[11]=10;results[11]=32'hffffffff;
        destinations[12]=11;results[12]=9;destinations[13]=12;results[13]=1;
        destinations[14]=13;results[14]=10;destinations[15]=14;results[15]=32'hffffffff;
        destinations[16]=15;results[16]=32'hfffffff5;
        for(i=0;i<32;i=i+1)final_values[i]=0;
        tick();check(pc===0 && fault===0 && cause===0 && wr===0,"public reset initializes CPU");
        reset=0;#1;
        for(i=0;i<17;i=i+1)begin
            check(pc===(i*4) && fault===0 && rd===destinations[i][4:0] &&
                  write_data===results[i] && wr===(destinations[i]!=0),
                  "instruction trace matches hand-calculated expectation");
            tick();
            if(destinations[i]!=0)final_values[destinations[i]]=results[i];
            // Observation only. No DUT register or RAM hierarchy is written.
            check(dut.u_register_file.registers[destinations[i]]===
                  final_values[destinations[i]],"result stored at instruction boundary");
        end
        check(pc===68 && wr===0,"illegal sentinel cannot write before fault edge");
        tick();check(fault===1 && cause===2 && pc===68,"illegal sentinel holds PC");
        repeat(3)tick();
        check(pc===68 && wr===0 && fault===1,"sticky fault suppresses later writes");
        for(i=0;i<32;i=i+1)
            check(dut.u_register_file.registers[i]===final_values[i],"final architectural register state");
        reset=1;#1;check(wr===0 && fault===1,"reset suppresses writes before synchronous clear");
        tick();check(pc===0 && fault===0 && cause===0,"fault reset restarts CPU");
        for(i=0;i<32;i=i+1)
            check(dut.u_register_file.registers[i]===0,"public reset clears registers");
        $display("PASS: tb_rv32i_cpu checks=%0d",checks);$finish;
    end
    initial begin #2000;$fatal(1,"FAIL: CPU execution timeout");end
endmodule
