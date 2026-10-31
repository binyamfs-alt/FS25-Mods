# Perfect Edge Meadow Companion

Testing version **1.0.0.1**. User verified meadow placement works in-game on October 30, 2026. Not released.

Enable alongside the original `FS25_PerfectEdge` mod. In Construction > Plants,
select meadow and hold Left Shift while dragging, just as for ground painting.
The original PerfectEdge mod chooses and locks the axis after 0.25 m movement.
The same support applies to other foliage painted with the foliage brush.

This companion only connects the foliage brush's activate, update and deactivate
callbacks to PerfectEdge's existing functions. It does not copy or modify the
third-party mod, define a second hotkey, change placement costs or permissions,
or change crop/soil data. Original brush arguments and return values are preserved.
Methods already inherited from the hooked paint brush are not hooked twice.

Known limits: matches the API of PerfectEdge 1.1.0.0; runtime meadow placement was verified by the user on October 30, 2026. If the required interface is absent, a warning is logged
and no brush methods are changed.

References: original installed PerfectEdge 1.1.0.0 was inspected read-only;
GIANTS FS25 SDK `xmlDoku/constructionBrushTypes.xml` identifies foliage painting
as `ConstructionBrushFoliage` and ordinary painting as `ConstructionBrushPaint`.

Source is maintained on the `feature/perfect-edge-meadow` branch of
https://github.com/binyamfs-alt/FS25-Mods. No release or merge is authorized.
