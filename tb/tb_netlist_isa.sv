`timescale 1ns/1ps
module tb_netlist_isa;
    reg clk=0,reset=1;
    wire [31:0] pc,insn,wd,addr,store,load,npc;
    wire wr,fault,mr,mw,taken,execute;wire [4:0] rd;wire [1:0] cause;
    reg [31:0] ep,ei,ew,ed,ev,er,em,ea,es,en,eb;
    integer fd,rc,checks=0,steps=0,i;
    rv32i_cpu dut(.clk(clk),.reset(reset),.debug_pc(pc),.debug_instruction(insn),
        .debug_reg_write(wr),.debug_rd(rd),.debug_write_data(wd),.fault(fault),
        .fault_cause(cause),.debug_mem_read(mr),.debug_mem_write(mw),
        .debug_mem_address(addr),.debug_mem_write_data(store),.debug_mem_read_data(load),
        .debug_branch_taken(taken),.debug_next_pc(npc),.debug_execute(execute));
    task check(input bit condition,input string label);
        begin checks=checks+1;if(!condition)$fatal(1,"FAIL: %s step=%0d pc=%h insn=%h",label,steps,pc,insn);end
    endtask
    task tick;begin #4;clk=1;#1;clk=0;#5;end endtask
    initial begin
        if($test$plusargs("wave"))begin $dumpfile("build/tb_netlist_isa.vcd");$dumpvars(0,tb_netlist_isa);end
        fd=$fopen("build/full_isa.trace","r");if(!fd)$fatal(1,"FAIL: missing independent reference trace");
        tick();check(pc===0 && fault===0 && wr===0 && mw===0,"reset");reset=0;#1;
        while(!$feof(fd))begin
            rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h %h %h\n",ep,ei,ew,ed,ev,er,em,ea,es,en,eb);
            if(rc==11)begin
                steps=steps+1;
                check(pc===ep && insn===ei && fault===0 && execute===1,"reference PC/instruction/execute");
                check(wr===ew[0] && mr===er[0] && mw===em[0],"write/read permissions");
                if(ew)check(rd===ed[4:0] && wd===ev,"architectural writeback");
                if(er || em)check(addr===ea,"effective data address");
                if(er)check(load===ev,"loaded data, including rd=x0");
                if(em)check(store===es,"store value");
                check(npc===en && taken===eb[0],"branch decision and next PC");
                tick();
            end else if(rc!=-1)$fatal(1,"FAIL: malformed trace record");
        end
        $fclose(fd);check(steps==38,"bounded complete reference program");
        repeat(3)tick();check(fault===0 && npc===pc && taken===1,"valid terminal self-loop");
        $display("PASS: tb_netlist_isa checks=%0d",checks);$finish;
    end
    initial begin #10000;$fatal(1,"FAIL: full ISA timeout");end
endmodule
