#!/usr/bin/env python3
"""Run checked generic Yosys synthesis; all generated outputs remain in build/."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from datetime import datetime, timezone
ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
out = ROOT / 'build/synthesis'
out.mkdir(parents=True, exist_ok=True)
exe = shutil.which(os.environ.get('YOSYS', 'yosys'))
manifest = {'status': 'fail', 'started_utc': datetime.now(timezone.utc).isoformat(),
    'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
    'working_tree_dirty': bool(subprocess.check_output(['git', 'status', '--porcelain'])),
    'target': 'generic cells; default full-subset CPU and full_isa ROM',
    'input_sha256': {str(p): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in sorted([*Path('rtl').glob('*.v'), Path('programs/full_isa.hex'),
                         Path('synth/generic.ys'), Path(__file__).relative_to(ROOT)])}}
try:
    words = Path('programs/full_isa.hex').read_text().split()
    if len(words) != 256 or any(len(w) != 8 or not all(c in '0123456789abcdefABCDEF' for c in w) for w in words):
        raise RuntimeError('Synthesis ROM must contain exactly 256 eight-digit hex words')
    if not exe:
        raise RuntimeError('Yosys unavailable: install yosys or set YOSYS to yowasp-yosys')
    manifest['version'] = subprocess.check_output([exe, '-V'], text=True, timeout=300).strip()
    with (out / 'synthesis.log').open('w') as log:
        result = subprocess.run([exe, '-s', 'synth/generic.ys'], stdout=log,
                                stderr=subprocess.STDOUT, timeout=300)
    if result.returncode:
        raise RuntimeError('Yosys failed; inspect build/synthesis/synthesis.log')
    stats = json.loads((out / 'stat.json').read_text())
    manifest['statistics'] = stats
    for name, module in stats.get('modules', {}).items():
        bad = [c for c in module.get('num_cells_by_type', {}) if 'LATCH' in c.upper()]
        if bad:
            raise RuntimeError('Unexpected inferred latch in ' + name)
    manifest['status'] = 'pass'
    manifest['output_sha256'] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
        for p in out.iterdir() if p.name in ['synthesis.log','stat.json','netlist.json','netlist.v']}
except (OSError, RuntimeError, subprocess.SubprocessError, ValueError) as exc:
    manifest['error'] = str(exc)
finally:
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
if manifest['status'] != 'pass':
    print('FAIL: ' + manifest['error'], file=sys.stderr)
    sys.exit(1)
print('PASS: generic synthesis and structural check; no inferred latches')
print('No device mapping, timing, Fmax, power or FPGA deployment is claimed.')
