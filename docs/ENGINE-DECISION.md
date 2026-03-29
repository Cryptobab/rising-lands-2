# Engine Decision

The project is switching to `Godot 4`.

## Decision

Use Godot as the active runtime and editor for the remake.

## Why Not Keep The Browser Prototype

The prototype was useful for quick exploration, but it is not the right base for:

- large campaign state
- robust editor workflow
- maintainable RTS scripting
- save compatibility over a long project
- scalable content tooling

## Why Godot

- strong 2D feature set
- good fit for a public repo
- easier solo/small-team iteration than Unreal
- lower project friction than Unity for this specific remake
- straightforward data-driven workflow

## Language Choice

Start with typed `GDScript`.

Reason:

- local machine currently lacks the Godot editor
- local machine lacks a usable .NET SDK
- typed GDScript removes those blockers while still giving a clean Godot-native workflow

If later needed, performance-critical systems can move to C++ or C# after the runtime and content pipeline are stable.
