`timescale 1ns/1ps
module tb_cpu_reset_memory;
    reg clk=0,reset=1;wire [31:0] pc;wire wr,mw,fault;
    integer checks=0;
    rv32i_cpu #(.INIT_FILE("programs/reset_memory.hex")) dut(
        .clk(clk),.reset(reset),.debug_pc(pc),.debug_instruction(),.debug_reg_write(wr),
        .debug_rd(),.debug_write_data(),.fault(fault),.fault_cause(),.debug_mem_write(mw));
    task check(input bit c,input string label);
        begin checks=checks+1;if(!c)$fatal(1,"FAIL: %s pc=%h",label,pc);end
    endtask
    task tick;begin #4;clk=1;#1;clk=0;#5;end endtask
    initial begin
        if($test$plusargs("wave"))begin $dumpfile("build/tb_cpu_reset_memory.vcd");$dumpvars(0,tb_cpu_reset_memory);end
        tick();check(pc===0 && wr===0 && mw===0,"reset suppresses writes");
        reset=0;tick();tick();check(dut.u_dmem.words[0]===11,"initialized by public SW");
        tick();check(pc===12 && mw===1 && dut.u_dmem.words[0]===11,"overwrite pending");
        reset=1;#1;check(mw===0 && wr===0,"reset pre-edge suppression");
        tick();check(pc===0 && dut.u_dmem.words[0]===11 &&
                      dut.u_register_file.registers[1]===0,"pending store cancelled and RAM retained");
        reset=0;repeat(4)tick();
        check(pc===16 && dut.u_dmem.words[0]===22 && fault===0,"normal store after reset");
        repeat(2)tick();check(pc===16 && fault===0,"self-loop is not a fault");
        $display("PASS: tb_cpu_reset_memory checks=%0d",checks);$finish;
    end
    initial begin #1000;$fatal(1,"FAIL: reset-memory timeout");end
endmodule
