# AutoDrive Parking Node Rows

Testing version **1.0.0.1**. Initial construction-tool implementation; engine
and in-game validation pending. No public release or merge authorized.

Find **AutoDrive Parking Node Row** in **Construction > Decorations > Others**.
Click once to anchor a row, stretch its preview, then click again to place.
Right-click cancels an anchored row; right-click again exits. The construction
tertiary action switches primary/secondary nodes. The construction primary-axis
(brush size) controls adjust maximum spacing in 1 m steps from 1 to 10 m,
default 5 m. Both endpoints are included, with equal spacing no larger than the
selected maximum. Thus stretching beyond a spacing threshold adds another node.
Rows are capped at 500 m. The preview displays length and node count.

Nodes have **no incoming or outgoing connections**. The tool places no physical
decoration, charges no money, and does not change landscaping. It calls
AutoDrive's existing networked graph API so normal AutoDrive saving applies.
Turn on AutoDrive's editor display to inspect finished nodes.

The original AutoDrive mod is a dependency and is not modified or redistributed.
Integration reference: read-only installed AutoDrive 3.0.1.2 GraphManager and
CreateWayPointEvent; GIANTS FS25 SDK construction categories and brush types;
official ConstructionScreen action registration documentation.

Known limits: construction UI wiring needs runtime validation. This build does
not add destination names/markers or connect new nodes to existing routes.
