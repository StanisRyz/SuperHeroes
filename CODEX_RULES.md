# Codex rules

SuperHeroes is a Godot 4.5 GDScript survivors-like targeting Web export and landscape browser layouts.

## Working rules

- Inspect the relevant current scene, script, and data provider before editing.
- Prefer a focused extension of an existing system over a duplicate subsystem or broad rewrite.
- Keep configuration/data, runtime state, UI presentation, and persistence separated.
- Do not introduce copyrighted superhero names, brands, logos, or existing characters.
- Do not add monetization, cloud/Yandex storage, online services, or new persistence without an explicit request.
- Keep desktop and mobile landscape use, including 16:9 and wide layouts, in scope.

## Ownership boundaries

- `Main` coordinates front-end and run transitions; `Arena` coordinates an active run.
- Providers own static hero, stage, Training, and equipment definitions. Managers own runtime or saved state.
- UI emits intent and displays state; it must not apply combat, rewards, save writes, or scene changes directly.
- `MetaProgressionManager` is the only owner of persistent progression; `SettingsManager` and `UserPreferencesManager` own their separate files.
- `FeedbackManager` is presentation-only and never applies gameplay effects.

## Required follow-up

- Update [README.md](README.md), [Agents.md](Agents.md), and the relevant manual checks in [docs/validation/gameplay_validation.md](docs/validation/gameplay_validation.md) whenever an implemented behavior or contract changes.
- Run `godot --headless --editor --quit` after code/scene/configuration changes. Documentation-only work should instead verify Markdown links, referenced paths, and the final Git diff.
