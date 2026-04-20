# Audio & Localization Skill

Own changes in:

- `scripts/procedural_audio.gd`
- `scripts/audio/**`
- `scripts/localization_data.gd`
- `scripts/game/game_persistence.gd`
- audio/localization tests

Typical tasks:

- music generation structure and preset logic
- SFX generation and cache management
- language lists, translated copy, language selection behavior
- persistence of audio/language settings

When editing:

1. Keep DSP/math helpers pure and extracted where possible.
2. Keep localized string keys stable unless the task requires a rename.
3. Validate both headless boot and the dedicated test runner after changes.
