# Contributing

This repo is a public fan remake project. Keep the work traceable, honest, and easy to review.

## Ground Rules

- Keep `main` stable.
- Use short-lived `feature/*` branches.
- One pull request should solve one problem.
- Update docs when architecture, scope, or workflow changes.
- Do not commit original proprietary game binaries, audio, video, or extracted art unless rights are clear.
- Keep active gameplay code in the Godot project under `game/`.
- Do not reintroduce retired browser-prototype files into the canonical branch.

## Workflow

1. Open or link an issue for the work.
2. Create a branch such as `feature/worker-jobs` or `feature/research-runtime`.
3. Keep commits focused and readable.
4. Open a pull request with a short problem statement, implementation summary, and test notes.

## Engineering Expectations

- Prefer data-driven systems over hard-coded one-off logic.
- Keep simulation logic separate from scene presentation and UI.
- Expand importer scripts instead of retyping original balance data by hand.
- Preserve a clean split between `classic` content and `expanded` content.

## Review Checklist

Before merging, confirm:

- the feature actually works end-to-end
- save/load behavior is still valid if persistence is affected
- docs reflect any roadmap or workflow changes
- performance did not regress badly in the main gameplay loop
- public-facing text does not overstate what is implemented
