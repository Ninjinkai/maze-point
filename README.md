# Maze Point

Maze Point is a colorful number-path puzzle built with Godot. Every level is a procedurally generated grid with adaptive difficulty, a hard timer, and fully procedural music and sound.

## How to play

Start anywhere the level places you and reach the goal with the **exact target total** shown on the goal cell.

- **Mouse / touch:** click or tap an orthogonally adjacent cell to move.
- **Keyboard:** move with **WASD** or the **arrow keys**.
- **Gamepad:** move with the **D-pad** or **left stick**.

Rules:

- You begin each level at **0**.
- Every time you move onto a non-goal cell, that cell's number is added to your running total.
- Backtracking is allowed, and revisiting a cell adds its value again.
- The goal only clears the level when your total exactly matches the target shown on it.
- If your total goes above the target, the level fails immediately.

## Level flow

- The timer starts after the spawn animation.
- If time runs out, the level ends immediately.
- Clearing a level lets you **continue**, **retry the same level**, or **end the run**.
- Retry keeps the **same grid layout and music** for that level.
- New levels increase difficulty with larger grids and higher target totals.
- New levels get their own procedurally generated music theme.

## UI actions

- **Confirm / continue:** `Enter`, `Space`, or gamepad `A`
- **Retry level:** `R` or gamepad `Y`
- **End run:** `Esc` or gamepad `Start`
- **Invert colors:** `I` or gamepad `X`
- **Menu navigation:** arrow keys or gamepad **D-pad**

## Audio

All music and sound effects are generated in code at runtime.

- No external audio assets are required.
- Each level gets a different procedural music loop.
- Movement, goal clear, failure, menu navigation, restart, and palette inversion all have synthesized cues.

## Running locally

1. Install **Godot 4.6.2**.
2. Open this project in Godot, or run:

   ```bash
   godot --path .
   ```

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

- `scripts/game.gd` - gameplay, UI, input, rendering, totals, and animation hooks
- `scripts/maze_generator.gd` - procedural number-grid generation, target construction, and optimal-path validation
- `scripts/procedural_audio.gd` - procedural music and synthesized sound effects
- `assets/fonts/` - bundled UI font assets
