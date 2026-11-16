`timescale 1ns/1ps
module tb_immediate_generator;
    reg [31:0] instruction=0;
    reg [1:0] imm_select=0;
    wire [31:0] immediate;
    wire format_valid;
    integer checks=0, value;
    reg [12:0] bits13;
    reg [11:0] bits12;
    immediate_generator dut(instruction,imm_select,immediate,format_valid);
    task expect_imm(input [31:0] word, input [1:0] kind,
                    input [31:0] expected, input bit expected_valid);
        begin
            instruction=word; imm_select=kind; #1; checks=checks+1;
            if (immediate!==expected || format_valid!==expected_valid)
                $fatal(1,"FAIL: word=%08h select=%b got=%08h valid=%b expected=%08h",
                       word,kind,immediate,format_valid,expected);
        end
    endtask
    initial begin
        if ($test$plusargs("wave")) begin
            $dumpfile("build/tb_immediate_generator.vcd");
            $dumpvars(0,tb_immediate_generator);
        end
        // Literal machine words checked independently of the exhaustive packers.
        expect_imm(32'hfff90893,2'b00,-32'd1,1);   // addi x17,x18,-1
        expect_imm(32'hff0a2983,2'b00,-32'd16,1);  // lw x19,-16(x20)
        expect_imm(32'h015b2623,2'b01,32'd12,1);   // sw x21,12(x22)
        expect_imm(32'h018b8463,2'b10,32'd8,1);    // beq x23,x24,+8
        expect_imm(32'hffac9ee3,2'b10,-32'd4,1);   // bne x25,x26,-4
        // Every 12-bit signed immediate; other instruction fields are nonzero.
        for(value=-2048;value<=2047;value=value+1) begin
            bits12=value;
            expect_imm({bits12,20'hf8913},2'b00,value,1);
            expect_imm({bits12[11:5],5'd21,5'd22,3'b010,bits12[4:0],7'b0100011},
                       2'b01,value,1);
        end
        // Every representable signed B offset, including its implicit low zero.
        for(value=-4096;value<=4094;value=value+2) begin
            bits13=value;
            expect_imm({bits13[12],bits13[10:5],5'd26,5'd25,3'b001,
                        bits13[4:1],bits13[11],7'b1100011},2'b10,value,1);
        end
        expect_imm(32'hffffffff,2'b11,0,0);
        $display("PASS: tb_immediate_generator checks=%0d",checks); $finish;
    end
    initial begin #20000; $fatal(1,"FAIL: immediate generator test timeout"); end
endmodule
