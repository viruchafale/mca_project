# Ten-instruction integration fixture. Ends in BEQ self-loop, not HALT.
addi x1,x0,64
addi x2,x0,7
sw x2,0(x1)
lw x3,0(x1)
beq x2,x3,equal
addi x4,x0,99
equal: addi x4,x0,1
bne x2,x3,poison
addi x5,x0,3
addi x6,x0,0
loop: add x6,x6,x5
addi x5,x5,-1
bne x5,x0,loop
sw x6,-4(x1)
lw x7,-4(x1)
bne x7,x2,different
addi x8,x0,99
different: beq x7,x2,poison
addi x8,x0,-1
sw x8,4(x1)
lw x9,4(x1)
addi x10,x0,1020
sw x7,0(x10)
lw x11,0(x10)
sw x2,0(x0)
lw x12,0(x0)
sw x0,8(x1)
lw x0,8(x1)
sub x13,x3,x7
and x14,x3,x7
or x15,x3,x7
xor x16,x3,x7
beq x0,x0,done
poison: addi x30,x0,99
done: beq x0,x0,done
