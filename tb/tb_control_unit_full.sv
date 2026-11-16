`timescale 1ns/1ps
module tb_control_unit_full;
    reg [31:0] instruction=0;
    wire v,w,s,mr,mw,sm;wire [2:0] o;wire [1:0] im,br;
    integer op,f3,f7,eo,ei,eb,checks=0;
    reg ev,ew,es,er,em,et;
    control_unit dut(.instruction(instruction),.instruction_valid(v),.reg_write(w),
        .alu_src_immediate(s),.alu_operation(o),.imm_select(im),.mem_read(mr),
        .mem_write(mw),.select_memory(sm),.branch_mode(br));
    initial begin
        for(op=0;op<128;op=op+1)for(f3=0;f3<8;f3=f3+1)for(f7=0;f7<128;f7=f7+1)begin
            instruction=(f7<<25)|(17<<20)|(9<<15)|(f3<<12)|(5<<7)|op;
            ev=0;ew=0;es=0;eo=0;ei=0;er=0;em=0;et=0;eb=0;
            if(op==51 && f7==0)case(f3)
                0:begin ev=1;eo=0;end
                7:begin ev=1;eo=2;end
                6:begin ev=1;eo=3;end
                4:begin ev=1;eo=4;end
            endcase
            if(op==51 && f7==32 && f3==0)begin ev=1;eo=1;end
            if(op==51)ew=ev;
            if(op==19 && f3==0)begin ev=1;ew=1;es=1;end
            if(op==3 && f3==2)begin ev=1;ew=1;es=1;er=1;et=1;end
            if(op==35 && f3==2)begin ev=1;es=1;ei=1;em=1;end
            if(op==99 && (f3==0 || f3==1))begin ev=1;ei=2;eb=f3+1;eo=1;end
            #1;checks=checks+1;
            if({v,w,s,o,im,mr,mw,sm,br}!=={ev,ew,es,eo[2:0],ei[1:0],er,em,et,eb[1:0]})
                $fatal(1,"FAIL: full decoder word=%h",instruction);
        end
        $display("PASS: tb_control_unit_full checks=%0d",checks);$finish;
    end
    initial begin #140000;$fatal(1,"FAIL: full decoder timeout");end
endmodule
