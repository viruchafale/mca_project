#!/usr/bin/env python3
"""Restricted fixture encoder and independent architectural reference for phase-4.
--write-fixtures regenerates tracked inputs; normal mode only writes build outputs.
"""
import json
from pathlib import Path
import re
import sys
ROOT=Path(__file__).resolve().parents[1]
MASK=0xffffffff
PROGRAM="""addi x1,x0,64
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
"""
def encode(name,d=0,a=0,b=0,v=0):
    if name in ["add","sub","and","or","xor"]:
        f={"add":0,"sub":0,"and":7,"or":6,"xor":4}[name]
        return ((32 if name=="sub" else 0)<<25)|(b<<20)|(a<<15)|(f<<12)|(d<<7)|0x33
    if name in ["addi","lw"]:
        assert -2048<=v<=2047
        return ((v&4095)<<20)|(a<<15)|((2 if name=="lw" else 0)<<12)|(d<<7)|(3 if name=="lw" else 0x13)
    if name=="sw":
        assert -2048<=v<=2047
        return (((v&4095)>>5)<<25)|(b<<20)|(a<<15)|(2<<12)|((v&31)<<7)|0x23
    if name in ["beq","bne"]:
        assert -4096<=v<=4094 and v%2==0
        t=v&8191
        return ((t>>12)<<31)|(((t>>5)&63)<<25)|(b<<20)|(a<<15)|((name=="bne")<<12)|(((t>>1)&15)<<8)|(((t>>11)&1)<<7)|0x63
    raise ValueError(name)
def assemble(text):
    labels={};lines=[]
    for raw in text.splitlines():
        line=raw.split("#")[0].strip()
        if not line:continue
        if ":" in line:
            label,line=line.split(":",1);labels[label.strip()]=len(lines)*4;line=line.strip()
        if line:lines.append(line)
    words=[]
    for i,line in enumerate(lines):
        name,rest=line.split(None,1);parts=[p.strip() for p in rest.split(",")]
        reg=lambda s:int(s[1:]) if re.fullmatch(r"x(?:[0-9]|[12][0-9]|3[01])",s) else (_ for _ in ()).throw(ValueError(s))
        if name in ["add","sub","and","or","xor"]:
            words.append(encode(name,d=reg(parts[0]),a=reg(parts[1]),b=reg(parts[2])))
        elif name=="addi":
            words.append(encode(name,d=reg(parts[0]),a=reg(parts[1]),v=int(parts[2],0)))
        elif name in ["lw","sw"]:
            m=re.fullmatch(r"(-?[0-9]+)\((x[0-9]+)\)",parts[1]);assert m
            args={"a":reg(m[2]),"v":int(m[1])};args["d" if name=="lw" else "b"]=reg(parts[0])
            words.append(encode(name,**args))
        else:
            off=labels[parts[2]]-i*4 if parts[2] in labels else int(parts[2],0)
            words.append(encode(name,a=reg(parts[0]),b=reg(parts[1]),v=off))
    return words,labels
def write_image(name,words):
    assert len(words)<=256
    (ROOT/"programs"/name).write_text("".join(f"{w:08x}\n" for w in words+[0x13]*(256-len(words))))
def fixtures():
    # Independent literal checks catch encoder field mistakes.
    assert encode("addi",d=17,a=18,v=-1)==0xfff90893
    assert encode("sw",b=21,a=22,v=12)==0x015b2623
    assert encode("bne",a=25,b=26,v=-4)==0xffac9ee3
    words,labels=assemble(PROGRAM)
    (ROOT/"programs/full_isa.S").write_text("# Ten-instruction integration fixture. Ends in BEQ self-loop, not HALT.\n"+PROGRAM)
    write_image("full_isa.hex",words)
    expected={"registers":{str(i):v for i,v in {1:64,2:7,3:7,4:1,5:0,6:6,7:6,8:MASK,9:MASK,10:1020,11:6,12:7,13:1,14:6,15:7,16:1}.items()},
              "memory":{"0":7,"60":6,"64":7,"68":MASK,"72":0,"1020":6},"completion_pc":labels["done"]}
    (ROOT/"programs/full_isa.expected.json").write_text(json.dumps(expected,indent=2)+"\n")
    words=[0x13]*256
    for n in range(8):
        i=n*16;seq=[encode("addi",d=1,v=1),encode("sw",b=1)]
        if n==0:seq += [encode("sw",b=0,v=2)]
        if n==1:seq += [encode("addi",d=5,v=55),encode("lw",d=5,v=2)]
        if n==2:seq += [encode("addi",d=2,v=1024),encode("sw",a=2,b=0)]
        if n==3:seq += [encode("addi",d=2,v=1024),encode("lw",d=0,a=2)]
        if n==4:seq += [encode("beq",v=2)]
        if n==5:seq += [encode("bne",a=1,v=2)]
        if n==6:seq += [encode("beq",a=1,v=2),encode("addi",d=4,v=42),
                       encode("bne",v=2),encode("addi",d=5,v=43),0]
        if n==7:seq += [encode("beq",v=1024-(n*64+8))]
        seq += [encode("addi",d=31,v=99)]
        words[i:i+len(seq)]=seq
    write_image("phase4_faults.hex",words)
    write_image("reset_memory.hex",[encode("addi",d=1,v=11),encode("sw",b=1),
        encode("addi",d=1,v=22),encode("sw",b=1),encode("beq",v=0)])
def signed(v,bits):
    return v-(1<<bits) if v&(1<<(bits-1)) else v
def reference():
    words=[int(x,16) for x in (ROOT/"programs/full_isa.hex").read_text().split()]
    want=json.loads((ROOT/"programs/full_isa.expected.json").read_text())
    regs=[0]*32;ram={};pc=0;trace=[];coverage=set();ops=set()
    for _ in range(1000):
        assert 0<=pc<=1020 and pc%4==0
        word=words[pc//4];op=word&127;rd=(word>>7)&31;f3=(word>>12)&7
        a=regs[(word>>15)&31];b=regs[(word>>20)&31];f7=word>>25
        npc=(pc+4)&MASK;wr=0;value=0;mr=0;mw=0;addr=0;store=b;taken=0
        if op==0x33:
            name={(0,0):"ADD",(0,32):"SUB",(7,0):"AND",(6,0):"OR",(4,0):"XOR"}[(f3,f7)]
            value={"ADD":a+b,"SUB":a-b,"AND":a&b,"OR":a|b,"XOR":a^b}[name]&MASK;wr=int(rd!=0)
        elif op==0x13 and f3==0:
            name="ADDI";value=(a+signed(word>>20,12))&MASK;wr=int(rd!=0)
        elif op in [3,0x23] and f3==2:
            imm=(word>>20) if op==3 else ((word>>25)<<5)|((word>>7)&31)
            addr=(a+signed(imm,12))&MASK;assert addr<=1020 and addr%4==0
            if op==3:
                name="LW";mr=1;value=ram[addr];wr=int(rd!=0)
            else:
                name="SW";mw=1;ram[addr]=b
        elif op==0x63 and f3 in [0,1]:
            name="BEQ" if f3==0 else "BNE"
            off=((word>>31)<<12)|(((word>>7)&1)<<11)|(((word>>25)&63)<<5)|(((word>>8)&15)<<1)
            taken=int((a==b) if f3==0 else (a!=b));coverage.add((name,taken))
            if taken:npc=(pc+signed(off,13))&MASK
            assert npc%4==0
        else:raise ValueError(f"Unsupported reference word {word:08x}")
        trace.append([pc,word,wr,rd,value,mr,mw,addr,store,npc,taken]);ops.add(name)
        if wr:regs[rd]=value
        regs[0]=0
        if pc==want["completion_pc"]:
            assert name=="BEQ" and taken and npc==pc
            break
        pc=npc
    else:raise RuntimeError("Reference exceeded instruction bound")
    expected=[int(want["registers"].get(str(i),0)) for i in range(32)]
    assert regs==expected,(regs,expected)
    assert ram=={int(k):v for k,v in want["memory"].items()},ram
    assert coverage=={("BEQ",0),("BEQ",1),("BNE",0),("BNE",1)}
    assert len(ops)==10
    build=ROOT/"build";build.mkdir(exist_ok=True)
    (build/"full_isa.trace").write_text("".join(" ".join(f"{v:08x}" for v in row)+"\n" for row in trace))
    (build/"full_isa_registers.hex").write_text("".join(f"{v:08x}\n" for v in expected))
    (build/"phase4_reference.json").write_text(json.dumps({"status":"pass","executed_instructions":len(trace),
        "operations":sorted(ops),"branch_outcomes":sorted(list(coverage)),"registers":regs,"memory":ram},indent=2)+"\n")
    print(f"PASS: reference instructions={len(trace)} all_ten=1 branch_outcomes=4")
if __name__=="__main__":
    if "--write-fixtures" in sys.argv:fixtures()
    else:reference()
