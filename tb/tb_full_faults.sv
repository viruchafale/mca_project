`timescale 1ns/1ps
module tb_full_faults;
    reg clk=0,reset=1;always #5 clk=~clk;
    integer counts[0:7];integer i,total;
    genvar n;
    generate for(n=0;n<8;n=n+1)begin: scenarios
        localparam [31:0] START=n*64;
        localparam [31:0] BAD_PC=(n==7)?32'h400:START+((n==1 || n==2 || n==3)?12:(n==6)?24:8);
        wire [31:0] pc;wire fault,wr,mr,mw,execute;wire [1:0] cause;
        rv32i_cpu #(.INIT_FILE("programs/phase4_faults.hex"),.RESET_PC(START)) dut(
            .clk(clk),.reset(reset),.debug_pc(pc),.debug_instruction(),.debug_reg_write(wr),
            .debug_rd(),.debug_write_data(),.fault(fault),.fault_cause(cause),
            .debug_mem_read(mr),.debug_mem_write(mw),.debug_execute(execute));
        task check(input bit c,input string label);
            begin counts[n]=counts[n]+1;if(!c)$fatal(1,"FAIL: full fault %0d %s pc=%h",n,label,pc);end
        endtask
        always @(negedge clk)begin
            if(!reset && !fault && pc===BAD_PC)
                check(wr===0 && mr===0 && mw===0 && execute===0,
                      "faulting instruction suppressed before fault edge");
        end
        initial begin
            counts[n]=0;#6;check(pc===START && fault===0,"reset");
            #110;check(fault===1 && cause===((n==7)?1:(n==6)?2:3) && pc===BAD_PC,"fault address and cause");
            check(wr===0 && mr===0 && mw===0 && execute===0,"fault suppresses side effects");
            check(dut.u_dmem.words[0]===1,"invalid access cannot alias or overwrite RAM");
            check(dut.u_register_file.registers[31]===0,"following instruction skipped");
            if(n==6)check(dut.u_register_file.registers[4]===42 &&
                          dut.u_register_file.registers[5]===43,"untaken misaligned branches do not fault");
            else check(dut.u_register_file.registers[5]===((n==1)?55:0),"faulting load preserves previous destination");
            #20;check(pc===BAD_PC && fault===1 && mw===0,"sticky hold");
            #10;check(pc===START && fault===0 && cause===0 && dut.u_dmem.words[0]===1,
                      "reset recovers CPU and preserves initialized RAM");
        end
    end endgenerate
    initial begin
        if($test$plusargs("wave"))begin $dumpfile("build/tb_full_faults.vcd");$dumpvars(0,tb_full_faults);end
        #10;reset=0;#130;reset=1;#10;
        total=0;for(i=0;i<8;i=i+1)total=total+counts[i];
        $display("PASS: tb_full_faults checks=%0d",total);$finish;
    end
    initial begin #1000;$fatal(1,"FAIL: full faults timeout");end
endmodule
