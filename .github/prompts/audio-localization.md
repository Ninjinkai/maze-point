# Audio & Localization Skill

Own changes in:

- `scripts/procedural_audio.gd`
- `scripts/audio/**`
- `scripts/localization_data.gd`
- `scripts/game/game_persistence.gd`
- `scripts/game/game_ui_styles.gd`
- `assets/fonts/**`
- audio/localization tests

Typical tasks:

- music generation structure and preset logic
- SFX generation and cache management
- language lists, translated copy, language selection behavior
- glyph coverage, multilingual font routing, and bundled fallback font assets
- persistence of audio/language settings

When editing:

1. Keep DSP/math helpers pure and extracted where possible.
2. Keep localized string keys stable unless the task requires a rename.
3. Validate both headless boot and the dedicated test runner after changes.
4. Do not rely on host-system fonts alone for CJK coverage when the game needs deterministic rendering; prefer a bundled fallback in `assets/fonts/` when necessary.
5. If a language fix also changes menu focus, directional navigation, or splash rebuild behavior, hand the menu portion to gameplay-ui-agent with the affected files and expected control focus.
