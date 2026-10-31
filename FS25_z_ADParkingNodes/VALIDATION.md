# Validation, 1.0.0.1

Lua 5.1 tests pass for spacing 1-10 m, both endpoints, diagonal rows, threshold
node counts, independent empty connection arrays, native AD event arguments,
height preflight, confirm/cancel, type switching and unrelated-brush passthrough.

GIANTS TestRunner 0.9.22, non-GUI checks, October 30, 2026: descriptor, Lua,
I3D, texture, mipmap and packaged-file checks pass. Overall result remains FAIL:
- BC7 store icon has opaque alpha (format itself matches store-icon requirement).
- Physical-placeable checks expect clearing/leveling areas and placement sounds;
  those are deliberately absent for a graph-only tool. Price zero is intentional.

No editor/engine/UI test was run; Construction-menu runtime validation is pending.
