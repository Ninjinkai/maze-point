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
