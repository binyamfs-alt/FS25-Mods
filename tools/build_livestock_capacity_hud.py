"""Build Livestock Capacity HUD deterministically from this checkout."""
from pathlib import Path
import zipfile
ROOT = Path(__file__).resolve().parents[1]
source = ROOT / 'FS25_z_LivestockCapacityHUD'
output = ROOT / 'builds/FS25_z_LivestockCapacityHUD.zip'
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for p in sorted(source.rglob('*')):
        if p.is_file() and p.suffix != '.md':
            info = zipfile.ZipInfo(p.relative_to(source).as_posix(), (1980,1,1,0,0,0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, p.read_bytes())
print(output)
