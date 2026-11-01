# AD Row Tool

**Version 1.0.0.15** · [Download ZIP](https://github.com/binyamfs-alt/FS25-Mods/releases/download/ad-row-tool-v1.0.0.15/FS25_z_ADRowTool.zip) · [Release](https://github.com/binyamfs-alt/FS25-Mods/releases/tag/ad-row-tool-v1.0.0.15)

Create straight or curved rows of AutoDrive nodes with two clicks. This is useful
for lining up parking bays along farmyards, sheds and buildings.

## Install

Put `FS25_z_ADRowTool.zip` in your active mods folder and enable it alongside
**FS25_AutoDrive**. Do not unzip it. The original AutoDrive mod is unchanged.

## Use

1. Enter a vehicle and enable AutoDrive's **editor mode** to see AutoDrive nodes. This is required by AutoDrive for node visibility.
2. Open **Construction > Decorations > Others > AD Row Tool**.
3. Click to anchor the start, move the cursor to stretch the straight preview,
   then click again to place the row.
4. Use **B** to switch primary/secondary nodes and **N / M** to adjust maximum
   spacing from **1-10 m**, default **5 m**. Bindings follow your Construction controls.
5. Right-click to cancel an unfinished row; right-click again to leave the tool.

The preview shows node count, length and type. Both endpoints are included;
gaps are equal and never exceed the selected spacing. For example, a 35 m row
at 5 m spacing creates eight nodes. Maximum row length is 500 m.

**H** cycles **Unconnected → One-way → Bidirectional** using the Construction fourth-action binding. Unconnected is the default. One-way runs from the first click toward the second. Connections are created only between adjacent nodes in the new row; existing routes are never joined automatically. Connected rows currently require single-player or the multiplayer host.

In Unconnected mode, nodes have **no incoming or outgoing connections**. No physical decoration is
placed, no landscaping is changed, and placement is free. You must be in a vehicle with AutoDrive's **editor mode** enabled to see the placed nodes. Save normally to retain them through
AutoDrive's own configuration. Add destination names or route connections in
AutoDrive afterward if needed.

## Compatibility and validation

User-tested on October 30, 2026 with AutoDrive **3.0.1.2**. Straight preview,
primary/secondary selection, adjustable spacing and node creation were confirmed.
The successful session logged no parking-tool Lua errors.

Automated Lua 5.1 checks cover geometry, spacing thresholds, empty connections,
AutoDrive network API arguments, selection paths, protected metatables,
activation rollback, input controls and unrelated-brush passthrough. See
[validation](VALIDATION.md) and [build status](status.json).

Multiplayer uses AutoDrive's existing network events but has not been runtime-tested.
Selecting the tool may log warnings about missing optional clearing, indoor,
AI and leveling areas on its temporary catalog preview. Those areas are omitted
because this tool must not alter the ground. No destination names or automatic connections to existing routes are created.

## Source and license

Original companion code and artwork: BinyamFS, [MIT license](LICENSE). AutoDrive
is developed by **Stephan Schlosser and the AutoDrive contributors** and is a separate dependency, not modified or redistributed here.

[Official AutoDrive project](https://github.com/Stephan-S/FS25_AutoDrive) · [AutoDrive downloads](https://github.com/Stephan-S/FS25_AutoDrive/releases) · [AutoDrive MIT license](https://github.com/Stephan-S/FS25_AutoDrive/blob/main/LICENSE) · [Credits](CREDITS.md). This is an
unofficial companion, not endorsed by AutoDrive or GIANTS Software.

Run `python test_parking_rows.py` with `lupa==2.8` installed. Run `python build.py`
to build, or `python build.py --check` to verify the committed release package.
The GitHub Actions release workflow publishes the verified ZIP and checksum.

The tool keeps its target on terrain through placeables and renders the preview over surfaces, allowing alignment with painted guides and placement inside sheds. Verified in game with AutoDrive 3.0.1.2.

## Curves (testing)

**K / L** decrease/increase the curve by **5 degrees**, from **0 to 180 degrees**, using the Construction secondary-axis bindings. Zero is straight, 90 degrees a quarter-circle, and 180 degrees a semicircle. Click the start and end as usual; adjust the bend while previewing. Press **R** to flip the bend without changing endpoint order or one-way travel. Spacing is measured along the arc, with a 500 m maximum path length. All three connection modes apply. New paths do not automatically join existing nodes.

When upgrading from the original filename, delete `FS25_z_ADParkingNodes.zip` and enable `FS25_z_ADRowTool.zip` instead. Do not enable both copies. Existing AutoDrive nodes and routes remain in AutoDrive's save data.
