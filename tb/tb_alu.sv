`timescale 1ns/1ps
module tb_alu;
    reg [31:0] a,b;
    reg [2:0] operation;
    wire [31:0] result;
    wire zero;
    reg [31:0] values[0:9],expected;
    integer checks=0,i,j,k;
    alu dut(a,b,operation,result,zero);
    initial begin
        if($test$plusargs("wave")) begin
            $dumpfile("build/tb_alu.vcd"); $dumpvars(0,tb_alu);
        end
        values[0]=0;values[1]=1;values[2]=2;values[3]=32'h7fffffff;
        values[4]=32'h80000000;values[5]=32'hffffffff;values[6]=32'haaaaaaaa;
        values[7]=32'h55555555;values[8]=32'h12345678;values[9]=32'hdeadbeef;
        for(k=0;k<5;k=k+1)
          for(i=0;i<10;i=i+1)
            for(j=0;j<10;j=j+1) begin
                a=values[i];b=values[j];operation=k;
                case(k)
                    0:expected=a+b;1:expected=a-b;2:expected=a&b;
                    3:expected=a|b;4:expected=a^b;
                endcase
                #1;checks=checks+1;
                if(result!==expected || zero!==(expected==0))
                    $fatal(1,"FAIL: ALU op=%d a=%h b=%h",k,a,b);
            end
        for(k=5;k<8;k=k+1) begin
            operation=k;#1;checks=checks+1;
            if(result!==0 || zero!==1) $fatal(1,"FAIL: invalid ALU operation");
        end
        $display("PASS: tb_alu checks=%0d",checks);$finish;
    end
    initial begin #2000;$fatal(1,"FAIL: ALU timeout");end
endmodule
