# RV32I fetch fixture: phase-1 checks these encodings and fetch order only.
# The processor does not execute instructions in this phase.
# Byte address  Instruction                 Hexadecimal word
# 0x00          addi x1, x0, 5              00500093
# 0x04          addi x2, x0, 10             00a00113
# 0x08          add  x3, x1, x2             002081b3
# 0x0c          sw   x3, 0(x0)              00302023
# 0x10          lw   x4, 0(x0)              00002203
# 0x14          beq  x3, x4, done           00418463
# 0x18          add  x5, x1, x2             002082b3
# 0x1c  done:   beq  x0, x0, done          00000063
.text
addi x1, x0, 5
addi x2, x0, 10
add x3, x1, x2
sw x3, 0(x0)
lw x4, 0(x0)
beq x3, x4, done
add x5, x1, x2
done:
beq x0, x0, done
# fetch_smoke.hex pads the remaining 248 ROM words with 00000013 (NOP).
