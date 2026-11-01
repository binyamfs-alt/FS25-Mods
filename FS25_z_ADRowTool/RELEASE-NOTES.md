# AD Row Tool 1.1.0.0

Create straight and curved AutoDrive node paths from the free Construction camera.

- Unconnected, One-way and Bidirectional modes (H).
- Primary/secondary selection (B) and 1-10 m maximum spacing (N/M).
- Circular curves from 0 to 180 degrees in 5-degree steps (K/L).
- Independent curve flip (R), preserving one-way travel direction.
- Preview across placeables and inside sheds.
- F1 connection label refresh and safe cursor initialization.

**Upgrade:** remove `FS25_z_ADParkingNodes.zip`, install `FS25_z_ADRowTool.zip` and enable AD Row Tool. Existing AutoDrive routes are preserved.

**Node visibility:** be in a vehicle with AutoDrive editor mode enabled. Connected modes require single-player or the multiplayer host. Multiplayer remains untested. No automatic joining to existing routes. Four known optional-area warnings may occur when selecting the temporary catalog preview.

Verified with FS25 1.25.0.0 and AutoDrive 3.0.1.2. The final test log contains zero script errors and successful connected node placement; automated Lua 5.1 and package checks pass. Release Lua is unchanged from tested 1.0.0.15.

AutoDrive by Stephan Schlosser and the AutoDrive contributors: https://github.com/Stephan-S/FS25_AutoDrive. AutoDrive is a separate dependency, not modified or bundled. Unofficial companion. See CREDITS.md and LICENSE.
