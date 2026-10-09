# Livestock Capacity HUD — 1.0.0.7

Displays livestock trailer animal count, capacity and percentage. Protects against incompatible animal loading and preserves the loaded-animal trailer view.

## Butcher unloading correction

Version 1.0.0.6 compared the trailer load with a single husbandry type during every transfer. This incorrectly blocked La Boucherie, whose Extended Production controller accepts multiple types and consumes trailer animals through `applySource`.

Version 1.0.0.7 leaves that production unload path to its original controller, including subtype, age and capacity validation. The exception requires both animal acceptance tables and applies only to source transfers. Target/loading actions and normal pen guards retain their existing protection. Saved animals are not modified by this update.

## Installation and build

Replace the existing `FS25_z_LivestockCapacityHUD.zip` with the ZIP from this branch's `builds/` directory after closing FS25, then restart and enable it. Keep its filename unchanged.

Run `python tools/build_livestock_capacity_hud.py` and `python tools/verify_livestock_capacity_hud.py` from the checkout. Run `python tools/test_livestock_dialog.py` with `lupa` installed for the Lua 5.1 regression checks.

## Status

Source and matching build are maintained in this GitHub branch. Author: BinyamFS. GPL-3.0-or-later; full license remains in modDesc.xml. The published 1.0.0.6 release remains historical; 1.0.0.7 is a development build pending in-game confirmation.

Regression checks cover production unloading through both interception layers, continued rejection of incompatible loading, normal pen guards, cancellation, original arguments/returns and trailer type views. ZIP integrity and source equality are verified. Diagnostics remain enabled. Next: confirm goat unloading at La Boucherie in-game; multiplayer is unverified.
