# Next 20 Execution Backlog

This is the next forward-looking 20-task tranche. It shifts the project from classic parity closure into classic alpha polish, runtime decomposition, shipping discipline, and the first honest expanded seeding work.

## Status

1. `[done]` Design the first honest creature-taming interaction using existing mission and unit data.
2. `[done]` Implement the taming runtime and allegiance transfer behavior.
3. `[done]` Add a dedicated taming smoke test.
4. `[done]` Add a GitHub Actions workflow for representative Godot smoke coverage.
5. `[pending]` Audit `GameRoot` orchestration slices and choose the first extraction boundary.
6. `[pending]` Extract command-card and selected-unit action handling from `GameRoot`.
7. `[pending]` Extract mission snapshot or objective support from `GameRoot`.
8. `[pending]` Preserve save compatibility and smoke coverage across the first refactor boundary.
9. `[pending]` Improve move-order clarity or formation spacing around dense groups and transports.
10. `[pending]` Surface richer selected-unit cooldown, transport, and tame state in the HUD.
11. `[pending]` Add a small manual interactive classic-campaign validation checklist.
12. `[pending]` Document reproducible local smoke commands in a helper script or README section.
13. `[pending]` Define the first export or package path for Windows builds.
14. `[pending]` Add export preset or packaging scaffolding without committing binaries.
15. `[pending]` Audit the remaining classic spell data for the second spell tranche.
16. `[pending]` Implement one additional spell-depth or targeting improvement beyond the first druid slice.
17. `[pending]` Extend spell smoke coverage for the new spell-depth slice.
18. `[pending]` Seed the first real expanded unit data.
19. `[pending]` Seed the first real expanded building or tech data.
20. `[pending]` Add one expanded proving-ground smoke or loader-backed runtime check and update the roadmap docs with the tranche result.

## Success Condition

This tranche is complete when:

- the first oversized `GameRoot` responsibilities have moved into smaller runtime slices without breaking saves or smoke coverage
- local and CI validation cover importer tests plus the representative Godot runtime suite
- a Windows export path exists in committed config or documentation even if the build remains manual
- the expanded ruleset has its first real roster or building or tech footholds instead of remaining structurally empty
- the roadmap and continuation docs point to polish and expanded seeding instead of stale parity blockers
