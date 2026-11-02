# Repository conventions

- Keep all project-owned text files ASCII-only, including source code, comments, documentation, configuration, and scripts. Use `F Prime` for the framework name.
- Third-party submodules and generated build artifacts are outside this rule; do not modify upstream code merely to conform.
- Preserve binary files as binary. Check project-owned text for non-ASCII characters before finishing changes.
- Preserve the owner's words, casual tone, and existing explanations. Make focused edits instead of rewriting their prose. Do not present an assistant's suggestions or invented opinions as the owner's decisions.

## Working and learning

- Help complete the work efficiently, while supporting the owner's goal of learning RTL and the hardware/software boundary. The owner chooses what to learn and when to practice.
- For important design choices, briefly explain the intended behavior, consequential assumptions, supporting evidence, and what has not been checked. Give timing, state, hardware interfaces, and failure behavior the attention the task needs.
- Keep routine work direct. When the owner asks to practice, let them make a prediction or try a small part first, offer hints as requested, and compare the result with evidence. Do not quiz them or withhold answers by default.
- Check important behavior against evidence independent of the implementation where practical. Distinguish simulation, source review, successful builds, and measurements on hardware; never present one as proof of another.
- Prefer small, useful changes. Do not add infrastructure or process without a concrete need. Keep the approach flexible as the project and the owner's interests change.
