# Gameplay & UI Skill

Own changes in:

- `node_2d.tscn`
- `scripts/game.gd`
- `scripts/game/**`

Typical tasks:

- title screen, loading transitions, pause flow, run-over flow
- HUD structure, fonts, layout, sizing, button styling
- playfield rendering, animation timing, touch/keyboard/gamepad behavior
- visual polish that should not alter puzzle generation or audio logic

When editing:

1. Preserve existing generator/audio interfaces unless the task explicitly crosses those domains.
2. Prefer extracting new pure helpers into `scripts/game/` rather than growing `scripts/game.gd`.
3. If a render helper already exists in `game_renderer.gd`, extend it there instead of duplicating draw logic in the coordinator.
