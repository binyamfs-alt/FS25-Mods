from pathlib import Path
import argparse, hashlib, io, json, subprocess, sys, zipfile
import xml.etree.ElementTree as E

root = Path(__file__).resolve().parent
target = root.parent / 'builds/FS25_z_ADParkingNodes.zip'
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true', help='Verify committed package without changing it')
args = parser.parse_args()
subprocess.run([sys.executable, str(root / 'test_parking_rows.py')], check=True)
version = E.parse(root / 'modDesc.xml').findtext('version')
status = json.loads((root / 'status.json').read_text())
assert status['version'] == version and status['runtime_verified']
buffer = io.BytesIO()
with zipfile.ZipFile(buffer, 'w', zipfile.ZIP_STORED) as z:
    for p in sorted(root.rglob('*'), key=lambda item: item.relative_to(root).as_posix()):
        if not p.is_file() or not (p.suffix in ['.lua', '.xml', '.dds', '.i3d', '.md'] or p.name == 'LICENSE'):
            continue
        name = p.relative_to(root).as_posix()
        data = p.read_bytes()
        if p.suffix != '.dds': data = data.replace(b'\r\n', b'\n')
        info = zipfile.ZipInfo(name, date_time=(2026, 10, 30, 0, 0, 0))
        info.create_system = 3
        info.compress_type = zipfile.ZIP_STORED
        info.external_attr = 0o644 << 16
        z.writestr(info, data)
package = buffer.getvalue()
with zipfile.ZipFile(io.BytesIO(package)) as z:
    assert z.testzip() is None
    for n in z.namelist():
        if n.endswith(('.xml', '.i3d')): E.fromstring(z.read(n))
digest = hashlib.sha256(package).hexdigest()
record = {'archive': target.name, 'version': version, 'sha256': digest,
          'lua51_checks': 'passed', 'runtime_verified': True,
          'runtime_verified_date': status['runtime_verified_date'],
          'release_tag': 'ad-parking-nodes-v' + version}
metadata = target.parent / 'ad-parking-nodes-build.json'
checksums = target.parent / 'SHA256SUMS-ad-parking-nodes.txt'
if args.check:
    assert target.read_bytes() == package, 'Committed ZIP differs from source'
    assert json.loads(metadata.read_text()) == record, 'Build metadata mismatch'
    assert checksums.read_text().strip() == digest + '  ' + target.name
else:
    target.write_bytes(package)
    metadata.write_text(json.dumps(record, indent=2) + '\n')
    checksums.write_text(digest + '  ' + target.name + '\n')
print(json.dumps(record, indent=2))
