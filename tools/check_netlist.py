#!/usr/bin/env python3
"""Port-only architectural trace smoke test of the generated generic netlist."""
import json
import os
from pathlib import Path
import subprocess
import sys
import hashlib
ROOT=Path(__file__).resolve().parents[1]
os.chdir(ROOT)
out=Path('build/synthesis')
manifest={'status':'fail','scope':'38-instruction port-only netlist trace smoke test, not equivalence proof'}
try:
    for p in ['build/synthesis/netlist.v','build/full_isa.trace','tb/tb_netlist_isa.sv']:
        manifest.setdefault('input_sha256',{})[p]=hashlib.sha256(Path(p).read_bytes()).hexdigest()
    command=[os.environ.get('IVERILOG','iverilog')]
    if os.environ.get('IVL_BASE'):command+=['-B',os.environ['IVL_BASE']]
    command+=['-g2012','-s','tb_netlist_isa','-o',str(out/'netlist.vvp'),str(out/'netlist.v'),'tb/tb_netlist_isa.sv']
    with (out/'netlist-compile.log').open('w') as log:
        subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=120)
    r=subprocess.run([os.environ.get('VVP','vvp'),str(out/'netlist.vvp')],capture_output=True,text=True,timeout=60)
    (out/'netlist-simulation.log').write_text(r.stdout+r.stderr)
    if r.returncode or 'PASS: tb_netlist_isa checks=' not in r.stdout:
        raise RuntimeError('Netlist simulation failed; inspect its log')
    manifest['status']='pass';manifest['summary']=r.stdout.strip()
except (OSError,RuntimeError,subprocess.SubprocessError) as exc:
    manifest['error']=str(exc)
finally:
    out.mkdir(parents=True,exist_ok=True)
    (out/'netlist-check.json').write_text(json.dumps(manifest,indent=2)+'\n')
if manifest['status']!='pass':print(manifest['error'],file=sys.stderr);sys.exit(1)
print(manifest['summary'])
