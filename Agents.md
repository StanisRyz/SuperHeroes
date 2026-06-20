# Agents.md

## Project

SuperHeroes is a Godot 4.x GDScript project for Web / HTML5, with Yandex Games integration planned later.

The game is an original superhero survivors-like: the player moves around an arena, enemies chase the player, defeated enemies drop XP gems, and future milestones will add upgrades and active abilities.

## Important Files

- `scenes/main/Main.tscn` - project entry scene.
- `scenes/main/Main.gd` - frontend flow coordinator, character select transition, and run scene replacement.
- `scenes/heroes/HeroDataProvider.tscn` - runtime hero definition provider scene.
- `scenes/heroes/HeroDataProvider.gd` - dictionary-backed Guardian / Blaster / Vanguard definitions.
- `scenes/heroes/HeroApplier.gd` - run-only helper for applying selected hero stats to Player, AutoAttack, and AbilityManager.
- `scenes/evolution/EvolutionManager.tscn` - runtime evolution manager scene.
- `scenes/evolution/EvolutionManager.gd` - evolution definitions, prerequisites, effects, and applied run state.
- `scenes/settings/SettingsManager.tscn` - local settings manager scene.
- `scenes/settings/SettingsManager.gd` - `user://settings.cfg` load/save helper for settings only.
- `scenes/preferences/UserPreferencesManager.tscn` - local non-gameplay user preferences manager scene.
- `scenes/preferences/UserPreferencesManager.gd` - JSON preference save/load helper for remembered hero/stage choices.
- `scenes/audio/AudioManager.tscn` - audio playback manager scene.
- `scenes/audio/AudioManager.gd` - volume/mute application and optional SFX playback hooks.
- `scenes/debug/DebugManager.tscn` - runtime-only debug state manager scene.
- `scenes/debug/DebugManager.gd` - debug mode state and debug signals.
- `scenes/debug/ProjectHealthCheck.gd` - one-time Arena startup wiring checker; prints concise warnings only for missing critical nodes.
- `scenes/game/Arena.tscn` - arena composition.
- `scenes/game/Arena.gd` - arena bounds, player setup, spawner setup, level-up flow, run lifecycle.
- `scenes/game/GameplayTuning.tscn` - central exported gameplay tuning node instanced under Arena.
- `scenes/game/GameplayTuning.gd` - applies safe balance/logging defaults to existing Arena systems.
- `scenes/game/RunManager.tscn` - runtime run state manager scene.
- `scenes/game/RunManager.gd` - run timer, kill counter, and run end signal. Exposes `mark_boss_phase_triggered()` so StageObjectiveManager can prevent the timer from re-triggering the boss phase after an objective-driven trigger.
- `scenes/abilities/AbilityManager.tscn` - player active ability manager scene (3 slots wired).
- `scenes/abilities/AbilityManager.gd` - 3-slot active ability logic, hero-kit routing, legacy Nova/Laser/Slam tuning hooks, cooldown tracking, cast signals.
- `scenes/abilities/NovaPulseFeedback.tscn` - simple in-world Nova Pulse feedback scene.
- `scenes/abilities/NovaPulseFeedback.gd` - Nova Pulse feedback tween and cleanup logic.
- `scenes/abilities/NovaAftershockFeedback.tscn` - delayed Nova aftershock feedback scene.
- `scenes/abilities/NovaAftershockFeedback.gd` - aftershock ring tween and cleanup logic.
- `scenes/abilities/LaserBeamFeedback.tscn` - in-world Laser Beam feedback scene (built-in Line2D).
- `scenes/abilities/LaserBeamFeedback.gd` - Laser Beam feedback fade tween and cleanup logic.
- `scenes/abilities/HeroSlamFeedback.tscn` - in-world Hero Slam feedback scene (built-in ring Line2D).
- `scenes/abilities/HeroSlamFeedback.gd` - Hero Slam expanding ring tween and cleanup logic.
- `scenes/ui/FloatingText.tscn` - simple world-space floating text feedback scene.
- `scenes/ui/FloatingText.gd` - floating text tween and cleanup logic.
- `scenes/ui/FloatingTextSpawner.tscn` - utility node for spawning floating feedback text.
- `scenes/ui/FloatingTextSpawner.gd` - damage and pickup text display helper.
- `scenes/effects/DeathBurst.tscn` - simple enemy death burst feedback scene.
- `scenes/effects/DeathBurst.gd` - death burst tween and cleanup logic.
- `scenes/effects/HitSpark.tscn` - simple projectile hit feedback scene.
- `scenes/effects/HitSpark.gd` - hit spark tween and cleanup logic.
- `scenes/effects/DashBurst.tscn` - simple dash burst feedback scene.
- `scenes/effects/DashBurst.gd` - dash burst tween and cleanup logic.
- `scenes/pickups/ExperienceGem.tscn` - XP pickup scene.
- `scenes/pickups/ExperienceGem.gd` - XP pickup collection logic.
- `scenes/projectiles/PlayerProjectile.tscn` - player autoattack projectile scene.
- `scenes/projectiles/PlayerProjectile.gd` - projectile movement, lifetime, enemy hit damage, pierce, explosion, and bounce logic.
- `scenes/projectiles/EnemyProjectile.tscn` - enemy projectile scene.
- `scenes/projectiles/EnemyProjectile.gd` - non-homing enemy projectile damage and lifetime logic.
- `scenes/upgrades/UpgradeManager.tscn` - runtime upgrade manager scene.
- `scenes/upgrades/UpgradeManager.gd` - hardcoded upgrade definitions, option weighting, upgrade levels, passive upgrade definitions, and application logic.
- `scenes/ui/GameHUD.tscn` - player HP, XP, time, and kill counter HUD scene.
- `scenes/ui/GameHUD.gd` - player and run HUD binding. `setup_objective_manager(obj_manager, objective_type)` wires objective state; `update_objective_state(state)` renders defense HP or portal count; `_update_objective()` skips the survival timer when objective_type is non-survival.
- `scenes/ui/MobileControls.tscn` - mobile virtual joystick and 3 ability buttons scene; Pause and Build buttons stay visible for desktop/mobile run UI.
- `scenes/ui/MobileControls.gd` - mobile movement and ability button signal source (ability_1/2/3_pressed), plus pause_pressed and build_slots_pressed intent signals.
- `scenes/ui/BuildSlotsWindow.tscn` - in-run read-only Build Slots window CanvasLayer.
- `scenes/ui/BuildSlotsWindow.gd` - display-only slot overview; reads UpgradeManager slot state and definition summaries, shows 4 Attack / 4 Passive / 4 Active rows, emits closed.
- `scenes/ui/MainMenu.tscn` - frontend main menu scene.
- `scenes/ui/MainMenu.gd` - main menu start, settings, training, help, and quit intent signals.
- `scenes/ui/ControlsHelpOverlay.tscn` - reusable help and controls CanvasLayer scene.
- `scenes/ui/ControlsHelpOverlay.gd` - display-only help overlay API (`open`, `close`, `toggle`, `is_open`) and close handling.
- `scenes/ui/ControlsHelpContent.gd` - centralized help content sections.
- `scenes/ui/ConfirmDialog.tscn` - reusable pause-safe confirmation CanvasLayer scene for active-run destructive actions.
- `scenes/ui/ConfirmDialog.gd` - display-only confirmation dialog API (`open`, `close`, `is_open`, `get_action_id`) and confirmed/cancelled action-id signals.
- `scenes/ui/CharacterSelect.tscn` - hero selection screen between MainMenu and Arena.
- `scenes/ui/CharacterSelect.gd` - display-only hero list/details UI; emits selected hero id.
- `scenes/ui/RunBriefingScreen.tscn` - display-only run briefing screen between StageSelect and Arena.
- `scenes/ui/RunBriefingScreen.gd` - shows selected hero/stage, ability names, Training summary, objective, and final boss preview; emits start_requested/back_requested only.
- `scenes/ui/EvolutionRewardScreen.tscn` - paused evolution reward choice screen.
- `scenes/ui/EvolutionRewardScreen.gd` - display-only evolution option UI; emits selected evolution id.
- `scenes/ui/PauseMenu.tscn` - pause-time run menu scene.
- `scenes/ui/PauseMenu.gd` - pause menu resume, settings, help, restart, and quit intent signals.
- `scenes/ui/SettingsMenu.tscn` - pause-capable settings menu scene.
- `scenes/ui/SettingsMenu.gd` - settings UI binding for volume, mobile controls, and screen shake.
- `scenes/ui/DebugOverlay.tscn` - simple DEBUG ON overlay scene.
- `scenes/ui/DebugOverlay.gd` - debug overlay visibility binding.
- `scenes/ui/LevelUpScreen.tscn` - pause-time upgrade selection UI.
- `scenes/ui/LevelUpScreen.gd` - displays options and emits selected upgrade IDs.
- `scenes/ui/GameOverScreen.tscn` - pause-time game over UI.
- `scenes/ui/GameOverScreen.gd` - displays run stats and emits restart requests.
- `scenes/player/Player.tscn` - player scene with camera.
- `scenes/player/Player.gd` - movement, bounds clamp, health state.
- `scenes/player/PlayerAutoAttack.gd` - autoattack range tracking and periodic enemy damage.
- `scenes/enemies/Enemy.tscn` - enemy scene and contact damage area.
- `scenes/enemies/Enemy.gd` - chase movement, enemy health, contact damage.
- `scenes/enemies/SpawnDirector.tscn` - time-based spawn progression scene.
- `scenes/enemies/SpawnDirector.gd` - dynamic spawn settings and enemy variant selection.
- `scenes/enemies/EnemySpawner.tscn` - timer-based spawner scene.
- `scenes/enemies/EnemySpawner.gd` - spawn loop, spawn distance checks, max alive enemy limit, XP drops, powerup drop rolls.
- `scenes/player/PlayerBuffManager.tscn` - player buff manager scene.
- `scenes/player/PlayerBuffManager.gd` - timed buffs (move speed, attack speed) and shield charges.
- `scenes/passives/PassiveAbilityManager.gd` - runtime-only shared passive skill manager. Owns selected passive ids/levels, shield regeneration, shield/drone visuals, periodic visible passive attacks, magnet reach bonus, debug state, and cleanup. Never saves passive state.
- `scenes/powerups/PowerupManager.tscn` - powerup manager scene.
- `scenes/powerups/PowerupManager.gd` - applies powerup effects (heal, shield, bomb, magnet burst, speed boosts).
- `scenes/pickups/PowerupPickup.tscn` - generic in-run powerup pickup scene.
- `scenes/pickups/PowerupPickup.gd` - magnet movement and delegation to PowerupManager on collection.
- `scenes/effects/BombBurst.tscn` - bomb burst radius visual effect scene.
- `scenes/effects/BombBurst.gd` - expanding ring tween and cleanup logic.
- `scenes/game/EventDirector.tscn` - event director scene.
- `scenes/game/EventDirector.gd` - timed event schedule, elite/miniboss spawn signals, and active timed event tracking.
- `scenes/ui/EventAnnouncement.tscn` - event announcement overlay scene.
- `scenes/ui/EventAnnouncement.gd` - fade-in/out label announcement for run events.
- `scenes/ui/MinibossHealthBar.tscn` - miniboss health bar overlay scene.
- `scenes/ui/MinibossHealthBar.gd` - tracks a miniboss enemy and displays its name, HP bar, and HP text.
- `scenes/enemies/MinibossAttackController.tscn` - miniboss combat brain scene (Node root).
- `scenes/enemies/MinibossAttackController.gd` - owns miniboss attack timing, attack selection, nova/barrage/charge execution, 2-phase logic, and phase_changed signal.
- `scenes/effects/AttackTelegraph.tscn` - short-lived visual warning zone scene (Node2D root).
- `scenes/effects/AttackTelegraph.gd` - plays circle or line danger zone using dynamically created Line2D; fades/pulses and queue_frees; never applies damage.
- `scenes/ui/DebugStatsOverlay.tscn` - minimal CanvasLayer root scene for the debug stats panel; all UI built programmatically in _ready().
- `scenes/ui/DebugStatsOverlay.gd` - live debug stats panel: player HP/level/XP/speed/dash, weapon stats, ability cooldowns/damage/synergy flags, build archetype/points/synergies/build-defining picks, passive ids/levels/timers, buff/shield state, spawner wiring. Refreshes every 0.25s while visible. Display-only; never mutates gameplay state.
- `scenes/ui/VictoryScreen.tscn` - pause-time victory UI scene.
- `scenes/ui/VictoryScreen.gd` - displays run summary on victory and emits restart_requested / quit_to_menu_requested.
- `scenes/meta/MetaProgressionManager.tscn` - persistent meta manager node scene (instantiated at runtime by Main).
- `scenes/meta/MetaProgressionManager.gd` - owns soft currency, meta upgrade levels, hero unlock state, lifetime stats, and save/load to user://superheroes_meta_progress.json. Calculates and applies run rewards. Never called directly by Arena.
- `scenes/meta/MetaApplier.gd` - static helper; applies purchased meta bonuses to Player, AutoAttack, and pickup_radius_bonus. Called by Arena after HeroApplier at run start.
- `scenes/ui/PostRunRewardsScreen.tscn` - post-run reward display CanvasLayer scene (instantiated at runtime by Main).
- `scenes/ui/PostRunRewardsScreen.gd` - display-only reward breakdown screen. Emits continue_requested. Shown between V/GO result screen and the next action (restart or menu).
- `scenes/ui/MetaUpgradeShop.tscn` - meta upgrade shop CanvasLayer scene (instantiated at runtime by Main).
- `scenes/ui/MetaUpgradeShop.gd` - display-only Training shop UI. Shows meta upgrade levels and costs. Emits buy_requested; Main handles the purchase. Accessed via "Training" button on MainMenu.
- `docs/validation/gameplay_validation.md` - manual test checklist for all gameplay systems (debug keys, powerups, abilities, weapon upgrades, build archetypes, miniboss, run flow, run victory, meta progression/rewards, expected console log patterns).
- `scenes/stages/StageDataProvider.tscn` - runtime stage definition provider scene.
- `scenes/stages/StageDataProvider.gd` - dictionary-backed City Rooftop / Neon Lab / Wasteland Gate stage presets. Returns stage dicts with id, display_name, difficulty_label, display-only identity metadata, background_colors, run_settings, event_profile, final_boss_id, `objective_type` ("survival"/"defense"/"destroy_structures"), and `objective_data` (per-type parameters).
- `scenes/objectives/StageObjectiveManager.gd` - central objective controller; instantiated at runtime by Arena; reads stage_data.objective_type and .objective_data; spawns DefenseObjective or PortalObjective × N; tracks progress; emits `objective_completed`, `objective_failed`, `objective_state_changed`.
- `scenes/objectives/DefenseObjective.gd` - Node2D Lab Reactor structure for "defense" stages; has a Polygon2D visual and HP label; Area2D (collision_mask=2) accumulates contact damage from nearby enemies at `damage_per_enemy_per_second`; emits `health_changed` and `objective_destroyed`.
- `scenes/objectives/PortalObjective.gd` - StaticBody2D Dark Portal for "destroy_structures" stages; collision_layer=2 (enemy layer) so existing player projectiles and autoattack Area2Ds detect it naturally; added to "enemies" group; implements `take_damage(amount)`; emits `portal_destroyed` and `health_changed`.
- `scenes/stages/StageApplier.gd` - static helper; applies selected stage to Arena at startup: background colors, run settings, event/spawn profiles. Called by Arena._ready() when stage_data is non-empty.
- `scenes/ui/StageSelect.tscn` - stage selection screen CanvasLayer scene (child of Main).
- `scenes/ui/StageSelect.gd` - display-only stage list + bounded scrollable detail panel UI. Emits the original stage_confirmed(stage_id) and back_requested.
- `scenes/enemies/FinalBossController.tscn` - final boss combat brain scene (Node root).
- `scenes/enemies/FinalBossController.gd` - owns final boss attack timing (Nova/Barrage/Charge), 2-phase logic, boss_id variant stats, phase_changed signal. Attached dynamically as child of boss enemy on spawn.
- `scenes/ui/BossHealthBar.tscn` - final boss health bar overlay scene (CanvasLayer layer=9).
- `scenes/ui/BossHealthBar.gd` - tracks a final boss enemy; shows "FINAL BOSS", name, HP bar, HP text. Positioned below MinibossHealthBar.
- `scenes/ui/UIFormat.gd` - display formatting helpers (RefCounted, static methods only): format_time, format_cooldown, format_percent, format_list, format_title_id. No gameplay logic.
- `scenes/ui/UIStateColors.gd` - color state helpers (RefCounted, static methods only): ready_color, cooldown_color, warning_color, danger_color, muted_color, positive_color, boss_color, final_phase_color. Built-in Color values only; no external assets.
- `scenes/feedback/FeedbackManager.tscn` - central feedback manager scene (Node root).
- `scenes/feedback/FeedbackManager.gd` - non-gameplay feedback router: show_damage, show_heal, show_powerup, show_status, show_announcement, shake, flash_node. Respects SettingsManager for shake/floating-text/impact-flash toggles. Contains per-frame throttle cap for floating text spam. Arena instantiates and wires it at startup. Never applies damage or owns gameplay state.

## Miniboss Combat Architecture

- `EventDirector` schedules the miniboss event and signals `EnemySpawner` to spawn it.
- `EnemySpawner.spawn_miniboss_enemy()` creates the base enemy, applies the miniboss modifier, emits `miniboss_spawned`, then calls `_attach_miniboss_controller()`.
- `_attach_miniboss_controller()` instantiates `MinibossAttackController`, calls `setup(enemy, player, projectile_container)`, and adds the controller as a child of the enemy so it is freed automatically on miniboss death.
- `Enemy.gd` remains responsible for base movement, health, contact damage, and the new `set_velocity_override` / `clear_velocity_override` methods used by the charge attack.
- `MinibossAttackController` owns all miniboss-only attack timing: picks randomly from Nova, Barrage, and Charge each cycle; respects `_stopped` flag so it halts when the enemy dies.
- `AttackTelegraph` shows danger zones for Nova (circle) and Charge (line); it never applies damage and always queue_frees after its animation.
- Phase 2 begins at ≤50% HP: `phase_changed(2)` → EnemySpawner emits `miniboss_phase_changed(2)` → Arena shows "Miniboss Enraged!" announcement.
- Miniboss death → `_on_enemy_died` emits `miniboss_defeated` → Arena shows "Miniboss Defeated!" announcement.
- All miniboss damage goes through `Player.take_damage()` or existing `EnemyProjectile` collision logic, so dash/debug/shield invulnerability protections are always respected.
- Timers use `get_tree().create_timer()` with default `process_always=false`, so attacks pause naturally with tree pause.

## Event Director System Architecture

- `EventDirector` owns the run event schedule and fires signals when events trigger.
- Arena wires `EventDirector.setup(run_manager)` and connects all event signals.
- Timed events (`type: "timed"`) call `SpawnDirector.apply_event_modifier(event_data)` on start and `clear_event_modifier(event_id)` on finish.
- Elite events (`type: "elite"`) call `EnemySpawner.spawn_elite_enemy(event_data)`.
- Miniboss events (`type: "miniboss"`) call `EnemySpawner.spawn_miniboss_enemy(event_data)`.
- `EventAnnouncement` shows a fade-in/out announcement label when an event with a non-empty announcement text starts.
- `MinibossHealthBar` is wired by Arena to `EnemySpawner.miniboss_spawned` and calls `track_enemy(enemy)`.
- Elite and miniboss enemies are spawned using the normal variant then `apply_special_modifier()` applies stat multipliers, color overrides, and flags.
- Elite and miniboss enemies always drop a powerup pickup on death (guaranteed drop).
- SpawnDirector reads `active_event_modifiers` in `get_spawn_interval`, `get_max_alive_enemies`, and `get_enemy_variant`.

## Powerup Wiring Notes

- `EnemySpawner.tscn` MUST assign `powerup_pickup_scene` — the original bug was this assignment missing, causing all powerup drops to silently return early.
- `PowerupManager.tscn` MUST assign `bomb_burst_scene` for the bomb visual to work.
- `PowerupPickup` detects the player via `body_entered`; its `collision_mask` must include the player layer (layer 1). `collision_layer = 0` is correct.
- `POWERUP_WIRING`, `POWERUP_ROLL`, `POWERUP_SPAWNED` diagnostics are available through `EnemySpawner.powerup_debug_logging`; keep the diagnostics, but leave verbose logging off by default.
- `EnemySpawner.debug_spawn_powerup(powerup_id)` can be called from the Godot remote console or editor to spawn a powerup pickup near the player without waiting for an enemy death.
- Powerup drops silently fail if scene/manager/container are missing; diagnostics reveal which dependency is absent.

## Powerup System Architecture

- `ExperienceGem` remains XP-only; it exposes `force_magnet_to_player(player)` for magnet burst but does not apply powerup effects.
- `PowerupPickup` is generic — it stores a `powerup_id` and delegates all gameplay effects to `PowerupManager.apply_powerup()`.
- `PlayerBuffManager` owns all temporary player stat modifiers and shield charges. It is a child of `Player` and is wired by Arena via `PlayerBuffManager.setup(player, auto_attack)`.
- `EnemySpawner` only rolls and spawns powerup pickups on enemy death; it never applies powerup effects directly.
- `PowerupManager` applies effects and is wired by Arena to Player, AutoAttack, containers, HUD, and EnemySpawner.
- Shield blocks damage in `Player.take_damage()` after dash and debug invulnerability checks, before HP reduction.
- Timed buffs pause naturally with the tree and do not persist between runs (fresh Arena on restart).

## Miniboss + Final Boss Encounter Architecture

### Miniboss rules
- Miniboss spawns via EventDirector during normal waves (no separate arena, no enemy clear).
- Normal enemies MUST keep spawning while the miniboss is alive.
- Miniboss health bar tracks the miniboss; defeat opens the evolution reward screen.
- Do not clear normal enemies, do not create a temporary arena, and do not restrict the player's movement for the miniboss.

### Final boss encounter state
- `Arena._final_boss_arena_active: bool` — set to `true` when the final boss encounter begins; reset by Arena scene reload.
- `EnemySpawner._final_boss_encounter_active: bool` — stops `_can_spawn()`, `spawn_timer`, and `_wave_timer` for the duration of the encounter.
- `EventDirector._final_boss_encounter_active: bool` — causes `_process()` to return early, preventing new event triggers and active-timed-event ticks.

### Encounter trigger flow
1. `RunManager.target_time_reached` → `Arena._on_boss_phase_triggered()`.
2. Arena shakes and calls `Arena._start_final_boss_encounter()`.
3. `EnemySpawner.start_final_boss_encounter()` stops spawn and wave timers.
4. `EventDirector.stop_for_final_boss_encounter()` freezes the event schedule.
5. `Arena._clear_normal_enemies_for_boss()` calls `queue_free()` on all `enemy_container` children whose `is_final_boss != true`. No `died` signal fires; no XP or powerup drops are granted.
6. Arena builds a 1200×900 `Rect2` centered on the player, clamped to the full playable field, via `_build_boss_arena_rect()`.
7. `Player.set_playable_rect()` and `Player.set_camera_limits()` apply the smaller rect.
8. `_spawn_boss_arena_boundary(rect)` adds a `Node2D` child with a single `Line2D` rectangle. The boundary is display-only — no collision shape, no damage. No damaging arena hazards are ever added here.
9. "Final Boss Arena!" is announced; the boss spawns at the arena center via `EnemySpawner.spawn_final_boss(boss_id, center_pos)`.
10. `BossHealthBar`, HUD final boss info, and FinalBossController all wire the same way as before.

### Temporary boss arena boundary rules
- The boundary is a `Line2D` rect drawn in world space; it is purely visual.
- Player clamping is handled by `Player.set_playable_rect()` (existing mechanism).
- Camera limits are handled by `Player.set_camera_limits()` (existing mechanism).
- The boundary node is named `"BossArenaBoundary"` and stored in `Arena._boss_arena_boundary`.
- **No collision shape** is added to the boundary. **No area damage** is added. Damaging arena hazards must not be added unless explicitly requested by the user.

### Encounter cleanup
- Final boss defeated: `Arena._on_final_boss_defeated()` calls `_clear_boss_arena_boundary()`. Victory flow continues as normal.
- Player death: `_on_player_died()` → game over screen; boundary cleanup happens when the player confirms restart or quit.
- Restart from game over/victory: `_on_restart_requested()` calls `_clear_boss_arena_boundary()` before emitting `restart_run_requested`.
- Quit to menu from game over/victory: `_on_quit_to_menu_requested()` calls `_clear_boss_arena_boundary()`.
- Restart/quit confirmed via pause-menu ConfirmDialog: `_on_confirm_dialog_confirmed()` calls `_clear_boss_arena_boundary()` before the scene transition.
- Arena scene reload resets all state naturally; no explicit flag reset is needed.

### Spawn guard chain during final boss
- `EnemySpawner.start_final_boss_encounter()` stops timers → timer callbacks do not fire.
- `EnemySpawner._can_spawn()` also checks `_final_boss_encounter_active` as a redundant guard.
- `EventDirector._process()` returns early → no new elites, no new miniboss events, no new timed modifiers.
- `EnemySpawner.spawn_final_boss()` is exempt: it accepts an optional `override_position: Vector2` (defaults to `NO_SPAWN_POSITION` which triggers the normal ring-based search). Arena passes the boss arena center.

## Stage Objectives & Win Conditions Architecture

Each stage has an `objective_type` and `objective_data` in StageDataProvider. Victory always requires defeating the final boss; the objective type determines how the boss phase is triggered.

### Per-stage objectives
- **City Rooftop** (`objective_type: "survival"`) — classic survival; `RunManager.target_time_reached` drives the boss trigger unchanged.
- **Neon Lab** (`objective_type: "defense"`) — a Lab Reactor spawns at `Vector2(0, -110)`; enemies deal contact damage to it; reactor reaching 0 HP triggers immediate defeat; surviving to 10:00 triggers the boss phase normally.
- **Wasteland Gate** (`objective_type: "destroy_structures"`) — 3 Dark Portals spawn at spread positions; destroying all 3 immediately triggers the boss phase; the 10:00 timer does NOT connect to the boss trigger for this objective type.

### StageObjectiveManager responsibilities
- Instantiated at runtime in `Arena._setup_stage_objective()` using `load(...).new()` — same pattern as FeedbackManager/DebugStatsOverlay.
- Added as child of Arena with position `Vector2.ZERO`.
- Reads `stage_data.objective_type` and `stage_data.objective_data` to spawn the correct entity/entities.
- Emits `objective_completed`, `objective_failed`, `objective_state_changed(state)`.
- `get_objective_state()` returns a Dictionary describing current progress (defense HP or portals destroyed / total).
- `cleanup()` removes spawned entities and disconnects signals; called by Arena in all restart/quit/death paths.

### Objective entities are gameplay targets, not hazards
- `DefenseObjective` has no collision_layer of its own and no arena effect on the player. It is a damage-receiving structure, not an obstacle or trap.
- `PortalObjective` is on collision_layer=2 (enemy layer) solely so player attacks detect it. It deals no damage and has no effect on movement.
- The boss arena boundary (`BossArenaBoundary`) remains a display-only Line2D with no collision or damage. No damaging arena hazards are added anywhere.

### Arena integration
- `Arena._setup_run_lifecycle()` conditionally connects `RunManager.target_time_reached` → `_on_boss_phase_triggered()` only when `objective_type != "destroy_structures"`.
- `_on_boss_phase_triggered()` guards `if _run_ended: return` to prevent triggering after a defense defeat.
- `_on_objective_completed()` (destroy_structures path): calls `run_manager.mark_boss_phase_triggered()`, shows announcement, then calls `_on_boss_phase_triggered()` directly.
- `_on_objective_failed()` (defense path): calls `_trigger_objective_defeat()` — mirrors `_on_player_died()` flow with "Reactor Destroyed!" announcement.
- `_on_objective_state_changed(state)` forwards state to `hud.update_objective_state(state)`.

### HUD integration
- `GameHUD.setup_objective_manager(obj_manager, objective_type)` wires signals and sets `_objective_type`.
- `update_objective_state(state)` renders defense HP (with color coding) or portal count ("Portals: N / 3" / "Portals: ALL DESTROYED").
- `_update_objective()` skips the survival-timer label when `_objective_type != "survival"`.

### PortalObjective detectability
- `collision_layer=2`, `collision_mask=0`, added to `"enemies"` group.
- Player autoattack Area2D (mask=2) detects portals as bodies via `body_entered`; `splash_melee` includes portals in `_enemies_in_range` since they share the enemy collision layer.
- Portals implement `take_damage(amount)` — the same interface called by projectile and shockwave damage paths.
- No modifications to `PlayerProjectile.gd` or `PlayerAutoAttack.gd` were needed.

### Cleanup invariant
`Arena._cleanup_stage_objective_manager()` is called in every exit path: restart from game over, restart from victory, quit to menu, and pause-menu ConfirmDialog confirm. The manager node is freed and the reference set to null.

### No Build Evolution
Build Evolution is not included in any stage objectives patch. The `objective_type` field is the only new stage data; it does not add build paths, meta economy changes, or upgrade categories.

## Stage & Final Boss Architecture

- `Main` owns the navigation flow: MainMenu → CharacterSelect → StageSelect → RunBriefingScreen → Arena. Back from StageSelect returns to CharacterSelect. Back from RunBriefingScreen returns to StageSelect. Restart keeps same hero + stage and bypasses briefing. Quit to menu clears both.
- `StageDataProvider` is a persistent Node in Main (child of Main.tscn). It owns stage definitions and is passed to StageSelect.setup().
- `StageApplier` (static) is called by Arena._ready() after GameplayTuning.apply_to() when stage_data is non-empty. It applies background colors, run settings, and event/spawn profiles.
- StageSelect is display-only: it may show stage cards, remembered-stage markers, color swatches, threat summaries, run objectives, recommended playstyle, and boss previews, but it must not mutate stage data or gameplay state.
- Stage identity metadata in StageDataProvider is for UI presentation only. Do not wire `threat_summary`, `stage_goal`, `recommended_playstyle`, `enemy_pressure`, or `boss_preview` into spawn logic, run settings, rewards, persistence, or final boss behavior.
- StageSelect must emit the original stable stage id (`city_rooftop`, `neon_lab`, or `wasteland_gate`) when Start Run is pressed.
- RunBriefingScreen is display-only: it may read hero data, stage data, and Training summaries, but it must not mutate meta/training data, saves, gameplay state, or persistence.
- RunBriefingScreen Start emits intent only and Main starts the current selected hero/stage flow. RunBriefingScreen Back returns to StageSelect.
- Do not add arena hazards unless the user explicitly requests hazards. The boss arena boundary (`BossArenaBoundary`) is a display-only Line2D with no collision or damage; it must remain that way.
- `EventDirector.set_event_profile(profile)` appends profile-specific extra events to the schedule. "balanced" adds nothing. "ranged_support" adds early shooter and support surge events. "swarm_exploder" adds early exploder and swarm rush events.
- `SpawnDirector.set_stage_profile(profile)` stores the profile and applies per-variant weight bonuses in `_get_modified_weight()`.
- **Final boss victory gating**: when `RunManager.final_boss_required == true` (set from stage run_settings), reaching target time emits `target_time_reached` instead of victory. Arena spawns the boss. Victory only triggers after `register_final_boss_defeated()`.
- `EnemySpawner.spawn_final_boss(boss_id)` mirrors `spawn_miniboss_enemy` but calls `_attach_final_boss_controller()` instead. Emits `final_boss_spawned(enemy)` and `final_boss_defeated(enemy)`.
- `FinalBossController` is attached as a child of the boss enemy (auto-freed on death), same pattern as MinibossAttackController. Phase 2 at ≤50% HP emits `phase_changed(2)`.
- `BossHealthBar` is wired by Arena to `EnemySpawner.final_boss_spawned`; tracks the enemy until death. It is a permanent child of Arena (Arena.tscn).
- Run summary includes `stage_id`, `stage_display_name`, `final_boss_id`, and `final_boss_defeated` (from RunManager.get_stats()). MetaProgressionManager uses `final_boss_defeated` for the +35 reward.
- Debug: `Arena.debug_spawn_final_boss(boss_id)` spawns the final boss immediately. No key binding — call from the Godot remote console during a live run.

## Run Victory Architecture

- `RunManager` owns the run objective state (is_final_phase_active, has_victory, elite_kill_count, miniboss_kill_count, target_run_time, final_phase_start_time, final_boss_required, final_boss_spawned, final_boss_defeated).
- `Arena` owns screen coordination: connects RunManager signals, builds enriched run summaries, and shows/hides VictoryScreen and GameOverScreen.
- `VictoryScreen` and `GameOverScreen` are display-only — they show stats and emit intent signals only.
- `Main` owns scene replacement for restart and main menu navigation.
- Run summary is built by `Arena._build_run_summary(base_stats)` on both victory and defeat and is not persisted.
- Final phase: `RunManager` emits `final_phase_started` → Arena shows announcement → Arena calls `EventDirector.start_final_phase_event()` → EventDirector applies pressure modifier via SpawnDirector.
- Final boss: `RunManager` emits `target_time_reached` → Arena spawns final boss → victory only after boss death.
- Debug-shortened runs: set `use_debug_run_duration = true` in RunManager inspector; final phase start time scales proportionally. Not persisted. Not enabled by default.

## Balance / Readiness Architecture

- `GameplayTuning` centralizes exported balance defaults and applies them to existing systems at Arena startup.
- Arena remains the coordinator: it finds systems, calls `GameplayTuning.apply_to(self)`, then wires gameplay, UI, debug, and lifecycle flows.
- Arena should avoid storing every balance number directly; keep easily tweakable values on `GameplayTuning` or the owning gameplay node.
- Debug logs should be configurable and off by default unless actively diagnosing input, spawn, or powerup flow.
- Spawn diagnostics use `EnemySpawner.spawn_debug_logging`; powerup diagnostics use `EnemySpawner.powerup_debug_logging`.
- `ProjectHealthCheck` is a one-time startup wiring checker, not a test framework and not a success logger.
- Readiness safeguards should be lightweight caps or validation guards, not object pooling or architecture rewrites.

## Character Select / Hero Roster Architecture

- Main owns the frontend flow: MainMenu -> CharacterSelect -> Arena.
- MainMenu only emits `start_requested`; it does not know Arena or hero details.
- CharacterSelect is display-only: it reads HeroDataProvider, displays heroes, and emits `hero_confirmed(hero_id)`.
- CharacterSelect hero cards must show display name, playstyle, and compact locked/last-selected state without owning navigation or persistence.
- CharacterSelect selected hero detail cards must show name, subtitle, description, playstyle, hero-specific ability display names from hero data, compact stat traits, and a read-only per-hero Training summary when MetaProgressionManager is available.
- CharacterSelect selected hero detail content must stay inside a bounded `ScrollContainer`; long details should scroll inside the right panel and must never push Back / Start Run below the screen.
- CharacterSelect bottom navigation buttons must remain fixed below the main hero list/details content and visible at 16:9 landscape sizes.
- CharacterSelect must never mutate Training/meta data, buy upgrades, write saves, change hero stats, or change balance values.
- HeroDataProvider owns hardcoded hero dictionaries for now; do not migrate to Resources until explicitly requested.
- HeroDataProvider supplies stable hero ids plus kit ids: `guardian` -> `solar_guardian`, `blaster` -> `night_tactician`, `vanguard` -> `fury_vanguard`.
- Guardian is an original solar/flying powerhouse fantasy: durable beam attacker with Solar Energy passive, a focused beam ability, frost cone with slow, and a damage dash with invulnerability.
- Guardian may override ability display names through hero data, but global input slots and ability ids must stay stable.
- Blaster keeps the `blaster` id and is a rocket tactician: fires homing rockets (no pierce, no bounce), plants Smoke Screen/Explosive Trap, and closes with a Grappling Hook. Tactical Mark is multi-enemy and duration-based.
- Blaster presents slot 1/2/3 as Smoke Screen, Explosive Trap, and Grappling Hook in hero data; global input slots and ability ids remain stable.
- Vanguard keeps the `vanguard` id and is an original rage bruiser: close-range splash melee autoattack (`splash_melee`), Rage passive (builds from damage taken and damage dealt, decays over time, increases all damage up to 1.45× at max), Rage Wave (slot 1, circle AoE + slow), Mighty Clap (slot 2, cone AoE + knockback), Rage Leap (slot 3, dash + landing AoE + slow). Upgrade lines: `splash_melee_damage/radius/speed/impact/frenzy` (attack); `rage_wave_power/radius/cooldown/deep_slow/chain`, `mighty_clap_power/range/cooldown/shockwave`, `rage_leap_power/radius/cooldown` (active). Vanguard is excluded from all projectile-count, pierce, bounce, spread, multishot, and old nova/laser/slam ability upgrade lines.
- Vanguard's ability display names through hero data are Rage Wave, Mighty Clap, and Rage Leap; global input slots and ability ids remain stable.
- Final hero roster ids and display names: `guardian` = Solar Guardian, `blaster` = Night Tactician, `vanguard` = Fury Vanguard.
- Final hero ability display names: Solar Guardian = Solar Beam / Frost Breath / Death Dash; Night Tactician = Smoke Screen / Explosive Trap / Grappling Hook; Fury Vanguard = Rage Wave / Mighty Clap / Rage Leap.
- Hero-specific ability display names must come from hero data and flow through HeroApplier/AbilityManager or direct hero data reads in display-only roster UI.
- HeroApplier must pass selected hero kit info into AbilityManager. AbilityManager owns all hero-specific active ability behavior and passive combat resources.
- Global input slots and public methods remain stable: `ability_1`/`cast_ability_1`, `ability_2`/`cast_ability_2`, `ability_3`/`cast_ability_3`.
- AbilityManager uses per-hero dedicated properties. Solar Guardian: `solar_beam_*`, `frost_breath_*`, `death_dash_*`. Night Tactician: `smoke_screen_*`, `explosive_trap_*`, `grappling_hook_*`. Fury Vanguard (reworked): `rage_wave_*`, `mighty_clap_*`, `rage_leap_*`, plus `rage`, `rage_max`, `rage_decay_per_second`, `rage_damage_multiplier_at_max`, etc. Generic `nova_*`, `laser_*`, and `slam_*` properties remain for the generic fallback slot path and existing non-hero-specific upgrades — they must not be removed, but Vanguard no longer uses them.
- Solar Guardian uses Solar Energy passive (+2/sec automatic, not from hits). At 100 energy, a 15-second empowered state activates (x2 damage on all abilities and autoattack); energy resets to 0 and resumes charging. `get_solar_damage_multiplier()` returns the active multiplier. Solar Guardian autoattack weapon id is `solar_ray` (direct beam, no projectile).
- Solar Guardian must NOT receive projectile-count/multishot upgrades (`multishot_up`, `spread_up`, `bouncing_bolts`, `split_barrage`), nor nova/laser/slam ability upgrade lines. Use `hero_exclude: ["guardian"]` on those definitions. Guardian-only upgrades use `hero_only: ["guardian"]` and the `solar_ray`, `solar_beam`, `frost_breath`, `death_dash` archetypes.
- Night Tactician uses multi-enemy Tactical Mark: `_tactical_marks` is a Dictionary (enemy Node → seconds_remaining), ticked each frame. All three active abilities apply marks on contact/area. Rockets read `get_tactical_mark_multiplier(target)` for bonus damage on marked targets. Mark does NOT affect other heroes' weapons.
- Fury Vanguard uses Rage built from damage taken and from dealing autoattack/ability damage. Rage decays at `rage_decay_per_second`; higher Rage increases all autoattack and ability damage (up to `rage_damage_multiplier_at_max` at 100 Rage). Public helpers: `add_rage(amount)` (called by PlayerAutoAttack on hits), `get_rage_damage_multiplier()` (read by PlayerAutoAttack for splash_melee scaling), `get_rage_state()` (read by DebugStatsOverlay).
- These runtime passive resources reset naturally with each Arena.
- Ready ability casts must not silently fail because zero enemies were hit. If `_guard_cast(slot)` allows the cast, AbilityManager should provide available feedback/status, start cooldown, emit `ability_cast`, and emit `ability_cooldown_changed`.
- UI, HUD, mobile controls, debug overlays, and debug logs must prefer hero-specific ability display names from AbilityManager state instead of hardcoded global ability labels.
- Level-up option descriptions may substitute hero-specific ability display names at presentation time, but upgrade ids, archetypes, effects, weights, and save-facing data must stay stable.
- Hero-specific upgrade flavor is display-only. Upgrade ids, effects, weights, rarity, max levels, prerequisites, archetype points, synergies, build-defining logic, and selected upgrade history remain shared and stable.
- LevelUpScreen must always store and emit the original `upgrade_id`; flavored titles/descriptions must never become gameplay identifiers.
- LevelUpScreen selection must hide the level-up UI before or during signal handling so Arena can resume gameplay when no other blocking modal remains.
- HeroApplier applies run-only selected hero stats to Player, AutoAttack, and AbilityManager.
- Arena stores selected hero data for the active run summary and HUD display.
- Restart from GameOver/Victory should reuse the same selected hero id; Quit to Menu should allow choosing a different hero next run.
- Do not persist selected hero or add hero unlocks/meta-progression unless explicitly requested.
- Do not use licensed superhero names, characters, brands, logos, or protected identity terms in code, UI text, docs, comments, or commit text.

## Evolution System Architecture

- UpgradeManager owns level-up upgrade options, upgrade history, archetype points, and synergy/build-defining upgrade state.
- EvolutionManager owns evolution definitions, prerequisite checks, effect application, and applied evolution state.
- EvolutionRewardScreen is display-only; it never applies evolutions directly.
- Arena coordinates opening the reward screen, pausing/resuming, applying selected evolutions, and announcements.
- Evolutions are runtime-only and reset naturally with every new Arena.
- Miniboss defeat is the main evolution reward path; elite rewards are optional through `elite_reward_chance` and default to off.
- Do not add persistence, meta-progression, evolution unlock storage, or evolution art assets unless explicitly requested.

## Meta Progression Architecture

- `Main` owns `MetaProgressionManager`, `PostRunRewardsScreen`, and `MetaUpgradeShop`. All three are loaded and instantiated at runtime in `Main._ready()` via `load().instantiate()` — do not add them to Main.tscn directly.
- `Arena` emits `run_result_ready(summary: Dictionary)` before pausing the tree for the V/GO result screen. Arena never calls MetaProgressionManager directly.
- `Main._on_run_result_ready(summary)` calls `MetaProgressionManager.apply_run_result(summary)`, stores the reward data, and marks rewards as pending (`_rewards_shown = false`).
- When the player clicks Restart or Menu from the V/GO screen, Main intercepts via `_check_and_show_rewards(pending_action)`. If rewards have not been shown, it re-pauses the tree, opens PostRunRewardsScreen, and defers the action as `_pending_action`.
- `PostRunRewardsScreen.continue_requested` → Main hides the screen, unpauses, and executes the pending action (`_do_restart_run` or `_do_quit_to_menu`).
- `MetaApplier.apply_meta_progression(meta_manager, player, auto_attack, ability_manager)` is called by Arena after `_apply_selected_hero`, applying bonuses in this order: GameplayTuning → HeroApplier → MetaApplier. MetaApplier is loaded dynamically via `load("res://scenes/meta/MetaApplier.gd")`.
- `MetaUpgradeShop` emits `buy_requested(upgrade_id)` → `Main._on_meta_buy_requested(upgrade_id)` → `MetaProgressionManager.buy_meta_upgrade(upgrade_id)`. The shop is display-only.
- `MainMenu` emits `meta_shop_requested` → `Main._open_meta_shop()` hides MainMenu and opens MetaUpgradeShop. Shop back → `Main._close_meta_shop()` closes shop and re-shows MainMenu.
- `CharacterSelect.setup(hero_data_provider, meta_progression_manager)` accepts optional MetaProgressionManager. If provided and `is_hero_unlocked()` returns false, the hero button shows "[LOCKED — N currency]" and the start button is disabled. Currently all heroes are `unlocked_by_default: true` so no locking occurs in practice.
- `Player.pickup_radius_bonus` is a `@export float = 0.0`. `ExperienceGem._update_target_player()` reads it safely via `player_node.get("pickup_radius_bonus") or 0.0` to extend the magnet radius without hard coupling.
- `MetaProgressionManager` save format: JSON, versioned (`save_version: 1`). Keys: `currency`, `meta_upgrades` (dict of id→level), `unlocked_heroes` (array), `total_runs`, `total_victories`, `best_kill_count`, `total_kills`, `total_currency_earned`. Corrupt or missing saves start fresh.
- `reset_progress()` is available for remote console use only. No key binding.
- `DebugStatsOverlay.setup_meta_manager(meta_manager)` wires the overlay to show currency, run/win counts, and non-zero upgrade levels in a "-- Meta --" section (visible while F12 debug mode is active).

## Per-Hero Training Architecture

- `MetaProgressionManager` stores shared currency plus per-hero Training levels in `training_by_hero`.
- Guardian, Blaster, and Vanguard Training levels are separate. Shared currency is never duplicated per hero.
- Old global `meta_upgrades` saves migrate by copying global levels to each existing hero, preserving earned Training value.
- `UserPreferencesManager` stores only non-gameplay preferences like last selected hero/stage; it must not store Training levels.
- `Main` owns current selected hero/stage flow and resolves the safe hero id when opening Training from MainMenu.
- `MetaUpgradeShop` displays the selected Training hero, offers a compact hero selector, and must never purchase upgrades without a resolved hero id.
- `MetaUpgradeShop` emits `buy_requested(hero_id, upgrade_id)`; Main delegates to `MetaProgressionManager.purchase_training_upgrade(hero_id, upgrade_id)`.
- `MetaApplier` must apply Training by selected hero id only. Runs as Guardian, Blaster, or Vanguard must never combine Training levels from other heroes.
- Runtime upgrades, evolutions, and temporary run state must not be written into Training data.

## Implemented Systems

- MinibossAttackController with Nova, Barrage, and Charge Slam attacks.
- AttackTelegraph visual warning zones (circle for nova, line for charge).
- 2-phase miniboss: reduced cooldowns, increased barrage count and nova radius in phase 2.
- Miniboss phase announcement: "Miniboss Enraged!" on phase 2 transition.
- Miniboss defeated announcement: "Miniboss Defeated!" on miniboss death.
- Enemy.set_velocity_override / clear_velocity_override for locked-direction charge movement.
- Enemy.apply_knockback(direction: Vector2, force: float, duration: float = 0.22) — applies velocity override in the given direction at force magnitude, then clears it after duration via a one-shot tween.
- EnemySpawner.projectile_container passed from Arena for projectile and effect parenting.
- Player movement.
- Arena bounds and player clamping.
- Camera follow and camera limits.
- Enemy chase behavior.
- Timer-based enemy spawning.
- Basic player/enemy HP.
- Enemy contact damage to player.
- Projectile-based player autoattack.
- Player HP HUD.
- Enemy HP bars.
- Hit flash feedback.
- XP gem drops.
- XP pickup.
- XP HUD bar.
- Run timer.
- Enemy kill counter.
- Player death handling.
- Game over screen with current run stats.
- Current run restart from game over.
- Time-based spawn difficulty.
- SpawnDirector-owned spawn scaling and variant selection.
- Dynamic spawn interval and max alive enemy scaling.
- Enemy variants: Grunt, Runner, Tank, Charger, and Shooter.
- Variant-based XP values.
- Level-up pause screen.
- Three-option upgrade selection.
- Basic run upgrades.
- Upgrade levels and max upgrade levels.
- Weighted upgrade option selection.
- Upgrade rarity labels.
- Dynamic upgrade descriptions.
- AbilityManager on the player with 3 active ability slots.
- Active ability input through `ability_1` (J), `ability_2` (K), `ability_3` (L).
- Slot 1 active ability (`ability_1`): hero-specific area presentation.
- Slot 2 active ability (`ability_2`): hero-specific forward line presentation.
- Slot 3 active ability (`ability_3`): hero-specific close burst presentation.
- 3-slot ability cooldown HUD display.
- Slot 1/2/3 visual feedback (built-in nodes only).
- Slot 2 and slot 3 runtime upgrades (damage, cooldown, width/radius).
- Player.get_aim_direction() for slot 2 targeting.
- Mobile ability buttons for all 3 slots.
- Virtual joystick mobile movement foundation.
- Mobile slot 1 ability button.
- Keyboard and mobile input coexist.
- Floating damage numbers.
- Enemy death burst feedback.
- Projectile hit spark feedback.
- XP gem magnet attraction.
- Camera shake foundation.
- Main menu.
- Start Run flow.
- Pause menu.
- Resume from pause.
- Restart Run through Main.
- Quit to Menu.
- Desktop/mobile Pause button.
- Desktop/mobile Build button under Pause.
- Settings menu.
- Persistent local settings through `user://settings.cfg`.
- Volume settings.
- Force mobile controls setting.
- Screen shake setting.
- AudioManager foundation.
- Enemy behavior expansion v1.
- Charger enemy behavior.
- Shooter enemy behavior.
- EnemyProjectile foundation.
- Player dash.
- Dash cooldown.
- Dash invulnerability window.
- HUD dash cooldown display.
- Mobile dash button.
- Dash visual feedback.
- Dash upgrades.
- Debug Mode toggle with F12.
- DEBUG ON overlay.
- Debug invulnerability through Player.take_damage().
- F1 debug one-level gain while Debug Mode is enabled.
- Projectile pierce.
- Multishot.
- Projectile spread angle.
- Projectile size upgrade.
- Explosive projectile upgrade.
- Weapon modifier upgrades.
- Separated collision layers/masks to prevent Player and Enemy bodies from physically pushing each other.
- PowerupPickup foundation.
- PowerupManager with heal, shield, bomb, magnet burst, move speed boost, attack speed boost.
- PlayerBuffManager with timed speed buffs and shield charges.
- Active buff HUD display (shield, move speed timer, attack speed timer).
- BombBurst visual effect.
- Enemy death powerup drop rolls (6% base chance, weighted selection).
- ExperienceGem.force_magnet_to_player() for magnet burst.
- Player.heal() for non-damaging HP restoration.
- Shield charge consumption in Player.take_damage() (after dash/debug invulnerability).
- EventDirector with a timed event schedule (Runner Rush at 30s, Tank Wave at 60s, Elite at 90s, Miniboss at 150s).
- Run progression and victory condition:
  - RunManager owns target_run_time (600s), final_phase_start_time (540s), elite_kill_count, miniboss_kill_count, has_victory.
  - final_phase_started signal triggers "Final Phase!" announcement and EventDirector final pressure event.
  - victory_reached signal triggers VictoryScreen with full enriched run summary.
  - special_kill_count_changed signal updates GameHUD elite/boss counter.
  - VictoryScreen shows time, kills, elite kills, miniboss kills, level, build, upgrade count.
  - GameOverScreen enriched with elite kills, miniboss kills, and dominant build; has Main Menu button.
  - GameHUD objective label "Survive: MM:SS / 10:00"; FINAL PHASE label; Elite N | Boss N counter.
  - Arena._build_run_summary() composes full stats from RunManager, Player, and UpgradeManager.
  - Debug-shortened runs via use_debug_run_duration / debug_target_run_time in RunManager inspector.
- Timed events boost spawn pressure and variant weights through SpawnDirector active_event_modifiers.
- Elite enemy spawning: base variant with 3× HP, 3× XP, 1.2× damage, 1.1× scale, orange color override.
- Miniboss enemy spawning: base variant with 12× HP, 10× XP, 2× damage, 2× scale, purple color override, forced chase behavior.
- MinibossHealthBar UI tracks live miniboss HP and hides on death.
- EventAnnouncement fade-in/out label for event names.
- Guaranteed powerup drop for elite and miniboss enemies.

## Primary Weapon / Autoattack Architecture

- `HeroDataProvider` stores a `primary_weapon` dictionary on every hero: `weapon_id` (stable string id), `display_name`, and weapon-specific default property overrides (`projectile_speed`, `projectile_size_multiplier`, `projectile_pierce`, `projectile_bounce`, `attack_range`, `direct_damage`).
- Stable hero primary weapon ids: `guardian` → `solar_ray`, `blaster` → `homing_rockets`, `vanguard` → `splash_melee`.
- `HeroApplier.apply_hero()` calls `PlayerAutoAttack.set_primary_weapon(hero_id, weapon_id, weapon_data)` as the final step, after all stat bonuses have been applied. It also calls `PlayerAutoAttack.set_ability_manager_ref(ability_manager)` so homing_rockets can read Tactical Mark state.
- `PlayerAutoAttack.set_primary_weapon()` stores `_primary_weapon_id` and `_primary_weapon_data`, then applies weapon-specific property defaults. It does NOT override `attack_damage` or `attack_interval` — those are owned by HeroApplier stats and UpgradeManager.
- `PlayerAutoAttack._physics_process` routes by `_primary_weapon_id` after the cooldown check:
  - `"solar_ray"` → `_tick_solar_ray()` — direct beam, no projectile spawned.
  - `"homing_rockets"` → `_tick_homing_rockets()` — spawns `projectile_count` rockets distributed round-robin across all enemies in range. Each rocket is always pierce=0, bounce=0, homing=true. Reads `get_tactical_mark_multiplier(target)` from AbilityManager to pre-multiply damage for marked targets.
  - `"splash_melee"` → `_tick_splash_melee()` — direct `take_damage()` on all enemies within `splash_melee_radius` of the player; no projectile spawned. Damage scales with Rage via `get_rage_damage_multiplier()`. Reports hits back to AbilityManager via `add_rage(rage_per_hit)` for Rage gain. Applies per-hit knockback if `splash_melee_knockback > 0`.
  - empty / unknown → `_tick_solar_bolt(enemy)` — standard projectile spawn via `_spawn_projectiles()` (fallback).
- Stable upgrade hooks that must not be renamed: `attack_damage`, `attack_interval`, `attack_range`, `projectile_count`, `projectile_pierce`, `projectile_size_multiplier`, `projectile_explosion_radius`, `projectile_bounce`, `projectile_speed`. All apply on top of weapon defaults regardless of weapon mode.
- Projectile-specific upgrades (`projectile_count`, `projectile_pierce`, `projectile_bounce`, `projectile_explosion_radius`, `projectile_size_multiplier`, `projectile_speed`) do not crash `splash_melee`; they simply have no effect since no projectile is spawned. Vanguard has `hero_exclude` on all projectile-category upgrade definitions so they never appear in the pool.
- `PlayerAutoAttack` exposes `splash_melee_radius: float` and `splash_melee_knockback: float` as `@export` properties, upgradeable via `splash_melee_radius` and `splash_melee_impact` upgrade definitions.
- `PlayerAutoAttack.get_primary_weapon_id()` returns the current weapon id string.
- `PlayerAutoAttack.get_primary_weapon_display_name()` returns the `display_name` from weapon data.
- `GameHUD.set_primary_weapon_name(display_name)` dynamically adds a `WeaponLabel` child to `BuildPanel`.
- `Arena._ready()` calls `hud.set_primary_weapon_name(auto_attack.get_primary_weapon_display_name())` inside the HUD setup block, after `_apply_selected_hero`.
- `DebugStatsOverlay` Weapon section now shows `Primary: <weapon_id>`, then `DMG / Interval / Range`, then `Count / Pierce / Bounce`, then `Spread / Size / Expl R`.
- No arena hazards were added. Build Evolution is not included in this patch.

## Weapon Modifier Notes

- PlayerAutoAttack owns weapon stats: `projectile_count`, `projectile_spread_degrees`, `projectile_pierce`, `projectile_size_multiplier`, and `projectile_explosion_radius`.
- PlayerAutoAttack exposes `get_weapon_stats()` for debugging and headless sanity checks.
- `projectile_count > 1` must use visible spread even when `projectile_spread_degrees` is still zero.
- Spread and multishot projectiles should not be forced back onto the same target every frame.
- PlayerProjectile handles pierce and explosion.
- PlayerProjectile uses `homing_enabled` to decide whether it follows the target after launch.
- PlayerProjectile should only damage enemies.
- PlayerProjectile hit lists are local per projectile instance; do not add global same-target blocking.
- Multishot projectile instances must each be able to apply direct damage to the same enemy.
- PlayerProjectile should not damage the same enemy twice from the same projectile instance.
- `attack_id` and `projectile_index` can be used with `debug_hits` for local hit testing.
- Weapon modifier upgrades are runtime-only.

## Player Dash Notes

- Player owns dash state, cooldown, and invulnerability.
- Damage immunity is handled inside `Player.take_damage()`.
- Debug invulnerability is separate from dash invulnerability and must not alter dash timers.
- MobileControls emits dash intent; Arena wires it to `Player.try_dash()`.
- `dash_cooldown_down` and `dash_invulnerability_up` are runtime upgrades only.

## Debug Flow

- Arena coordinates Debug Mode keyboard input during an active Arena run.
- DebugManager owns debug state and signals, not keyboard handling.
- Arena._input() uses `_input` (not `_unhandled_input`) for debug keys to intercept before UI.
- Direct raw key detection for F12/F10/F1/F2 is checked first; InputMap actions are a fallback.
- F3–F8 debug validation keys use InputMap action names and raw keycode fallbacks; they are blocked by `_is_debug_action_blocked()` (paused / game-over / player-dead / debug-off).
- A single `handled_debug_key` boolean prevents double-processing the same key press.
- Debug toggle supports F12 with F10 fallback; debug level supports F1 with F2 fallback.
- Debug level keys should not work while paused, game-over, level-up, or player-dead.
- DebugOverlay only displays DEBUG ON and does not own debug rules.
- DebugStatsOverlay is display-only: it reads state from references, never mutates gameplay.
- DebugStatsOverlay is instantiated at runtime in Arena._setup_debug_stats_overlay() by loading the scene via `load()`. It is NOT added to Arena.tscn.
- Player owns `debug_invulnerable`, `debug_gain_one_level()`, and `debug_add_experience(amount)`.
- Arena wires DebugManager to Player, DebugOverlay, and DebugStatsOverlay.
- Debug Mode is runtime-only, not persisted, and not exposed in SettingsMenu.
- DebugManager.request_*() methods check debug_enabled, print accept/reject reason, then emit signals. DebugManager never spawns objects or modifies gameplay state directly.
- Arena connects all DebugManager validation signals in _setup_debug_flow() and handles each action.
- Do not add debug cheats unless explicitly requested.

### Debug Diagnostics

- `DEBUG_INPUT:` — Arena can print raw key detection for F12/F10/F1/F2 and debug action names when `Arena.debug_input_logging` is enabled.
- `DEBUG_WIRING:` — Arena prints whether DebugManager, DebugOverlay, DebugStatsOverlay, and Player debug APIs were found and whether signals were connected.
- `DEBUG_MODE:` — DebugManager logs every toggle with the resulting enabled state.
- `DEBUG_LEVEL:` — DebugManager logs each request (accepted) or rejection with a short reason (disabled, tree paused, missing player, player dead).
- `DEBUG_ACTION:` — DebugManager logs each validation request (accepted or rejected with reason). Arena logs the result: `spawned powerup <id>`, `spawned elite`, `spawned miniboss`, `added XP <n>`, `killed nearby enemies count=<n>`.
- `DEBUG_PLAYER:` — Player logs `set_debug_invulnerable` changes, `debug_gain_one_level` level values, and `debug_add_experience` amounts.
- `POWERUP_WIRING:`, `POWERUP_ROLL:`, `POWERUP_SPAWNED:`, `POWERUP_DEBUG:` — EnemySpawner powerup diagnostics controlled by `powerup_debug_logging`.
- Diagnostic log code should remain available, but verbose logging should be off by default unless actively debugging.

### Old Naruto-Clicker Comparison

- In the previous naruto-clicker project, debug logic lived directly in the active gameplay screen (`ClickerScreen.gd`) and game state (`ClickerState.gd`). Because those scripts processed all relevant input, debug keys were reliably received.
- In SuperHeroes, Arena is the active gameplay coordinator and should be the primary debug input owner for the same reason: it is the scene that is awake and processes input during a run.
- DebugManager should own state and signals (service node pattern), not be the sole input receiver. A service node without a direct input path risks missing key events if Godot's input routing changes or if UI nodes consume input first.
- Keeping debug level-up integrated with Arena also ensures it shares the same block conditions (pause, game-over, level-up, player dead) as the regular level-up flow.

## Settings Flow

- SettingsMenu uses `Node.PROCESS_MODE_ALWAYS` because it must work from MainMenu while unpaused and PauseMenu while paused.
- SettingsMenu should block clicks behind it while visible.
- Main owns the MainMenu SettingsMenu and must hide it before starting Arena.
- Arena owns the in-run SettingsMenu for PauseMenu flow.

## Controls Help Flow

- `ControlsHelpOverlay` is display-only and does not own pause, navigation, upgrades, settings, rewards, or persistence.
- `ControlsHelpContent.gd` is the single source for help text sections.
- Main owns the frontend help overlay and opens it from MainMenu `help_requested` or `help_toggle` when no run/settings/shop screen is active.
- Arena owns the in-run help overlay and opens it from PauseMenu `help_requested` or `help_toggle`.
- Opening help during active gameplay pauses the tree and resets mobile controls. Closing resumes only when help was the reason the tree was paused.
- Opening help from PauseMenu keeps PauseMenu state intact; closing help returns to the paused menu.
- Help must not open over SettingsMenu, LevelUpScreen, EvolutionRewardScreen, VictoryScreen, or GameOverScreen.

## Pause / Restart / Exit Safety Flow

- `ConfirmDialog` is display-only; it emits `confirmed(action_id)` and `cancelled(action_id)` and does not own gameplay pause state.
- Arena owns active-run confirmation and pause state. Restart and Main Menu requests from PauseMenu open ConfirmDialog first; confirmed actions emit `restart_run_requested` or `quit_to_menu_requested` once.
- Main owns the out-of-run menu stack and post-run reward transition. Victory/GameOver buttons keep using the reward screen path and are not confirmed as active-run abandonment.
- PauseMenu emits requests only; it does not confirm destructive actions or change scenes directly.
- SettingsMenu and ControlsHelpOverlay do not own gameplay pause state. Arena/Main decide whether closing them should resume gameplay or return to a menu.
- Escape / Back priority during a run is ConfirmDialog, Help, Settings, blocked run screens, PauseMenu, then opening PauseMenu.
- Mobile pause follows the same Arena pause/back route as Escape. Mobile ability and dash signals are blocked while run modals are open.
- Duplicate transition guards are required around active-run restart/quit, CharacterSelect/StageSelect confirms, result-screen reward transitions, and PostRunRewardsScreen Continue.

## User Preferences Flow

- `UserPreferencesManager` stores non-gameplay preferences only in `user://superheroes_user_preferences.json`.
- `MetaProgressionManager` stores gameplay progression only in `user://superheroes_meta_progress.json`.
- `SettingsManager` keeps settings in `user://settings.cfg`.
- Main owns `UserPreferencesManager`, loads preferences during `_ready()`, and saves confirmed hero/stage choices.
- CharacterSelect and StageSelect may read preferred ids and show "Last selected", but they must not own saving.
- Restart keeps the current hero/stage already stored on Main; Quit to MainMenu keeps preferences for the next run flow.
- Preference reset must call `UserPreferencesManager.reset_preferences()` only and must not reset meta progression or settings.

## Frontend Flow

- Main owns frontend flow and run scene replacement.
- Main owns SettingsManager and AudioManager.
- MainMenu emits `start_requested`; it does not start Arena directly.
- Arena emits `restart_run_requested` and `quit_to_menu_requested`.
- PauseMenu only emits UI intents.
- GameOver restart goes through Arena/Main, not direct scene reload.

## Main Menu Layout

- MainMenu layout is UI-only and must preserve existing flow signals.
- Current layout: Settings button is top-left; Help / Controls button is top-right; Select Hero and Training are horizontal neighbors in the bottom interface.
- The centered header panel keeps the SuperHeroes title, subtitle, and remembered `Last: Hero / Stage` hint.
- MainMenu reworks must not rename existing button signals or change Main's navigation ownership without a specific flow reason.
- Layout-only patches must not change gameplay balance, hero/stage data, rewards, runtime persistence, debug behavior, or add arena hazards.
- Do not directly copy licensed superhero names, characters, brands, or logos.

## Settings And Audio Flow

- SettingsMenu edits SettingsManager.
- AudioManager applies volume and mute settings from SettingsManager.
- Arena applies mobile controls and screen shake settings during runs.
- Audio streams are optional; no real audio assets are included yet.

## Level-Up Flow

- Player emits `level_up_available(level)` after XP crosses a threshold.
- Arena pauses the tree.
- Arena asks `UpgradeManager` for three options.
- `UpgradeManager` returns option dictionaries with title, rarity, level info, max level, dynamic description, slot category, new-line state, and category slot usage.
- `LevelUpScreen` displays option dictionaries from `UpgradeManager` while paused, including compact `Attack`, `Passive`, or `Active` slot markers with usage.
- Arena applies the selected upgrade through `UpgradeManager`.
- Arena unpauses gameplay.

## UpgradeManager V3 Notes

- Upgrade definitions remain hardcoded dictionaries (not Resource assets).
- Each upgrade now optionally carries `archetype`, `tags`, `prerequisites`, `tier`, and `unlock_hint` fields.
- Supported archetypes: `projectile`, `nova`, `laser`, `slam`, `dash`, `tank`, `speed`, `utility`.
- `archetype_points: Dictionary` tracks how many upgrades per archetype the player has taken this run.
- `selected_upgrade_history: Array[Dictionary]` stores compact history entries (id, title, archetype, level_after_pick, tags).
- `selected_attack_lines`, `selected_passive_lines`, and `selected_active_lines` track owned upgrade ids for the 4/4/4 slot limits.
- All upgrade build state is run-only state — it resets naturally when Arena reloads. Not saved to disk.
- Upgrade slot categories are stable and owned by `UpgradeManager`: `attack` for primary weapon / autoattack lines; `passive` for `type/category: "passive"` or `tags: ["passive", ...]`, plus defense/mobility/utility run-stat lines; `active` for ability-tagged, `nova`/`laser`/`slam`, or `ability_manager` targeted lines.
- New upgrade lines consume one slot in their category. Repeated levels of an already selected upgrade id do not consume extra slots.
- Slot limits are `MAX_ATTACK_LINES = 4`, `MAX_PASSIVE_LINES = 4`, and `MAX_ACTIVE_LINES = 4`. When a category is full, new lines in that category must not appear; already selected non-maxed lines may still appear.
- `build_changed(dominant_archetype, points)` signal is emitted after every successful upgrade application.
- Build-aware weighted selection: archetype bias multiplier = `1.0 + min(archetype_points * 0.12, 0.6)`. The system remains non-deterministic.
- Diversity protection: `get_upgrade_options` tries to ensure at least 1 option from outside the dominant archetype when enough off-archetype candidates exist.
- Synergy upgrades carry a `prerequisites` dictionary with optional keys: `archetype_points` (AND), `upgrade_levels` (AND), `any_archetype_points` (OR), `any_upgrade_levels` (OR), and `any_of` (OR over nested prerequisite dictionaries).
- `is_upgrade_available` checks max_level, prerequisites, and slot availability. Locked synergy upgrades and new full-category lines never appear in the option pool.
- Synergy upgrades use an `effects: Array[Dictionary]` field; `_apply_effects_array` handles bool/int/float properties, supports `add`, `subtract`, `multiply`, and `set`, applies optional min/max clamping, and fails safely on invalid target/property/operation.
- Build-defining synergy upgrades set `is_build_defining = true`; LevelUpScreen appends `BUILD DEFINING`, and DebugStatsOverlay reports selected/available build-defining counts.
- Build-defining v4 upgrades: Aftershock Zone, Double Pulse, Seismic Echo, Comet Dash, and Bouncing Bolts.
- Base upgrades retain their `effect_value` + match-statement path unchanged.
- `heroic_endurance` uses the existing `_apply_max_health_upgrade` helper via the match statement.
- Public methods added: `get_archetype_points`, `get_dominant_archetype`, `get_selected_upgrade_history`, `get_upgrade_definition_summary`.
- Prerequisite helpers: `_meets_prerequisites`, `_get_tag_count`, `_get_archetype_count`, `_has_upgrade_level`.
- Slot category helpers: `_get_slot_category`, `_get_selected_slot_lines`, `_get_slot_category_max`, and `_definition_targets`.
- Debug helpers (not bound to keys): `debug_get_available_upgrade_ids`, `debug_get_slot_state`, `debug_print_upgrade_pool`.
- `LevelUpScreen._format_option_text` now shows `[RARITY] [ARCHETYPE]`, appends `SYNERGY` for synergy upgrades, appends `BUILD DEFINING` for build-defining upgrades, and shows slot category / usage from the option dictionary.
- `GameHUD` connects to `build_changed` via `setup_upgrade_manager(upgrade_manager)` and displays "Build: Archetype" or "Build: Mixed".
- Arena calls `hud.setup_upgrade_manager(upgrade_manager)` inside `_setup_level_up_flow` after `upgrade_manager.setup(...)`.
- UpgradeManager remains the owner of the upgrade pool and all run build state.
- Arena coordinates the level-up flow; LevelUpScreen and GameHUD are display-only.
- `BuildSlotsWindow` is display-only and reads `UpgradeManager.get_slot_state()` plus `get_upgrade_definition_summary(upgrade_id)`; it must not parse history manually or mutate upgrade state.
- Arena owns BuildSlotsWindow setup/open/close, modal blocking, and pause/resume safety. Opening the window pauses active gameplay; closing resumes only when no other blocking modal is open.
- MobileControls only emits `build_slots_pressed`; it must not inspect or mutate build state.
- Pause/Build buttons stay visible on desktop and mobile. Joystick, dash, and ability buttons remain touch/forced-mobile controls.
- DebugStatsOverlay may read `UpgradeManager.debug_get_slot_state()` and display selected upgrade ids by category, but must never mutate slot state.
- Slot state remains runtime-only and resets with each fresh Arena/UpgradeManager run.
- Hero-specific upgrade rewrites are not included in this patch.
- No Build Evolution in this patch.

## Passive Ability System Foundation

- `PassiveAbilityManager` is instantiated at runtime by `Arena._setup_passive_ability_manager()` using `load("res://scenes/passives/PassiveAbilityManager.gd").new()`. It is not part of Arena.tscn.
- `PassiveAbilityManager.setup(player, enemy_container, projectile_container, pickup_container, feedback_manager)` wires run references only. It owns `add_or_upgrade_passive(passive_id)`, `get_passive_level(passive_id)`, `has_passive(passive_id)`, `get_passive_state()`, and `cleanup()`.
- Passive state is runtime-only. Selected passive ids/levels, timers, shield regeneration state, and pickup radius bonuses must reset every run and must never be written to meta saves, settings, rewards, user preferences, or stage data.
- Current shared passive lines are `orbit_shields`, `storm_relay`, `guardian_drone`, and `magnet_core`. They are shared by all heroes and must not depend on hero kit identity.
- Passive abilities must provide visible gameplay feedback, not only hidden numeric state.
- Orbit Shields visuals must track `PlayerBuffManager.shield_changed` / `get_shield_charges()` so consumed and regenerated charges are visible around the player.
- Storm Relay and Guardian Drone must show clear hit feedback when they deal damage, such as Line2D arcs plus status/damage text.
- Magnet Core must either rely on pickup scripts reading `player.pickup_radius_bonus` or provide an explicit runtime pull fallback; upgrades should show clear selection feedback.
- Passive upgrade definitions live in `UpgradeManager.gd` with `type`/`category` set to `"passive"`, `tags` containing `"passive"`, conservative `max_level`, a display `description_template`, and normal weighting/archetype fields.
- `UpgradeManager` now supports passive upgrades by passing passive ids to `PassiveAbilityManager.add_or_upgrade_passive()`. Existing attack upgrades, active ability upgrades, hero-flavored text, synergy upgrades, and build-defining upgrades must keep their ids and behavior.
- `LevelUpScreen` may display passive options with a compact `PASSIVE` marker, but it remains display-only.
- `DebugStatsOverlay` may read `PassiveAbilityManager.get_passive_state()` for ids/levels/timers. It must never mutate passive or gameplay state.
- Slot limits are implemented in `UpgradeManager`; passive visibility hotfixes should preserve those limits rather than reimplementing them elsewhere.
- Hero-specific attack/active upgrade rewrites are not included yet.
- No Build Evolution in this patch.

## Run Lifecycle

- `RunManager` owns run objective state: timer, kill count, elite kills, miniboss kills, target run time, final phase start time, and victory state.
- `EnemySpawner` reports enemy deaths to `RunManager` via `register_enemy_kill()`, `register_elite_kill()`, and `register_miniboss_kill()`.
- Player emits `died` when health reaches zero.
- `RunManager` emits `final_phase_started` when run_time crosses `final_phase_start_time`; Arena announces it and EventDirector applies final pressure.
- `RunManager` emits `victory_reached(stats)` when run_time crosses `target_run_time` and `can_trigger_victory()` returns true.
- Arena ends defeat run, pauses the tree, builds enriched summary, and shows `GameOverScreen`.
- Arena handles `victory_reached`, builds enriched summary, and shows `VictoryScreen`.
- `VictoryScreen` and `GameOverScreen` are display-only; they emit restart or quit intents.
- Restart emits through Arena/Main and creates a fresh run; it does not write saves, high scores, or meta-progression.
- Run summary (`_build_run_summary`) is run-only and not persisted.
- Victory screen guards: player death after victory is ignored; duplicate screens are prevented by `has_victory` and `is_run_active` flags.

## Spawn Progression

- `SpawnDirector` owns time-based spawn scaling, variant selection, wave packages, and the Wave Director layer.
- `EnemySpawner` spawns enemies and drops XP, but should not own long-term difficulty design.
- Enemy variants are currently hardcoded dictionaries, not Resources.
- Enemy variant dictionaries include `behavior_id` and `role`.
- Spawn interval and max alive enemy limits scale from run time.
- Grunt is available from run start, Runner opens after about 30 seconds, Charger after about 45 seconds, Tank after about 60 seconds, Shooter after about 75 seconds, Exploder after about 120 seconds, Swarm after about 150 seconds, Shielded after about 180 seconds, and Support after about 210 seconds.
- Variant XP values are copied onto the dropped `ExperienceGem`.
- Enemies should spawn near the player using `EnemySpawner` ring spawn, but never directly on top of the player.

## Wave Director / Enemy Roles Architecture

- Enemy roles are metadata added to each variant dict: `swarmer` (grunt, swarm), `hunter` (runner, charger), `bruiser` (tank, shielded), `shooter` (shooter), `disruptor` (exploder, support). Role is informational and used for package selection weight; it does not change behavior_id or stats.
- `SpawnDirector.WAVE_PACKAGES` is a constant array of package definitions. Each package defines `id`, `role`, `variant_pool`, `min_count`, `max_count`, `weight`, `unlock_time`, and `profile_bonus` (per-profile weight multiplier).
- `SpawnDirector.get_wave_package()` selects a package weighted by time + stage profile, builds the final `variant_ids` list (already sized), and returns `{id, role, variant_ids}`. Returns `{}` if no package is available yet.
- `SpawnDirector.get_wave_interval()` returns the seconds between wave package spawns: 14 s early → 8 s late.
- `SpawnDirector.debug_get_wave_state()` returns `{stage_profile, last_wave_package, wave_interval}` for the debug overlay.
- `EnemySpawner._wave_timer` is a `Timer` created programmatically in `_ready()` and started in `setup()`. It fires `_on_wave_timer_timeout()` independently of the regular `SpawnTimer`.
- `EnemySpawner._on_wave_timer_timeout()` updates `_wave_timer.wait_time`, calls `spawn_director.get_wave_package()`, then calls `_spawn_from_package(package)`.
- `EnemySpawner._spawn_from_package(package)` iterates `package.variant_ids`, checks `enemy_container.get_child_count() >= _get_current_max_alive_enemies()` before each enemy, and calls `_spawn_enemy_with_variant`. Stops early if cap is reached or no spawn position is found.
- **Max alive cap is always respected**: both the regular `SpawnTimer` path and the wave package path independently check the cap before each enemy spawn. No burst can overflow the cap.
- Stage profiles affect package weight via `profile_bonus` on each package. Neon Lab (ranged_support) boosts shooter_screen and support_pair. Wasteland Gate (swarm_exploder) boosts swarm_rush and exploder_pressure. Balanced (City Rooftop) gives a small bonus to bruiser_wall and mixed_late_wave.
- Stage profiles also continue to affect individual per-enemy variant weights via `_stage_profile_weight_bonuses` in SpawnDirector (unchanged from before).
- `EnemySpawner.debug_get_spawn_state()` now includes `stage_profile`, `last_wave_package`, and `wave_interval` fields sourced from `SpawnDirector.debug_get_wave_state()`.
- `DebugStatsOverlay` Spawner section now shows: `Profile: <profile>  MaxAlive: N`, `Interval: X.XX  WaveEvery: Xs`, `Last pkg: <package_id>`.
- Do not add arena hazards unless explicitly requested.
- Miniboss and final boss spawning remain unchanged: they are triggered by EventDirector and EnemySpawner dedicated methods, not by wave packages.

## Enemy Behavior Notes

- `behavior_id` comes from SpawnDirector variant dictionaries.
- `Enemy.gd` owns runtime behavior execution.
- SpawnDirector owns unlock timing and weighted selection.
- EnemySpawner should stay behavior-agnostic.
- EnemyProjectile should detect Player only.
- Shooter must approach into preferred range, stand ground, and never retreat away from the player.
- Exploder uses `behavior_id = "exploder"` and deals explosion damage through `Player.take_damage()`.
- Swarm uses `behavior_id = "swarm"` and combines approach with simple orbit movement.
- Support uses `behavior_id = "support"` and applies temporary enemy modifiers to nearby non-support enemies.
- Shielded enemies use `shield_value` / `max_shield_value`; shield absorbs damage before HP.
- Support modifiers must remain temporary; reapplying the same modifier refreshes duration rather than stacking permanent stats.
- `EnemySpawner.debug_spawn_enemy_variant(variant_id)` can spawn specific enemy variants for remote console testing.
- EventDirector owns enemy wave timing; SpawnDirector owns temporary event weight modifiers.

## Active Ability Flow

- `AbilityManager` is a child of `Player` and owns all active ability logic and cooldowns.
- Arena wires `AbilityManager` to the Player, EnemyContainer, HUD, and optionally UpgradeManager.
- Slot 1 uses `ability_1` (J) with hero-specific area behavior routed by kit id.
- Slot 2 uses `ability_2` (K) with hero-specific forward behavior routed by kit id.
- Slot 3 uses `ability_3` (L) with hero-specific impact/control behavior routed by kit id.
- Solar Guardian: Solar Beam (slot 1) is a long-range red beam in aim direction, Frost Breath (slot 2) is a cone that damages and slows enemies, and Death Dash (slot 3) moves the player forward dealing path damage with brief invulnerability. All three abilities apply `get_solar_damage_multiplier()` for the empowered x2 bonus.
- Night Tactician: Smoke Screen creates a persistent area zone (ColorRect visual) that slows enemies inside every 0.5s, applies Tactical Mark to them, and reduces player damage while the player is inside. Explosive Trap is placed at the player's position and triggers on enemy contact in `trigger_radius`, then explodes in `explosion_radius` and marks all hit enemies. Grappling Hook finds the nearest enemy in `grappling_hook_range`, dashes the player to it via `_move_player_safely()`, deals `grappling_hook_damage`, and applies a mark. All three abilities are blocked from applying if `_guard_cast()` fails.
- Fury Vanguard: Rage Wave (slot 1) is a circle AoE that damages and slows all enemies in radius (radius scales slightly with Rage ratio). Mighty Clap (slot 2) is a cone AoE that damages and knocks back enemies using `_apply_knockback_in_cone` → `Enemy.apply_knockback()`. Rage Leap (slot 3) dashes toward aim direction with brief invulnerability then deals AoE damage + slow at landing. All three apply `_get_rage_damage_multiplier()` and call `_add_rage_from_ability_damage()` on hits. `AbilityManager.add_rage()` is public so PlayerAutoAttack grants Rage from splash_melee hits.
- All abilities are available from run start; no unlock system.
- HUD listens to `ability_cooldown_changed` and displays readiness for all 3 slots.
- MobileControls emits ability intents (ability_1/2/3_pressed) only; Arena wires them to AbilityManager.
- GameHUD displays ability states only; no gameplay logic.
- Cooldowns pause naturally while the tree is paused.
- `Player.get_aim_direction()` returns the last non-zero movement direction; slot 2 uses this as its cast direction.
- Ability enemy scans happen only on cast, not every frame.
- Ability synergy delayed hits are owned by AbilityManager and stay anchored to their original cast origin/direction.
- Nova Aftershock uses `NovaAftershockFeedback`; Laser Double Pulse and Slam Second Wave reuse the existing Laser/Slam feedback scenes at the delayed cast position.
- Hero-kit routing must not change enemies, stages, reward formulas, meta economy, save format, arena hazards, primary autoattack identity, or Build Evolution unless explicitly requested.
- In hotfixes for ability reliability, keep the scope to AbilityManager/input/UI pause flow; do not add arena hazards, Build Evolution, or primary autoattack reworks.
- Do not introduce Enemy Roles, Boss Rework, Stage Objectives, arena hazards, licensed superhero names, or DC/Marvel/Superman/Batman/Hulk references in hero-kit work.

## Build Synergy v4 Notes

- `AbilityManager` owns Nova Aftershock, Laser Double Pulse, and Slam Second Wave runtime state/effects.
- `Player` owns dash damage trail state and applies the Comet Dash damage burst when dash ends.
- `PlayerAutoAttack` owns bounce configuration and passes it into spawned `PlayerProjectile` instances.
- `PlayerProjectile` owns per-projectile bounce target selection and never damages the same enemy twice from the same projectile instance.
- `UpgradeManager` owns all build-defining unlock rules and effect application.
- `LevelUpScreen`, `GameHUD`, and `DebugStatsOverlay` are display-only for build/synergy information.

## Upgrade Grid Schema Foundation

- `UpgradeManager` owns upgrade grid schema normalization and validation. Existing upgrade definitions remain dictionary-backed and hardcoded for now.
- Supported optional fields on upgrade definitions: `upgrade_line_id`, `slot_category`, `hero_id`, `hero_ids`, `hero_exclude`, `source_type`, `source_skill_id`, `grid_index`, `triple_id`, `evolution_role`, `evolution_target_active_skill`, and `evolution_candidate_id`.
- Backward compatibility rules: missing `upgrade_line_id` falls back to `id`; missing `slot_category` is inferred from existing `category`, `type`, `tags`, `archetype`, and effect targets. Existing upgrade effects, weights, prerequisites, 4/4/4 slot limits, and hero filtering must keep working.
- Normalization helpers exposed by `UpgradeManager`: `get_upgrade_line_id`, `get_upgrade_slot_category`, `get_upgrade_hero_ids`, `get_upgrade_source_skill_id`, `get_upgrade_grid_index`, `get_upgrade_triple_id`, `get_upgrade_evolution_role`, and `get_upgrade_evolution_target`.
- Validation helpers exposed by `UpgradeManager`: `validate_upgrade_grid(strict := false)`, `validate_upgrade_grid_for_hero(hero_id, strict := false)`, and `debug_get_upgrade_grid_state()`.
- Non-strict validation treats incomplete future 9/9/9 targets as warnings. Strict validation may promote target-count gaps to errors for future release gates.
- Future target counts are 9 Attack lines per hero, 9 Active lines per hero, and 9 shared Passive lines. Passive upgrade lines should remain shared, not hero-specific, unless a future task explicitly changes that rule.
- Future Evolution triples link one attack line, one passive line, one active line, and one evolved active skill. Each upgrade line may be used only once per hero triple grid.
- Do not implement EvolutionManager changes, Overdrive screens, evolved active skills, the 9-passive pack, or Solar/Night/Fury grid normalization in this schema-only patch.

## Input Flow

- Keyboard movement and ability input still use the Godot InputMap.
- `help_toggle` uses H with F11 fallback and opens/closes the Help / Controls overlay where allowed.
- `MobileControls` emits a movement signal instead of moving the Player directly.
- Arena wires `MobileControls.movement_changed` to `Player.set_external_move_vector`.
- Arena wires `ability_1_pressed` → `AbilityManager.cast_ability_1`.
- Arena wires `ability_2_pressed` → `AbilityManager.cast_ability_2`.
- Arena wires `ability_3_pressed` → `AbilityManager.cast_ability_3`.
- Arena wires the mobile pause button to the same pause-open handler as keyboard pause.
- Arena wires the Build button to BuildSlotsWindow through `build_slots_pressed`; the window is blocked during PauseMenu, Settings, Help, ConfirmDialog, LevelUp, EvolutionReward, Victory, and GameOver screens.
- `MobileControls` listens to `ability_cooldown_changed` and updates all 3 button texts.
- Help overlay blocks mouse/touch input behind it while visible.

## Collision Notes

- Player body uses the Player layer and should not physically collide with Enemy bodies.
- Enemy bodies use the Enemies layer and should not physically collide with Player or other Enemy bodies.
- Enemy contact damage is handled by `ContactDamageArea`, which detects Player bodies.
- Player autoattack range detects Enemy bodies through `Area2D`.
- Player projectiles detect Enemy bodies through `Area2D`.
- Enemy projectiles detect Player bodies through `Area2D`.
- Experience gems detect Player bodies through `Area2D`.
- Do not re-enable Player/Enemy physical body collisions unless explicitly requested.

## Feedback Notes

- Enemy emits `damage_taken`; UI/effects nodes handle display.
- EnemySpawner coordinates enemy death effects and XP drops.
- `ExperienceGem` owns magnet movement toward valid living players.
- Player owns the Camera2D shake helper (`shake_camera`); FeedbackManager wraps it and applies `screen_shake_intensity` scaling.
- Feedback scenes use built-in nodes only and do not own gameplay rules.

## Feedback Architecture (Feedback Polish Pack)

- `FeedbackManager` owns visual/audio feedback routing only. It never applies damage or changes gameplay state.
- Gameplay scripts (Player, PowerupManager, Arena) request feedback from FeedbackManager; they do not duplicate floating-text or shake logic.
- `SettingsManager` owns persistence for `screen_shake_enabled`, `screen_shake_intensity`, `floating_text_enabled`, and `impact_flash_enabled`. FeedbackManager reads these on every call.
- `FloatingTextSpawner` owns text visuals only. FeedbackManager delegates text spawning to it. Typed helpers: `spawn_damage_text`, `spawn_heal_text`, `spawn_powerup_text`, `spawn_status_text`. Legacy `show_damage` / `show_pickup` are preserved for backward compatibility.
- Arena instantiates FeedbackManager at runtime (loaded via `load()`, not in .tscn) during `_setup_feedback_manager()`, called before `_setup_spawn_director()`. Arena passes FeedbackManager to Player, AbilityManager, PowerupManager, and EnemySpawner.
- FeedbackManager throttles non-critical floating text to `MAX_FLOATING_TEXTS_PER_FRAME = 6` per `THROTTLE_WINDOW = 0.08s`. Critical texts (player damage, heal, powerup, evolution) bypass the throttle.
- Duplicate announcement guard: same text within 0.5 s is suppressed inside FeedbackManager.`show_announcement`.
- `EnemySpawner` connects `enemy.damage_taken` to `feedback_manager.show_damage` when available; falls back to `floating_text_spawner.show_damage`.
- Enemy hit flash updated: normal damage → red-white flash over 0.12 s; shield-absorbed hit → blue-white flash.
- Player `take_damage` routes shield-block feedback through FeedbackManager (`show_status("BLOCK")`) and real damage through `shake` + `show_damage`.

## Not Implemented Yet

- Reroll, skip, or banish upgrade actions.
- Upgrade icons.
- Upgrade codex or full upgrade history UI.
- Hero unlocks.
- Hero portraits.
- Hero-specific unique abilities.
- Persistent selected hero.
- Persistent evolution unlocks.
- Evolution art/icons.
- Evolution sound effects.
- Evolution chest animation.
- Stage-specific evolutions.
- Stage selection.
- Arena hazards.
- Data-driven Resource upgrade files.
- Stun from abilities.
- Chain-lightning projectiles.
- Permanent shield regeneration.
- New pickup types.
- Boss-specific art assets.
- Boss sound effects.
- More than 2 miniboss phases.
- Boss rewards or meta-progression.
- Complex bullet patterns or homing projectiles.
- Boss arena or cutscene.
- Buff icons.
- Powerup rarity tiers.
- Powerup upgrade scaling.
- Pickup object pooling.
- Advanced particle effects for powerups.
- Upgrade icons or Resource-backed data.
- Chain lightning.
- Critical hits.
- Elemental/status effects.
- Projectile pooling.
- Dash trail particles.
- Stamina.
- Advanced dodge perks.
- Controller remapping.
- Build Evolution rework.
- Enemy projectile patterns.
- Status effects.
- Real audio assets.
- Music playback.
- Localized help text.
- Icon-based controls guide.
- Runtime input remapping UI.
- Yandex/cloud save integration.
- Reroll, skip, or banish upgrade actions.
- Sound effects.
- Advanced particles.
- Crit text.
- Damage type colors.
- Pickup magnet upgrades.
- Mouse/manual ability aiming.
- Ability unlock system.
- Ability icons.
- Complex targeting indicators.
- Status effects from abilities.
- Ability loadouts.
- Input rebinding.
- Character select.
- Projectile upgrades.
- XP vacuum upgrades.
- Bosses.
- Biome or arena progression.
- Advanced hero unlock purchase UI (hero is visible as locked but no buy flow beyond the shop exists yet).
- Online leaderboard.
- Cloud save / Yandex save.
- Ads, paid purchases, or monetization.
- Achievements.
- Prestige or season resets.
- Persistent high scores or saved run history beyond total_runs/total_victories.

## Validation Notes

- Use debug tools (F3–F8) to verify gameplay systems before adding new content.
- Keep POWERUP_WIRING / POWERUP_ROLL / POWERUP_SPAWNED diagnostics available behind `powerup_debug_logging`.
- docs/validation/gameplay_validation.md is the canonical manual test checklist; update it when systems change.
- Run `godot --headless --editor --quit` from the repo root to confirm no parse errors after every patch.
- Validate Help / Controls from MainMenu, PauseMenu, active gameplay, and blocked modal states after changing input or menu flows.
- Validate Pause / Restart / Exit Safety QoL after changing pause, settings, help, reward, character select, stage select, or mobile controls flow.

## UI Helper Architecture

- `UIFormat` contains display formatting only — no gameplay logic, no signals, no state. Preload with `const UIFormat = preload("res://scenes/ui/UIFormat.gd")` and call static methods directly.
- `UIStateColors` contains color helpers only — no gameplay logic. Preload the same way. Colors are built-in Color values only; never require external assets or theme resources.
- UI scripts should not mutate gameplay balance. HUD, result screens, and reward screens are display-only.
- `GameHUD` displays state from Player, RunManager, AbilityManager, BuffManager, UpgradeManager, and EvolutionManager — it does not own any of that state.
- `GameHUD.show_final_boss_info(boss_name)` and `show_final_boss_defeated()` are called from Arena when the final boss spawns/dies.

## Development Rules

- README.md and Agents.md must be updated on every task.
- docs/validation/gameplay_validation.md must be updated for new gameplay flows and UI checks.
- Do not change gameplay values in UI polish patches.
- Do not change gameplay balance in QoL/progression architecture patches unless explicitly requested.
- QoL patches must not change gameplay balance, progression formulas, enemy/player stats, or reward formulas.
- Do not add arena hazards.
- Do not add persistence unless explicitly requested.
- Do not add runtime persistence for run temporary state.
- Do not add arena hazards.
- Do not add online backend, leaderboards, cloud save, ads, or paid purchases.
- Meta-progression save is local only (user://superheroes_meta_progress.json). Do not add Yandex or cloud save unless explicitly requested.
- Do not re-enable Player/Enemy physical body collisions.
- Debug tools (F3–F8) must only do anything while Debug Mode is ON (F12/F10). Normal gameplay must remain unchanged.
- Arena coordinates all debug actions. DebugManager owns debug state and emits request signals. DebugStatsOverlay is display-only.
- Do not add new enemy types unless explicitly requested.
- Miniboss damage must always go through Player.take_damage() or existing EnemyProjectile collision logic.
- Do not remove POWERUP_WIRING / POWERUP_ROLL / POWERUP_SPAWNED diagnostics; keep them configurable and off by default.
- Inspect the current project before changing files.
- Do not duplicate existing systems.
- Keep patches small and focused.
- Update `README.md` and `Agents.md` on every task.
- Do not remove `DEBUG_INPUT`, `DEBUG_WIRING`, `DEBUG_MODE`, `DEBUG_LEVEL`, or `DEBUG_PLAYER` diagnostic hooks; keep them configurable and off by default.
- Do not add extra debug cheats unless explicitly requested.
- Enemy variants are currently dictionaries, not Resource assets.
- Keep long-term difficulty formulas in `SpawnDirector`, not `EnemySpawner`.
- Keep spawn positioning and instancing in `EnemySpawner`.
- Do not add monetization unless explicitly requested.
- Do not use copyrighted superhero names, brands, logos, or specific existing characters.
- Keep desktop browser and mobile landscape browser in mind.
- Keep 16:9 and wide 20:9 landscape layouts in mind.
- AbilityManager owns active ability logic and cooldowns; do not split this into Player.
- Player exposes get_aim_direction() for ability targeting; do not add mouse aiming unless requested.
- GameHUD displays ability states only; do not add gameplay logic to HUD.
- MobileControls emits ability intents only; Arena wires them to AbilityManager.
- Do not add ability unlock systems unless explicitly requested.
- Do not add status effects or knockback to abilities unless explicitly requested.
- Do not make `MobileControls` directly mutate gameplay except through signals.
- Do not make ControlsHelpOverlay own gameplay pause decisions; Arena/Main own flow and state.
- Do not store run temporary state, currency, meta upgrades, run upgrades, or evolutions in UserPreferencesManager.
- Do not change gameplay values in QoL preference patches.
- Do not use Yandex storage until explicitly requested.
- Do not add real audio assets unless explicitly requested.
- Do not change gameplay damage values, cooldowns, drop rates, or enemy stats in feedback patches.
- FeedbackManager must not own game state or apply damage. It is a pure feedback router.
- SettingsManager owns feedback settings persistence; FeedbackManager reads settings on every call (never caches them).
- When adding new feedback calls, always use FeedbackManager methods; do not call FloatingTextSpawner or Player.shake_camera directly from gameplay scripts.
- Do not add bosses unless explicitly requested.
- Do not persist debug mode.
- Do not add debug cheats unless explicitly requested.
- RunManager owns run objective state; Arena coordinates screen display.
- VictoryScreen and GameOverScreen are display-only; never restart or load scenes directly.
- Run summary is not persisted; it resets naturally with Arena reload.

## Validation

Run:

```sh
godot --headless --editor --quit
```

Manual playtest checklist:

- Project starts from `Main.tscn`.
- Arena appears.
- Player moves with WASD and arrow keys.
- Player remains clamped inside arena bounds.
- Camera follows the player and respects limits.
- Enemies spawn over time and chase the player.
- Enemies do not spawn directly on top of the player.
- Enemy count respects `max_alive_enemies`.
- Spawn interval and max alive enemy pressure increase over time.
- Runner and Tank variants appear only after their unlock time.
- Enemy contact reduces player health at the configured interval.
- Player autoattack fires visible projectiles toward the nearest valid enemy in range.
- Projectiles damage enemies on hit and expire after `max_lifetime` if they miss.
- Enemies eventually die and disappear after enough projectile hits.
- Player HP HUD updates when player health changes.
- Enemy HP bars update when enemies take damage.
- Player and enemies briefly flash when damaged.
- Dead enemies drop XP gems.
- Tank XP gems grant more XP than Grunt and Runner gems.
- Player collects XP gems by touching them.
- XP HUD updates after pickup.
- Run timer advances during gameplay.
- Enemy kill counter increases when enemies die.
- Player death pauses gameplay and shows the game over screen.
- Game over screen displays time survived, enemies defeated, and player level.
- Help / Controls opens from MainMenu, PauseMenu, and H/F11 during allowed states.
- Remembered hero/stage preselect correctly in CharacterSelect and StageSelect.
- Restart button reloads the current run.
- No script errors appear.
