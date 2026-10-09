# Livestock Capacity HUD — 1.0.0.6

[Download the playable ZIP](https://github.com/binyamfs-alt/FS25-Mods/releases/download/livestock-capacity-hud-v1.0.0.6/FS25_z_LivestockCapacityHUD.zip) · [Release](https://github.com/binyamfs-alt/FS25-Mods/releases/tag/livestock-capacity-hud-v1.0.0.6)

Displays livestock trailer animal count, capacity, and percentage in the game HUD. Adds protection against transferring incompatible animal types and keeps the trailer's loaded-animal view independent of the pen. Breeds of the same animal type remain allowed.

## Installation

Place `FS25_z_LivestockCapacityHUD.zip` in your active Farming Simulator 25 mods folder, retain its filename, and enable it.

## Authoritative state

- Source: this directory. Author: BinyamFS. License: GPL-3.0-or-later; full license preserved in `modDesc.xml`.
- Version: 1.0.0.6, as recorded in `modDesc.xml`.
- Package: `builds/FS25_z_LivestockCapacityHUD.zip`; preserved byte-for-byte from the user-specified installed artifact during initial GitHub recovery on 2026-10-09. No previous GitHub source or release was found for this mod. Future changes start from this committed source.
- SHA-256: `0358c85d22e406b1ad7eaa4d2648b8fdedb133224c56857b3ee9c86341e45d39`.
- Release: `livestock-capacity-hud-v1.0.0.6`; workflow validates source/package correspondence before publication.
- Debugging status: existing installed build preserved unchanged. Package integrity, descriptor references, source equality, and Lua syntax are checked for this release. No new in-game or multiplayer testing was performed during archival.
- Known issues/limitations: dialog diagnostics and controller lookup logging remain enabled. No additional runtime issues are established by this archival verification.
- Next work item: confirm transfer protection and HUD behavior in-game and in multiplayer, then remove temporary diagnostics in a new version if appropriate.

## Version behavior

1.0.0.6 rejects incompatible transfers before dialog success confirmation. 1.0.0.5 uses loaded animal types for the trailer view. Earlier versions added controller protection, selection checks, capacity display, and diagnostic logging. The original changelog remains in `modDesc.xml`.
