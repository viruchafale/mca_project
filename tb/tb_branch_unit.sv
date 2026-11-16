`timescale 1ns/1ps
module tb_branch_unit;
    reg [31:0] pc,immediate,operand1,operand2;
    reg [1:0] mode;wire taken,aligned;wire [31:0] next_pc;
    integer m,j,k,checks=0;reg et;reg [31:0] target,expected;
    reg [31:0] offsets[0:5];
    branch_unit dut(pc,immediate,operand1,operand2,mode,taken,aligned,next_pc);
    initial begin
        if($test$plusargs("wave"))begin $dumpfile("build/tb_branch_unit.vcd");$dumpvars(0,tb_branch_unit);end
        offsets[0]=8;offsets[1]=-32'd4;offsets[2]=2;offsets[3]=-32'd4096;
        offsets[4]=4094;offsets[5]=0;
        for(m=0;m<4;m=m+1)for(j=0;j<6;j=j+1)for(k=0;k<4;k=k+1)begin
            pc=32'h40;immediate=offsets[j];mode=m;
            case(k)
                0:begin operand1=0;operand2=0;end
                1:begin operand1=0;operand2=1;end
                2:begin operand1=32'hffffffff;operand2=32'hffffffff;end
                3:begin operand1=32'h80000000;operand2=0;end
            endcase
            et=(m==1 && operand1==operand2)||(m==2 && operand1!=operand2);
            target=pc+immediate;expected=et?target:pc+4;
            #1;checks=checks+1;
            if(taken!==et || next_pc!==expected || aligned!==(target[1:0]==0))
                $fatal(1,"FAIL: branch mode=%d offset=%h",m,immediate);
        end
        pc=32'hfffffffc;immediate=4;mode=1;operand1=0;operand2=0;#1;checks=checks+1;
        if(next_pc!==0 || taken!==1 || aligned!==1)$fatal(1,"FAIL: wrapped branch target");
        $display("PASS: tb_branch_unit checks=%0d",checks);$finish;
    end
    initial begin #1000;$fatal(1,"FAIL: branch timeout");end
endmodule
