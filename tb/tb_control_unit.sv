`timescale 1ns/1ps
module tb_control_unit;
    reg [31:0] instruction=0;
    wire instruction_valid,reg_write,alu_src_immediate;
    wire [2:0] alu_operation;
    integer checks=0,op,f3,f7,expected_operation;
    reg expected_valid,expected_immediate;
    control_unit #(.ARITHMETIC_ONLY(1)) dut(.instruction(instruction),.instruction_valid(instruction_valid),.reg_write(reg_write),.alu_src_immediate(alu_src_immediate),.alu_operation(alu_operation));
    initial begin
        // Exhaustive opcode/funct3/funct7 classes. Register fields stay nonzero.
        // Omit enormous decoder VCD; the CPU waveform supplies integration evidence.
        for(op=0;op<128;op=op+1)
          for(f3=0;f3<8;f3=f3+1)
            for(f7=0;f7<128;f7=f7+1) begin
                instruction=(f7<<25)|(17<<20)|(9<<15)|(f3<<12)|(5<<7)|op;
                expected_valid=0;expected_immediate=0;expected_operation=0;
                if(op==51 && f7==0) begin
                    case(f3)
                        0:begin expected_valid=1;expected_operation=0;end
                        7:begin expected_valid=1;expected_operation=2;end
                        6:begin expected_valid=1;expected_operation=3;end
                        4:begin expected_valid=1;expected_operation=4;end
                    endcase
                end
                if(op==51 && f7==32 && f3==0) begin
                    expected_valid=1;expected_operation=1;
                end
                if(op==19 && f3==0) begin
                    expected_valid=1;expected_immediate=1;
                end
                #1;checks=checks+1;
                if(instruction_valid!==expected_valid || reg_write!==expected_valid ||
                   alu_src_immediate!==expected_immediate ||
                   alu_operation!==expected_operation[2:0])
                    $fatal(1,"FAIL: decode word=%08h",instruction);
            end
        $display("PASS: tb_control_unit checks=%0d",checks);$finish;
    end
    initial begin #140000;$fatal(1,"FAIL: decoder timeout");end
endmodule
