# Expanded Data

This folder holds new content created for the remake expansion layer.

Current structure:

- `ruleset_manifest.json`: ruleset identity and root-path metadata
- `normalized/`: expanded-mode mission and database payloads
- `vertical_slice/`: internal proving-ground maps for loader and save-path validation

Current status:

- the expanded path is internal-only
- it now has a minimal real mission/map dataset so tests can validate ruleset-aware loading
- it is not yet a public playable shell mode

Keep this content separate from the imported classic ruleset.
