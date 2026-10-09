"""Build the independent companion mod; never read or package Courseplay files.
"""
from pathlib import Path
import argparse
import struct
import xml.etree.ElementTree as ET
import zipfile
from io import BytesIO
from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / 'addon' if (ROOT / 'addon/modDesc.xml').exists() else ROOT
MOD_NAME = 'FS25_z_CourseplayBinyamFS'


def icon_dds():
    """Original 128px panel symbol, generated without third-party artwork/libraries."""
    size = 128
    pixels = bytearray()
    for y in range(size):
        for x in range(size):
            rgb = (13, 18, 15)
            if 15 <= x <= 112 and 18 <= y <= 109:
                rgb = (35, 43, 37)
                if x in (15, 16, 111, 112) or y in (18, 19, 108, 109):
                    rgb = (194, 202, 194)
                if 17 <= x <= 110 and 20 <= y <= 38:
                    rgb = (52, 81, 58)
                for row in (49, 68, 87):
                    if 25 <= x <= 102 and row <= y <= row + 12:
                        rgb = (194, 202, 194) if x in (25,102) or y in (row,row+12) else (24,30,25)
                    if 31 <= x <= 78 and row + 5 <= y <= row + 7:
                        rgb = (230, 247, 230)
            r,g,b = rgb
            pixels.extend((b,g,r,255))
    header = [124, 0x100F, size, size, size * 4, 0, 0] + [0] * 11
    header += [32, 0x41, 0, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000]
    header += [0x1000, 0, 0, 0, 0]
    raw = b'DDS ' + struct.pack('<31I', *header) + pixels
    image = Image.open(BytesIO(raw)).convert('RGB').resize((512, 512), Image.Resampling.NEAREST)
    output = BytesIO()
    image.save(output, format='DDS', pixel_format='DXT1')
    return output.getvalue()


def source_files():
    names = ['modDesc.xml', 'scripts/CpHudSkin.lua', 'scripts/CourseplayBinyamFS.lua', 'README.txt']
    files = {name: (SOURCE / name).read_bytes() for name in names}
    files['README.txt'] += b'\n\n' + (SOURCE / 'NOTICE.txt').read_bytes() + b'\n\n' + (SOURCE / 'LICENSE.txt').read_bytes()
    files['icon_CourseplayBinyamFS.dds'] = icon_dds()
    desc = ET.fromstring(files['modDesc.xml'])
    for entry in desc.findall('./extraSourceFiles/sourceFile'):
        assert entry.get('filename') in files
    assert desc.findtext('./dependencies/dependency') == 'FS25_Courseplay'
    return files


def build(output):
    files = source_files()
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path, data in sorted(files.items()):
            info = zipfile.ZipInfo(path, (2026, 10, 8, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    return len(files)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=ROOT / 'builds' / (MOD_NAME + '.zip'))
    args = parser.parse_args()
    print(f'Built {args.output} ({build(args.output)} files; Courseplay installed separately)')
