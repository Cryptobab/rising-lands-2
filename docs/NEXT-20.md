# Next 20 Execution Backlog

This document records the next bounded 20-task tranche that was selected and executed to push the classic campaign toward completion.

## Status

1. `[done]` Add a tracked execution backlog document for the next tranche.
2. `[done]` Add `control_building` mission-objective support for takeover scenarios.
3. `[done]` Add `transfer_building_team` mission-event action.
4. `[done]` Add `transfer_unit_team` mission-event action.
5. `[done]` Add `campaign_complete()` campaign-state helper.
6. `[done]` Surface campaign-complete result payload in the mission result flow.
7. `[done]` Author Mission 21 scenario content.
8. `[done]` Author Mission 22 scenario content.
9. `[done]` Author Mission 23 Great Library takeover scenario content.
10. `[done]` Author Mission 24 southeast sanctuary scenario content.
11. `[done]` Author Mission 25 final-annihilation scenario content.
12. `[done]` Add ownership-transfer regression coverage.
13. `[done]` Add final-campaign progression regression coverage for Missions 21 through 25.
14. `[done]` Update the active project phase marker.
15. `[done]` Update the README to reflect the full 25-mission classic slice.
16. `[done]` Update the continuation handoff with the new runtime and campaign coverage.
17. `[done]` Update the session log with the new tranche.
18. `[done]` Run importer tests.
19. `[done]` Run the full Godot smoke-test regression suite.
20. `[done]` Commit and push the tranche to `origin/main`.

## Result

The classic campaign now has authored scenario coverage through Mission 25, a final-campaign smoke path, ownership-transfer scripting for takeover scenarios, and campaign-complete result support in the shell/runtime snapshot.

Follow-on foundation after this tranche:

- explicit `classic` / `expanded` ruleset manifests now back a neutral database loader
- runtime saves, campaign profiles, slot metadata, and shell snapshots now carry `ruleset_id`
- `game/data/expanded` now contains an internal proving-ground dataset used to validate alternate ruleset loading without exposing a public unfinished mode
