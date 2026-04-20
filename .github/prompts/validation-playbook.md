# Validation Playbook

After code changes, run the smallest validation set that proves the change:

- Baseline project boot:
  - `godot --headless --path . --quit`
- Unit/helper suite:
  - `godot --headless --path . --script res://tests/test_runner.gd`

Escalate only when needed:

- Launch the game when the task affects runtime UX, rendering, or interaction flow.
- Launch the game for localization/font fixes that depend on runtime menu rendering or focus behavior, not just text tables.
- Re-run both commands after fixing any validation failure.

Do not finish after a plausible code change without running the relevant validation commands.
Keep the working tree clean after validation: review and discard accidental Godot-generated `.uid` and unrelated `.import` files unless the task explicitly requires them.
