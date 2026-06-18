# Codex Rules

This is a Godot 4.x GDScript project.

SuperHeroes is a Web/Yandex Games survivors-like with an original superhero theme.

## General Rules

- Always inspect the current project before changing files.
- If logic already exists, do not duplicate it.
- If logic is partially implemented, extend it with the smallest safe patch.
- Keep patches small and focused.
- Do not add unrelated systems.
- Do not rewrite broad architecture unless explicitly requested.
- Do not add ads, payments, monetization, leaderboards, saves, or meta-progression unless explicitly requested.
- Keep desktop browser and mobile landscape browser in mind.
- Keep 16:9 and 20:9 support in mind.
- Avoid copyrighted superhero IP; use original superhero concepts only.

## Architecture Separation

Keep these systems separated as the project grows:

- Player movement
- Enemy spawn
- Enemy AI
- Damage system
- XP drops
- Level-up upgrade system
- Active abilities
- UI
- Run state
- Yandex SDK wrapper
- Save/config data

Do not mix:

- Runtime state
- Config data
- UI
- Yandex SDK calls
- Gameplay formulas

## Validation

At minimum, run or document:

```sh
godot --headless --editor --quit
```

## Future Final Summary Format

1. What was already correct and left unchanged.
2. What was changed.
3. Files changed.
4. Validation commands run and results.
5. Manual checks still required.
