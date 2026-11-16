`timescale 1ns/1ps
module tb_cpu_faults;
    reg clk=0,reset=1;
    integer counts[0:9];
    integer i,total;
    always #5 clk=~clk;
    genvar n;
    generate for(n=0;n<10;n=n+1)begin: scenarios
        localparam [31:0] START = (n<7) ? n*4 :
                                       (n==7) ? 32'h400 : (n==8) ? 32'd2 : 32'h3fc;
        wire [31:0] pc,instruction,data;
        wire wr,fault;
        wire [1:0] cause;
        integer j;
        rv32i_cpu #(.INIT_FILE("programs/phase3_faults.hex"),.RESET_PC(START),.ARITHMETIC_ONLY(1)) dut(
            .clk(clk),.reset(reset),.debug_pc(pc),.debug_instruction(instruction),
            .debug_reg_write(wr),.debug_rd(),.debug_write_data(data),
            .fault(fault),.fault_cause(cause));
        task check(input bit condition,input string label);
            begin counts[n]=counts[n]+1;
                if(!condition)$fatal(1,"FAIL: fault scenario %0d %s pc=%h",n,label,pc);
            end
        endtask
        initial begin
            counts[n]=0;
            #6;check(pc===START && fault===0 && cause===0 && wr===0,"reset state");
            #10;
            if(n==9)
                check(pc===32'h400 && fault===0 &&
                      dut.u_register_file.registers[31]===9,"last valid ROM instruction executes");
            else
                check(pc===START && fault===1 && cause===((n<7)?2:1) && wr===0,
                      "unsupported instruction or invalid fetch cannot advance/write");
            #10;check(pc===((n==9)?32'h400:START) && fault===1 &&
                       cause===((n<7)?2:1) && wr===0,"correct sticky fault classification");
            for(j=0;j<32;j=j+1)
                check(dut.u_register_file.registers[j]===((n==9 && j==31)?9:0),
                      "faulting instruction has no register side effects");
            #30;check(pc===((n==9)?32'h400:START) && fault===1 && wr===0,"fault remains held");
            #10;check(pc===START && fault===0 && cause===0 &&
                       dut.u_register_file.registers[31]===0,"public reset recovers fault state");
        end
    end endgenerate
    initial begin
        if($test$plusargs("wave"))begin
            $dumpfile("build/tb_cpu_faults.vcd");$dumpvars(0,tb_cpu_faults);
        end
        #10;reset=0;#50;reset=1;#10;
        total=0;for(i=0;i<10;i=i+1)total=total+counts[i];
        $display("PASS: tb_cpu_faults checks=%0d",total);$finish;
    end
    initial begin #200;$fatal(1,"FAIL: fault test timeout");end
endmodule
