# Maze Point

Maze Point is a colorful score-chasing maze game built with Godot. Every level is a node-and-wall maze with adaptive difficulty, a hard timer, and fully procedural music and sound.

## How to play

Reach the goal marker to clear the maze.

- **Mouse / touch:** click or tap an adjacent connected node to move.
- **Keyboard:** move with **WASD** or the **arrow keys**.
- **Gamepad:** move with the **D-pad** or **left stick**.

Every maze score is based on:

- **steps taken**
- **red nodes** add `5`
- **green nodes** subtract `5`

The score is clamped at **0**, so the ideal route finishes at **0**.

## Level flow

- The timer starts after the spawn animation.
- If time runs out, the maze ends immediately.
- Clearing a maze lets you **continue**, **retry the same maze**, or **end the run**.
- Retry keeps the **same maze layout and music** for that level.
- New levels get their own procedurally generated music theme.

## UI actions

- **Confirm / continue:** `Enter`, `Space`, or gamepad `A`
- **Retry maze:** `R` or gamepad `Y`
- **End run:** `Esc` or gamepad `Start`
- **Invert colors:** `I` or gamepad `X`
- **Menu navigation:** arrow keys or gamepad **D-pad**

## Audio

All music and sound effects are generated in code at runtime.

- No external audio assets are required.
- Each level gets a different procedural music loop.
- Movement, bonus pickup, goal clear, timeout, menu navigation, restart, and palette inversion all have synthesized cues.

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

- `scripts/game.gd` - gameplay, UI, input, rendering, scoring, animation hooks
- `scripts/maze_generator.gd` - procedural maze generation, routing, bonus placement, difficulty shaping
- `scripts/procedural_audio.gd` - procedural music and synthesized sound effects
- `assets/fonts/` - bundled UI font assets
