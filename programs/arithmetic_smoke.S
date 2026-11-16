# Phase-3 six-instruction arithmetic program. No branches or memory accesses.
# Final zero word is an intentionally illegal diagnostic sentinel, not HALT.
.text
addi x1,x0,5             # 000: 00500093
addi x2,x0,10            # 004: 00a00113
add x3,x1,x2             # 008: 002081b3
sub x4,x1,x2             # 00c: 40208233
and x5,x1,x2             # 010: 0020f2b3
or x6,x1,x2              # 014: 0020e333
xor x7,x1,x2             # 018: 0020c3b3
addi x8,x4,-3            # 01c: ffd20413
addi x0,x0,123           # 020: 07b00013
addi x1,x1,-1            # 024: fff08093
add x9,x1,x2             # 028: 002084b3
addi x10,x0,-1           # 02c: fff00513
add x11,x10,x2           # 030: 002505b3
sub x12,x0,x10           # 034: 40a00633
and x13,x10,x2           # 038: 002576b3
or x14,x10,x2            # 03c: 00256733
xor x15,x10,x2           # 040: 002547b3
.word 0
