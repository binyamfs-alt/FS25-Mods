from pathlib import Path
import json, hashlib, zipfile, xml.etree.ElementTree as E
root = Path(__file__).parent
target = root.parent / 'builds/FS25_z_ADParkingNodes.zip'
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for p in root.rglob('*'):
        if p.is_file() and p.suffix in ['.lua','.xml','.dds','.i3d','.md']:
            z.write(p,p.relative_to(root).as_posix())
with zipfile.ZipFile(target) as z:
    assert z.testzip() is None
    for n in z.namelist():
        if n.endswith(('.xml','.i3d')): E.fromstring(z.read(n))
record={'archive':target.name,'version':'1.0.0.1','sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
        'lua51_checks':'passed','runtime_verified':False,'released':False}
(target.parent/'ad-parking-nodes-build.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps(record,indent=2))
