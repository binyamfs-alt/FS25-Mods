# Validation: 1.0.0.6

## In-game test, October 30, 2026

The user confirmed the straight preview, spacing controls, primary/secondary
selection and placement work. The successful session used AutoDrive 3.0.1.2.
The log records activation and creation of six unconnected primary nodes over
23.53 m with maximum spacing 5 m. No parking-tool Lua errors or call stacks
were present. Multiplayer has not been runtime-tested.

Optional-area warnings remain on selection of the temporary catalog preview:
missing clearing, indoor, AI update and leveling areas. The tool deliberately
has no physical placement or ground modification areas. An unrelated PF
Configurator FUNGICIDE mapping error was excluded from the parking-tool result.

## Automated checks

Lua 5.1 tests pass for spacing 1-10 m, endpoints, diagonal rows, threshold node
counts, independent empty connection arrays, native AD event arguments, terrain
height preflight, confirm/cancel, type switching and unrelated-brush passthrough.
Construction tests include deferred/cached selection, the protected base-class
metatable, complete activation/update/draw/deactivation and invalid-constructor
rollback. Release packaging is deterministic and checked against committed source.

GIANTS TestRunner 0.9.22 non-GUI checks passed descriptor, Lua, I3D, texture,
mipmap and packaged-file checks. The overall result was FAIL for an opaque BC7
store-icon alpha channel and physical-placeable expectations for clearing/
leveling areas and sounds; price zero is intentional. GUI/editor checks were
skipped. This is not a claim of a full TestRunner pass or ModHub certification.

## Development history

Versions 1.0.0.1-1.0.0.5 were development-only and should not be distributed.
They exposed catalog registration, deferred selection and constructor issues.
Version 1.0.0.6 is the first user-confirmed working build. Its installed runtime
Lua is unchanged for publication; release preparation updates documentation,
licensing and reproducible packaging only.

## 1.0.0.7
Terrain-only targeting and on-top preview regression checks pass in Lua 5.1. User verified painted guides and shed placement in game on 2026-10-30 with AutoDrive 3.0.1.2.
