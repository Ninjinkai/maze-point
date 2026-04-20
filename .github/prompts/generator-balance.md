# Generator & Balance Skill

Own changes in:

- `scripts/maze_generator.gd`
- `scripts/generator/**`
- `scripts/game/game_progression.gd`
- generator/progression tests

Typical tasks:

- path variety heuristics
- board size/profile progression
- exact-total puzzle solvability and optimal-route uniqueness
- return-model cleanup and helper extraction

When editing:

1. Keep generation deterministic for a given seed.
2. Favor pure helpers and testable value objects.
3. Add or update tests when heuristics or return shapes change.
