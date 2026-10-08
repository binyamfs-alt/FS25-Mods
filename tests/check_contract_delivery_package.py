from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

root = Path(__file__).resolve().parents[1]
source = root / 'FS25_z_ContractDeliveryFix'
with zipfile.ZipFile(root / 'builds/FS25_z_ContractDeliveryFix.zip') as archive:
    assert sorted(archive.namelist()) == ['icon.png', 'modDesc.xml', 'scripts/ContractDeliveryFix.lua']
    for name in archive.namelist():
        assert archive.read(name) == (source / name).read_bytes(), name
    descriptor = ET.fromstring(archive.read('modDesc.xml'))
    assert descriptor.findtext('version') == '1.0.0.0'
    assert descriptor.find('multiplayer').get('supported') == 'true'
    assert archive.read(descriptor.findtext('iconFilename')).startswith(b'\x89PNG\r\n\x1a\n')
    assert descriptor.find('extraSourceFiles/sourceFile').get('filename') in archive.namelist()
print('PASS: installable ZIP structure, descriptor, icon, and exact source bytes')
