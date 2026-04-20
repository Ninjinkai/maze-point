# Maze Point Repo Map

Use this map before reading files:

- `scripts/game.gd` — top-level coordinator for gameplay state and menu flow.
- `scripts/game/` — extracted helpers for input, rendering, progression, persistence, playfield math, shared enums/types, and UI styles.
- `scripts/game/game_ui_styles.gd` — active UI font selection, multilingual font stack, and bundled fallback-font wiring.
- `scripts/maze_generator.gd` — generator entry point.
- `scripts/generator/` — generator heuristics and puzzle data objects.
- `scripts/procedural_audio.gd` — audio controller entry point.
- `scripts/audio/` — procedural audio math, stream creation, and music-style data.
- `scripts/localization_data.gd` — localized strings and language metadata.
- `tests/` — headless test runner plus focused unit tests for pure helpers.
- `node_2d.tscn` — main scene.
- `assets/fonts/` — bundled UI fonts, including deterministic fallbacks for locales that cannot rely on host-system font resolution.

Default behavior:

1. Read only the entrypoint plus the directly-related helper folder.
2. Pull in tests for the touched component before editing.
3. Expand outward only if contracts between components actually changed.
4. For language bugs, check both `scripts/localization_data.gd` and the menu/font path in `scripts/game.gd` before assuming the issue is text-only.
