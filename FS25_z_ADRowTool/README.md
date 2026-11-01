# AD Row Tool

**Version 1.1.0.0** · [Download ZIP](https://github.com/binyamfs-alt/FS25-Mods/releases/download/ad-row-tool-v1.1.0.0/FS25_z_ADRowTool.zip) · [Release](https://github.com/binyamfs-alt/FS25-Mods/releases/tag/ad-row-tool-v1.1.0.0)

Create straight or curved rows of AutoDrive nodes using the free Construction camera. Preview the path and spacing before placing it. Useful for parking bays, yard lanes and route sections.

## Install and upgrade

Put `FS25_z_ADRowTool.zip` in your active mods folder without unzipping it. Enable it alongside **FS25_AutoDrive**. When upgrading from the old name, delete `FS25_z_ADParkingNodes.zip`; do not enable both copies. Existing nodes and routes remain in AutoDrive's save data.

## Use

1. Enter a vehicle and enable AutoDrive's **editor mode** to see AutoDrive nodes. This is AutoDrive's node-visibility requirement.
2. Open **Construction > Decorations > Others > AD Row Tool**.
3. Click the start, move the cursor to preview the path, and click again to place it.
4. Add connections to existing routes and destination names in AutoDrive as needed. Save normally.

| Control | Function |
|---|---|
| B | Primary / Secondary nodes |
| H | Unconnected / One-way / Bidirectional |
| N / M | Decrease / increase maximum spacing, 1-10 m (default 5 m) |
| K / L | Decrease / increase curve angle in 5-degree steps, 0-180 degrees |
| R | Flip the curve without changing endpoint order or travel direction |
| Right-click | Cancel the current path; right-click again to exit |

These follow your Construction bindings; the keys above are the tested keyboard defaults.

Unconnected is the default. One-way follows the first click toward the second; bidirectional connects each adjacent pair both ways. Only nodes in the new path are connected. Existing nodes are neither reused nor joined automatically.

Zero degrees is straight, 90 degrees a quarter-circle and 180 degrees a semicircle. Both clicks remain the endpoints. Spacing is equal along the arc and never exceeds the selected maximum. Both endpoints are included; maximum path length is 500 m. Terrain height is used even inside buildings. Preview markers render over surfaces. No physical decoration or landscaping is placed, and use is free.

## Compatibility and limitations

User-tested with FS25 **1.25.0.0** and AutoDrive **3.0.1.2**. Single-player or the multiplayer host is required for connected modes. Remote clients may use Unconnected mode; multiplayer has not been runtime-tested.

The final 1.0.0.15 test session recorded successful connected primary/secondary paths and zero script errors. Four warnings about missing clearing, indoor, AI update and leveling areas can appear on the temporary catalog preview. These intentionally absent areas must not modify the ground. See [validation](VALIDATION.md).

## Credits and license

AD Row Tool code and artwork: BinyamFS, [MIT license](LICENSE).

AutoDrive is developed by **Stephan Schlosser and the AutoDrive contributors**. [Official project](https://github.com/Stephan-S/FS25_AutoDrive) · [Downloads](https://github.com/Stephan-S/FS25_AutoDrive/releases) · [AutoDrive MIT license](https://github.com/Stephan-S/FS25_AutoDrive/blob/main/LICENSE).

AutoDrive is a separate dependency, not modified or included here. This is an unofficial companion and does not imply endorsement by the AutoDrive team or GIANTS Software. See [credits](CREDITS.md).

## Build

Install `lupa==2.8`, then run `python test_parking_rows.py`. Run `python build.py` to build, or `python build.py --check` to verify the committed package. GitHub Actions publishes the verified ZIP and checksum.
