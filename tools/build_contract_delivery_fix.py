from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
source = root / 'FS25_z_ContractDeliveryFix'
destination = root / 'builds' / 'FS25_z_ContractDeliveryFix.zip'
destination.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(source.rglob('*')):
        if path.is_file() and path.suffix != '.md':
            info = zipfile.ZipInfo(path.relative_to(source).as_posix(), (2026, 10, 8, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, path.read_bytes())
print(destination)
