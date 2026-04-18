# Maze Point

Maze Point is a colorful score-chasing maze game built with Godot. Each maze gets larger and more complex, and the best runs balance fast routing with bonus pickups so the score stays as close to `0` as possible.

## How to play

Reach the goal marker to clear the maze.

- **Mouse / touch:** click or tap an adjacent connected node to move.
- **Keyboard:** move with **WASD** or the **arrow keys**.
- **Gamepad:** move with the **D-pad** or **left stick**.

Every maze score is based on:

- steps taken,
- time spent past the maze par time,
- minus any collected bonus values.

A perfect run scores **0**.

## UI actions

- **Retry maze:** `R` or gamepad `Y`
- **End run:** `Esc` or gamepad `Start`
- **Continue / Start new run:** `Enter`, `Space`, or gamepad `A`

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

- `scripts/game.gd` - gameplay, UI, input, rendering, scoring
- `scripts/maze_generator.gd` - procedural maze generation and bonuses
- `assets/fonts/` - bundled UI font assets
