# Handoff Discipline

Keep context narrow:

1. Start with one component agent.
2. If a request crosses domains, hand off only the minimum contract needed.
3. Do not reread the entire repo in every agent.
4. Summarize touched files, changed contracts, and required validation when handing off.

Recommended routing:

- gameplay visuals / menus / input -> gameplay-ui-agent
- puzzle logic / difficulty / solver -> generator-balance-agent
- audio / localization / related persistence -> audio-localization-agent
- tests / workflows / developer setup -> validation-release-agent

Recent boundary lessons:

- A localization bug can still belong partly to gameplay-ui-agent if the root cause is menu focus, splash rebuild ordering, or directional control handling in `scripts/game.gd`.
- A font bug can still belong partly to audio-localization-agent if the fix lives in `scripts/game/game_ui_styles.gd`, `scripts/localization_data.gd`, or bundled assets under `assets/fonts/`.
- When handing off localization work, explicitly state whether the unresolved risk is glyph coverage, text data, persistence, or menu interaction behavior.
