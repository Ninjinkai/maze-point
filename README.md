# Maze Point

Maze Point is a colorful number-path puzzle built with Godot. Every level is a procedurally generated grid with adaptive difficulty and fully procedural music and sound.

## How to play

The game opens on a title screen before the first run begins, with language and audio controls available before play.

Start anywhere the level places you and reach the goal with the **exact target total** shown on the goal cell.

- **Mouse / touch:** click or tap an orthogonally adjacent cell to move.
- **Keyboard:** move with **WASD** or the **arrow keys**.
- **Gamepad:** move with the **D-pad** or **left stick**.
- **Pause menu:** `Esc`, the top-bar pause button, or gamepad `Start`.

Rules:

- You begin each level at **0**.
- Every time you move onto a non-goal cell, that cell's number is added to your running total.
- Backtracking is allowed, and revisiting a cell adds its value again.
- Reaching the goal always ends the level.
- The goal clears the level only when your total exactly matches the target shown on it.
- The running total is shown on the player marker so it stays visible while you move.

## Level flow

- Clearing a level lets you **continue**, **retry the same level**, or **end the run**.
- Retry keeps the **same grid layout and music** for that level.
- Start and goal positions are pushed far apart to encourage crossing and exploring the full board.
- New levels increase difficulty gradually with smoother board-size steps, steadier shape changes, and more varied intended solution routes.
- Clears are rated from **1 to 3 stars** based on how close your route stayed to the optimal path.
- Each run keeps a single evolving procedurally generated music theme.
- The end-of-run screen includes a final star score based on stars earned, levels cleared, and total resets.

## UI actions

- **Confirm / continue:** `Enter`, `Space`, or gamepad `A`
- **Retry level:** `R` or gamepad `Y`
- **End run:** `E` or gamepad `B`
- **Invert colors:** `I` or gamepad `X`
- **Pause menu:** `Esc` or gamepad `Start`
- **Title and pause controls:** both menus include separate music and SFX volume sliders, and both let you cycle the active language.
- **Language selector controls:** `Enter`, click, or tap cycles the focused language selector, while keyboard/gamepad left-right changes the language in place without kicking focus back to the first menu button.
- **Saved preferences:** language, music volume, SFX volume, and color inversion persist between launches.
- **Menu navigation:** arrow keys or gamepad **D-pad**

## Audio

All music and sound effects are generated in code at runtime.

- No external audio assets are required.
- Each run keeps a persistent procedural music theme instead of resetting every level or retry.
- The music shifts its energy as the run state changes.
- Movement, goal clear, failure, menu navigation, restart, and palette inversion all have synthesized cues.
- The best run score is saved locally and shown on the title screen and pause menu.

## Localization

- Maze Point includes built-in UI localization for English, Simplified Chinese, Hindi, Spanish, Arabic, French, Brazilian Portuguese, German, Japanese, and Korean.
- Language selection is available from the title screen before a run starts and again from the pause menu mid-run.
- Non-English UI text uses the multilingual font path, with a bundled Simplified Chinese fallback font so CJK coverage does not depend only on the host OS.

## Running locally

1. Install **Godot 4.6.2**.
2. Open this project in Godot, or run:

   ```bash
   godot --path .
   ```

## Running tests

Run the lightweight headless helper-suite with:

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

## Copilot agents and skills

Repository-local Copilot scaffolding lives under `.github/`:

- `.github/agents/` — component agents for gameplay/UI, generator/balance, audio/localization, validation/release, plus an orchestrator
- `.github/skills/` — reusable repo-map, validation, and component-scope skills
- `.github/prompts/` — prompt content backing the skills
- `.github/workflows/copilot-setup-steps.yml` — cloud-agent setup that installs Godot 4.6.2 before work begins

Use the orchestrator first for broad requests, then route to the narrowest component agent that matches the change.
The current guidance also captures recent lessons around deterministic CJK font fallback, language-selector left/right behavior, splash-menu focus retention, and filtering out accidental Godot-generated validation churn.

## Desktop builds

Desktop export presets are included for:

- Windows
- macOS
- Linux

Runnable desktop builds are written to `build/desktop/` when you export locally:

- `build/desktop/windows/MazePoint.exe`
- `build/desktop/macos/MazePoint.app`
- `build/desktop/linux/MazePoint.x86_64`

Windows and Linux exports also include a matching `.pck` data file beside the executable.

For publishing, GitHub Releases is a better fit than committing raw desktop binaries into the repository because the native executables are large, especially on macOS.

## Repository layout

- `scripts/game.gd` - high-level game coordinator
- `scripts/game/` - extracted gameplay progression, input, persistence, styling, rendering, playfield utilities, and shared game types
- `scripts/maze_generator.gd` - procedural number-grid generation and optimal-path validation
- `scripts/generator/` - extracted generator scoring, path-shape heuristics, and puzzle value objects
- `scripts/procedural_audio.gd` - procedural music and synthesized sound effects controller
- `scripts/audio/` - extracted audio math, music-style data objects, and stream-building helpers
- `tests/` - headless unit tests for pure helper modules
- `assets/fonts/` - bundled UI font assets
