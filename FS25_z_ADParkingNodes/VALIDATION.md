# Validation, 1.0.0.5

Lua 5.1 tests pass for spacing 1-10 m, both endpoints, diagonal rows, threshold
node counts, independent empty connection arrays, native AD event arguments,
height preflight, confirm/cancel, type switching and unrelated-brush passthrough.

GIANTS TestRunner 0.9.22, non-GUI checks, October 30, 2026: descriptor, Lua,
I3D, texture, mipmap and packaged-file checks pass. Overall result remains FAIL:
- BC7 store icon has opaque alpha (format itself matches store-icon requirement).
- Physical-placeable checks expect clearing/leveling areas and placement sounds;
  those are deliberately absent for a graph-only tool. Price zero is intentional.

No editor/engine/UI test was run; Construction-menu runtime validation is pending.

Runtime 1.0.0.1 rejected the unregistered adParkingNodes brush before catalog insertion. Version 1.0.0.2 uses the registered placeable type and routes only this mod's XML through its custom brush. A regression check verifies the XML type and preserves unrelated factory calls and nil return values. Runtime retest pending.

Runtime 1.0.0.2 entered a normal physical-placement preview because the screen constructs the reusable brush with no store item. Version 1.0.0.3 intercepts loadCurrentConfiguration before physical preview loading. Regression tests cover deferred selection, repeat selection and unrelated preview forwarding. No saved placeholders were found in the active standard savegame2. Runtime retest pending.

Version 1.0.0.4 additionally checks the loaded preview in ConstructionScreen.draw, using Placeable.configFileName (verified against installed Move Placeables and Unrestricted Placement code). Tests cover cached selection paths, store lookup, replacement, unrelated previews and nil-return forwarding. Runtime retest pending.

Version 1.0.0.4 is broken: the constructor incorrectly passed the store item as the base brush metatable, causing missing activate/update methods and Construction-screen errors. Version 1.0.0.5 passes the metatable correctly, validates all five required callbacks before selection, and returns to the selector if activation fails. Regression tests now use the one-argument base constructor and execute activation/update/draw/deactivation, including invalid-constructor rollback. Runtime verification remains pending.
