# Agent guide: SuperHeroes

## Scope and baseline

SuperHeroes is a Godot 4.5/GDScript survivors-like. The entry scene is `scenes/main/Main.tscn`; it targets desktop and mobile landscape Web builds. This document describes the checked-in architecture, not a feature wish list. Read the affected scene/script and [README.md](README.md) before changing code.

Run this after code, scene, or configuration edits:

```sh
godot --headless --editor --quit
```

Use [docs/validation/gameplay_validation.md](docs/validation/gameplay_validation.md) for the applicable manual flow. Update this file, the README, and that checklist when a public behavior or contract changes.

## Runtime topology

```text
Main.tscn / Main.gd
├─ scene children: settings, audio, user preferences, hero/stage providers, selection UI
├─ dynamically created: meta manager, rewards, briefing, Training shop, collection
└─ one Arena instance per run
   ├─ Player + autoattack + abilities
   ├─ spawner/director/run/upgrade/evolution/powerup managers
   ├─ objectives, events, miniboss/final-boss flow, feedback and debug state
   └─ HUD, pause/modals, mobile controls and result UI
```

- `Main` is the only front-end/run-flow coordinator. It owns selected hero/stage/level and applies the finished run through `MetaProgressionManager`.
- `Arena` coordinates a live run only. It accepts selected data through `setup()`, emits a run summary, and does not write persistent progress.
- Providers own definitions. Managers own mutable runtime state or save state. UI displays state and emits intent; it must not own combat, rewards, saves, or scene replacement.

There are no autoloads in `project.godot`.

## Parallel 3D migration foundation

`scenes3d/` is an isolated source tree for the staged 2D-to-3D migration. In stage 1.3, `scenes3d/game/Arena3D.tscn` is a standalone player, camera, and Knight presentation prototype only: it does not replace `scenes/game/Arena.tscn`, change `run/main_scene`, or connect to 2D gameplay managers, saves, progression, or run flow. Keep the existing 2D game playable throughout early migration stages.

The 3D horizontal-plane convention is XZ: `Vector3.x` and `Vector3.z` map to the game-facing `Vector2.x` and `Vector2.y`. Use `scenes3d/utilities/WorldPlane.gd` for typed conversions rather than duplicating coordinate mapping. `Player3D` is a `CharacterBody3D` with the existing player-facing health, XP, dash, input, and external-movement contracts; use 3D world units (currently 6 units/second in the 40×40 prototype), not 2D pixel tuning. It owns its movement, facing, gravity, and bounds enforcement, not combat managers.

`Arena3D` owns the 3D player spawn, assigns bounds, and connects the target to `CameraRig3D`. `CameraRig3D` has a fixed angled world view and smoothly follows position only; never parent or rotate it with Player3D. Player3D owns only physics and gameplay-facing contracts. `KnightVisual` owns the imported KayKit Knight, its ModelOffset/forward correction, animation player/skeleton discovery, locomotion/one-shots, and `handslot.r` sword plus `handslot.l` shield attachments. Do not place health, XP, input, damage, hit detection, or arena logic in visual scripts.

KnightVisual maps Idle_A and Running_A as looping locomotion clips and Use_Item, Hit_A, Death_A as one-shots. Death has priority and never returns to locomotion. `attack_impact` fires once per Use_Item at the configured normalized time; it is a timing seam for future melee damage, not damage itself. The KayKit Knight's visual forward is +Z and is corrected by ModelOffset, keeping Player3D free of asset-specific configuration. If imported KayKit scene paths change after asset reimport, update only KnightVisual's exported source/node paths and attachment visuals. For isolated controls, enable `prototype_debug_enabled`: J requests attack, K accepts 10 damage/hit, and L accepts lethal damage/death.

The named 3D physics layers are Player, Enemies, PlayerProjectiles, Pickups, EnemyProjectiles, Environment, and Obstacles. They coexist with the unchanged 2D layer names. Player3D is on Player and collides with Environment/Obstacles; its PickupArea detects Pickups. Arena3D's ground is Environment and detects Player. Always use `Main.tscn` for normal-game validation.

## Ownership map

| Area | Owner | Do not move into |
| --- | --- | --- |
| Menu, hero/stage choice, run replacement | `Main.gd` | selection/result UI |
| Active run and modal safety | `Arena.gd` | `Main`, HUD, individual controls |
| Hero definitions / base kit metadata | `HeroDataProvider.gd` | UI or meta save |
| Stage definitions and previews | `StageDataProvider.gd` | `StageSelect` or `Arena` |
| Hero application | `HeroApplier.gd` | `Player` or UI |
| Persistent rewards/progression | `MetaProgressionManager.gd` | Arena or result UI |
| Training and equipment definitions | their data providers | meta save/UI |
| Spawn scaling and variant selection | `SpawnDirector.gd` | `EnemySpawner` |
| Enemy creation, XP and powerup drops | `EnemySpawner.gd` | `SpawnDirector` |
| Run timer, kills and victory eligibility | `RunManager.gd` | HUD/result screens |
| Run upgrades and slot state | `UpgradeManager.gd` | `LevelUpScreen` |
| Triple evolution state/application | `EvolutionManager.gd` | Level-up UI |
| Shared temporary passives | `PassiveAbilityManager.gd` | meta save |
| Active abilities/cooldowns | `AbilityManager.gd` | Player, HUD, mobile controls |
| Objective entities and objective state | `StageObjectiveManager.gd` | HUD |
| Non-gameplay feedback | `FeedbackManager.gd` | combat scripts |

## Key scenes and files

| File | Purpose |
| --- | --- |
| `scenes/main/Main.tscn`, `Main.gd` | Entry point and all front-end/run transitions |
| `scenes/game/Arena.tscn`, `Arena.gd` | Active-run composition and coordination |
| `scenes/game/RunManager.gd` | Run timing, kills, boss/victory state |
| `scenes/player/Player.gd`, `PlayerAutoAttack.gd` | Movement/health/XP and primary weapon behavior |
| `scenes/abilities/AbilityManager.gd` | Three active slots, hero-kit routing, cooldowns |
| `scenes/enemies/EnemySpawner.gd`, `SpawnDirector.gd`, `Enemy.gd` | Spawn/inventory of enemies, pressure, role behavior |
| `scenes/upgrades/UpgradeManager.gd`, `scenes/evolution/EvolutionManager.gd` | Run upgrades, slot grid, triple evolutions |
| `scenes/meta/MetaProgressionManager.gd`, `MetaApplier.gd` | Persistent progression and run-start modifiers |
| `scenes/ui/StageSelect.gd`, `RunBriefingScreen.gd` | Stage/level choice and display-only briefing |
| `scenes/objectives/StageObjectiveManager.gd` | Survival, defense, and portal objective integration |
| `scenes/enemies/FinalBossController.gd` | Final boss encounter state and attacks |

## Persistence and compatibility

Keep these stores separate:

| Path | Owner | Contents |
| --- | --- | --- |
| `user://settings.cfg` | `SettingsManager` | Settings only |
| `user://superheroes_user_preferences.json` | `UserPreferencesManager` | Last hero/stage choices only |
| `user://superheroes_meta_progress.json` | `MetaProgressionManager` | Gameplay progression, inventory, Training, mastery, goals, stage progress |

`MetaProgressionManager.SAVE_VERSION` is 7. Preserve migration and compatibility behavior unless a task explicitly changes the save format. Call `MetaProgressionManager.apply_run_result(summary)` only from the run-completion flow; neither Arena nor display screens should award or save results directly. Run-only upgrades, passives, buffs, evolutions, debug state, and temporary currencies must not be persisted.

Training is hero-specific; equipment is shared/global. Apply progression in the existing order: hero data first, then `MetaApplier`. Do not let another hero's Training affect the selected hero.

## Gameplay contracts

- The live front-end chain is Main Menu → Character Select → Stage Select → Run Briefing → Arena.
- `StageSelect` is the only stage/zone selection screen. Do not create `ZoneSelect` or a duplicate zone provider.
- Stage level data is UI preview data only until a scoped scaling implementation changes that contract.
- Player damage follows `Player.take_damage()`; miniboss/final-boss damage must use it or existing enemy-projectile collision.
- `RunManager` controls victory eligibility. Stage objectives may trigger the final boss and call `mark_boss_phase_triggered()` to suppress duplicate timer triggers.
- `SpawnDirector` contains difficulty and wave formulas; `EnemySpawner` contains safe position selection and instancing.
- Enemy variants are dictionaries, not Resource assets.
- `EvolutionManager` owns 27 current triples (9 per hero); UI only offers/visualizes choices.
- `DebugManager` owns debug state. Debug actions remain gated by debug mode; overlays are read-only.
- `FeedbackManager` routes feedback and respects settings. It never applies damage, buffs, state transitions, or saves.

## UI rules

- `GameHUD`, `DebugStatsOverlay`, result screens, `BuildSlotsWindow`, `HeroCollectionScreen`, and `RunBriefingScreen` are display-only.
- `MobileControls` emits movement/ability/pause/build intents. Arena wires the intents; the control must not mutate gameplay directly.
- `Main` owns transitions outside a run; `Arena` owns transitions during a run. `VictoryScreen`/`GameOverScreen` request actions through signals only.
- Use `UIFormat`, `UIStateColors`, and `EquipmentFormat` for their existing display domains rather than duplicating display strings or colors.
- Equipment interactions remain in `MetaUpgradeShop`: item actions require the existing confirmation flow for Dismantle. Do not bypass locked/equipped protections.

## Input, platform, and export

- Movement: WASD/arrows; abilities: J/K/L; dash: Space; pause: Escape; help: H/F11.
- Debug mode and its actions are project input actions and must not affect normal play while disabled.
- Preserve 1280×720 canvas-item stretch/expand behavior and landscape Web usability.
- The checked-in `Web` export preset writes to `export/index.html`. No Yandex SDK, cloud storage, paid services, or custom Web template is present.

## Known debt and limitations

- `scenes/game/EventDirector.tscn` is the active Arena child. `scenes/events/EventDirector.gd` is a dynamically loaded fallback only if that child is absent. Their schedules differ; do not assume they are interchangeable. Consolidation is a separate code task.
- The stage-level preview exposes enemy/loot multipliers without applying them to runtime combat or reward formulas.
- Legacy inventory/meta APIs coexist with the current inventory/Dismantle UI. Preserve callers during scoped changes.

## Change discipline

- Keep changes small, local, and source-backed. Do not add unrelated systems, duplicate managers, or broad refactors.
- Do not add persistence, monetization, cloud/Yandex services, online features, arena hazards, input remapping, audio assets, or new enemy types unless explicitly requested.
- Avoid copyrighted superhero IP.
- Preserve pause cleanup, signal disconnection/validity checks, and UI display-only boundaries.
- After changes, inspect `git diff` and confirm changed files match the task. Do not commit unless explicitly asked.
