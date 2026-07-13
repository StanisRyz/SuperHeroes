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

`scenes3d/` is a parallel source tree for the staged 2D-to-3D migration. `scenes3d/game/Arena3D.tscn` does not replace `scenes/game/Arena.tscn` or `run/main_scene`: `Main` selects it only for legacy hero ID `vanguard`, while `guardian` and `blaster` stay on the 2D Arena. Keep those 2D paths playable throughout early migration stages. Arena3D accepts the standard `setup(settings, audio, hero, meta, stage)` contract and emits `run_result_ready(summary)`, `restart_run_requested`, and `quit_to_menu_requested`; Main remains the sole owner of rewards, restart cleanup, and menu transitions.

The 3D horizontal-plane convention is XZ: `Vector3.x` and `Vector3.z` map to the game-facing `Vector2.x` and `Vector2.y`. Use `scenes3d/utilities/WorldPlane.gd` for typed conversions rather than duplicating coordinate mapping. `Player3D` is a `CharacterBody3D` with the existing player-facing health, XP, dash, input, and external-movement contracts; use 3D world units (currently 6 units/second in the 40×40 prototype), not 2D pixel tuning. It owns its movement, facing, gravity, and bounds enforcement, not combat managers.

`Arena3D` owns the 3D player spawn, assigns bounds, and connects the target to `CameraRig3D`. `CameraRig3D` has a fixed angled world view and smoothly follows position only; never parent or rotate it with Player3D. Player3D owns only physics and gameplay-facing contracts. `KnightVisual` owns the imported KayKit Knight, its ModelOffset/forward correction, animation player/skeleton discovery, locomotion/one-shots, and `handslot.r` sword plus `handslot.l` shield attachments. Do not place health, XP, input, damage, hit detection, or arena logic in visual scripts.

KnightVisual maps Idle_A and Running_A as looping locomotion clips and Hit_A/Death_A as one-shots. It loads `Rig_Medium_CombatMelee` through `KayKitAnimatedVisual.additional_animation_sources` and maps `Melee_1H_Attack_Slice_Diagonal` for the Knight attack. `KnightMeleeAutoAttack3D` owns nearest-target selection, attack cooldown, XZ radius/arc dot-product hits, single impact damage, and knockback. It locks Player3D's visual-facing direction for the attack and releases it after the animation while movement continues. Do not put attack targeting or damage in the visual script.

`KayKitAnimatedVisual` owns shared imported-animation discovery, skeleton discovery, loop setup, and cached animation libraries. Concrete visual scenes own only their model, ModelOffset, animation mapping, and equipment. `SkeletonWarriorVisual` uses `Skeleton_Warrior.glb` on `Rig_Medium`, maps Idle_A/Running_A/Use_Item/Hit_A/Death_A, corrects its +Z-facing visual in ModelOffset, and attaches `Skeleton_Blade.gltf` to `handslot.r`. Animation tracks remain under visual descendants and must never move the owning CharacterBody3D.

`Enemy3D` owns health, chase-only XZ motion, gravity, visual facing, contact attack cooldown, knockback, and death lifecycle. It is on Enemies, collides physically with Environment/Obstacles only, exposes a future Enemies Hurtbox, and stops contact/movement at death. Its contact attack starts the visual one-shot and damages Player3D only at that visual's single `attack_impact` while the target remains in range. Do not add navigation, special behavior IDs, elite/miniboss/boss systems, or attack hit detection in this migration stage.

`Arena3D` configures the existing RunManager before `SpawnDirector.setup(run_manager)` and passes that same manager to EnemySpawner3D before `start_spawning()`. EnemySpawner3D owns safe instancing, ring-position selection, alive counting, target assignment, death wiring, XP pickup creation, and explicit start/stop spawning timers. It registers one RunManager kill per Enemy3D death; terminal death/victory stops spawning. It must query the existing SpawnDirector for interval, caps, variants, and wave packages; never copy its policy. ExperiencePickup3D preserves its configured global hover height. `EnemyVariant3DAdapter` converts director speeds with `40 pixels = 1 world unit` and deliberately forces unsupported behavior IDs to chase while preserving their source id.

The 3D run is a 75-second no-boss survival slice. Arena3D owns its wired `GameHUD`, `LevelUpScreen`, `EvolutionRewardScreen`, `GameOverScreen`, `VictoryScreen`, `PauseMenu`, and `MobileControls`; these remain display/input intent surfaces. `RunUpgradeManager3D` is run-local and covers sword, movement/health, Rage, and all Knight ability lines. Normal three-option selection prefers one `attack`, one `active`, and one `passive` option, then fills from remaining categories without duplicates or max-level entries. Do not port the 2D upgrade grid, bosses, or other hero paths until explicitly scoped.

Arena3D startup order is world, gameplay, critical run/input signal wiring, input reset, optional UI configuration, then spawning. Optional UI setup must be guarded with node/method/signal checks and must never prevent player movement, dash, pause, or run lifecycle signals. Player3D reads keyboard movement each physics frame; keyboard has priority, and the external MobileControls vector is only the fallback. Reset external/mobile movement when the arena starts, pauses, resumes, and ends.

Arena3D uses always-processing only for global Pause input. Its PlayerContainer, CameraRig3D, Managers, EnemyContainer, PickupContainer, and EffectContainer must be explicitly `PROCESS_MODE_PAUSABLE`, because inherited processing from the always-processing arena would otherwise keep the 3D run live during a modal. Escape and the mobile Pause button use the same toggle, reset the joystick/mobile vector, and open PauseMenu above normal run UI. Canvas layer order is HUD, mobile controls, pause, level-up, then terminal screens. Decorative full-screen controls must use `MOUSE_FILTER_IGNORE`; hidden overlays must not intercept input. Main must unpause and close hidden menu overlays before showing MainMenu, and connect a newly instantiated arena's result/restart/menu signals before adding it to the tree.

Stage 1.6 uses `KnightAbilityManager3D`, not the 2D AbilityManager, for Rage and active ability cooldowns. It owns Rage signals, ActionController-based readiness/blocked reasons, Rage Wave area slow, Shield Bash cone/knockback, and Crushing Leap landing logic. Rage Wave and Leap use expanding XZ ground rings; Bash uses an XZ sector built from its full cone angle and exact gameplay range. Each effect has an independent unshaded alpha `StandardMaterial3D` and Web-compatible fade. Player3D scripted motion must move through CharacterBody3D physics, honor bounds/collision, and cancel at terminal state. Enemy3D temporary modifiers refresh by ID and recalculate effective speed/contact damage without mutating base variant values. Arena3D republishes Knight ability state immediately after Level Up/Pause pause-state transitions, while the generic HUD and MobileControls preserve legacy 2D support for ability states that do not include a slot field; MobileControls only emits ready intents. ActionController, ability, autoattack, and visual debug snapshots are read-only; the action tracer is disabled in release/Web before opening files or processing input. Ability lines are active upgrades, Rage lines are passive.

Stage 1.7.1 adds a separate, run-local `EvolutionManager3D`, never the legacy 2D EvolutionManager. Worldbreaker uses Sword Arc (attack), Burning Rage (passive), and Wide Wave (active); Rampage Impact uses Sword Knockback, Furious Edge, and Heavy Bash; Meteor Crash uses Sword Damage, Smoldering Rage, and Leap Force. Each evolution is locked/partial/ready/selected from exactly those three line levels, using each line's maximum as the default required level. Arena3D checks after every accepted Level Up, keeps the world paused for `EvolutionRewardScreen`, and then continues the next Level Up or resumes. The HUD and run summary expose only selected run-local evolution IDs/titles.

Stage 1.7.2 marks Worldbreaker as implemented and reward-offerable. `KnightAbilityManager3D.apply_evolution()` activates supported evolutions run-locally and rejects placeholder IDs. Worldbreaker replaces Rage Wave's standard impact with three independent pulses at the original cast origin: 0.0s (1.0× radius, 1.5× base damage, 7.0 knockback), 0.22s (1.45×, 1.25×, 8.5), and 0.44s (1.9×, 1.0×, 10.0). Pulses reuse Rage scaling and upgrades, refresh a 0.40 speed slow for 2.5 seconds, and render `WorldbreakerPulseEffect3D`.

Stage 1.7.3 marks Rampage Impact as implemented and reward-offerable with Sword Knockback, Furious Edge, and Heavy Bash prerequisites unchanged. It replaces standard Shield Bash with a primary cone of 1.75× Bash damage, 1.35× range, 1.35× full angle capped at 120°, 1.80× knockback, and a 0.35 speed stagger for 1.2s. Its stored-origin/direction second cone follows at 0.28s with 1.00× Bash damage, 0.85× primary range, the same full angle, and 1.25× Bash knockback. `RampageImpactEffect3D` is presentation-only and uses exact gameplay range/angle. Worldbreaker values remain unchanged.

Stage 1.7.4 marks Meteor Crash as implemented and reward-offerable with Sword Damage, Smoldering Rage, and Leap Force prerequisites unchanged. It branches only at the actual end of Player3D scripted Leap movement: primary impact is 2.00× Leap damage, 1.50× radius, 12.0 radial knockback for 0.30s, and a stable 1.25s stun. Its landing-position aftershock queues for 0.35s at 1.00× Leap damage, 0.80× primary radius, 8.0 knockback for 0.24s, and a 0.30 speed slow for 1.8s. `KnightAbilityManager3D` uses one deterministic, pausable evolution-impact queue for Worldbreaker, Rampage, and Meteor events; it resolves by sequence, clears on stop/scene cleanup, and never retains action tokens. `MeteorCrashImpactEffect3D` is presentation-only. All three Knight evolutions now preserve normal Rage scaling, cooldowns, and ability lifecycle; balance and polish remain scoped to Stage 1.7.5.

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
