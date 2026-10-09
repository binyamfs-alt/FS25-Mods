# BinyamFS Modding Workflow

This repository is the authoritative source of truth for BinyamFS Farming Simulator 25 mod development.

## Non-negotiable rules

1. All mod work is based out of GitHub. Local files are working copies only.
2. Every mod under active development must have its source committed to GitHub before further debugging or feature work continues.
3. GitHub repository state, not chat memory or a local mods folder, defines the current authoritative version.
4. Once a mod is debugged and considered usable, it must have a GitHub release. The release may be public or private as appropriate, but there is no exception to the release requirement.
5. Release assets must be built from, or exactly match, the committed source for that release.
6. Version, debug status, release status, known issues, and next work item must be recoverable from GitHub without relying on prior chat history.
7. Before modifying a mod, review its GitHub source and latest release first. Do not reconstruct prior work from memory when GitHub contains the authoritative state.
8. Third-party mods or bespoke edits to others' work must not be redistributed without permission. When redistribution is not allowed, GitHub should contain only permitted patch/source material and documentation.

## Per-mod minimum state

Each mod should have:
- committed source
- current version in `modDesc.xml`
- concise README or release notes describing purpose and behavior
- known issues / debug notes when unresolved
- tagged GitHub release once debugged
- packaged ZIP corresponding to the released source

## Working principle

If a chat and GitHub disagree, GitHub wins unless a deliberate change is being made and committed during the current work session.
