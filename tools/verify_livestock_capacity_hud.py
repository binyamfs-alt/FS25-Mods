from pathlib import Path
import hashlib
import xml.etree.ElementTree as ET
import zipfile

root = Path(__file__).resolve().parents[1]
source = root / 'FS25_z_LivestockCapacityHUD'
package = root / 'builds/FS25_z_LivestockCapacityHUD.zip'
expected = '0358c85d22e406b1ad7eaa4d2648b8fdedb133224c56857b3ee9c86341e45d39'
assert hashlib.sha256(package.read_bytes()).hexdigest() == expected
with zipfile.ZipFile(package) as archive:
    assert archive.testzip() is None
    names = set(archive.namelist())
    expected_names = {p.relative_to(source).as_posix() for p in source.rglob('*') if p.is_file() and p.suffix != '.md'}
    assert names == expected_names
    for name in names:
        assert archive.read(name) == (source / name).read_bytes(), name
    descriptor = ET.fromstring(archive.read('modDesc.xml'))
    assert descriptor.findtext('version') == '1.0.0.6'
    assert descriptor.findtext('author') == 'BinyamFS'
    assert descriptor.findtext('iconFilename') in names
    for element in descriptor.findall('extraSourceFiles/sourceFile') + descriptor.findall('specializations/specialization'):
        assert element.attrib['filename'] in names
print('PASS: ZIP integrity, original checksum, complete source equality, descriptor and script references')
