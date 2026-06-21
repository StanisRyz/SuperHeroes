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
- `scenes/evolution/EvolutionManager.gd` - evolution definitions, prerequisites, effects, applied run state, and read-only evolution progress/synergy hint data for UI.
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
- `scenes/ui/BuildSlotsWindow.gd` - display-only slot overview; reads UpgradeManager slot state, definition summaries, and read-only evolution progress hints; shows 4 Attack / 4 Passive / 4 Active rows, emits closed.
- `scenes/ui/MainMenu.tscn` - frontend main menu scene.
- `scenes/ui/MainMenu.gd` - main menu start, settings, training, collection, help, and quit intent signals. Emits `collection_requested` when the Collection button is pressed.
- `scenes/ui/HeroCollectionScreen.tscn` - hero collection screen CanvasLayer scene (instantiated at runtime by Main).
- `scenes/ui/HeroCollectionScreen.gd` - display-only hero collection screen. `setup(meta_progression_manager, hero_data_provider)` stores refs; `open()` calls `_refresh()` then shows; `close()` hides. Left panel: scrollable card list (one Button card per hero from `HeroDataProvider.get_all_heroes()` + 3 locked placeholder cards). Right panel: scrollable detail view for the selected hero (color swatch, name, owned/locked status, playstyle, passive, weapon, ability names, mastery stats, compact read-only equipment summary, description). Emits `back_requested` and `hero_selected(hero_id)`. Must not connect to CharacterSelect, mutate meta/saves, or affect gameplay. No gacha, shards, inventory, equipment swapping, or equipment upgrades.
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
- `scenes/ui/LevelUpScreen.gd` - displays options, including read-only evolution synergy hints when Arena supplies them, and emits selected upgrade IDs.
- `scenes/ui/GameOverScreen.tscn` - pause-time game over UI.
- `scenes/ui/GameOverScreen.gd` - displays run stats and emits restart requests.
- `scenes/player/Player.tscn` - player scene with camera.
- `scenes/player/Player.gd` - movement, bounds clamp, health state.
- `scenes/player/PlayerAutoAttack.gd` - autoattack range tracking, periodic enemy damage, and runtime-only attack evolution effects via `apply_attack_evolution(evolution_id, target_id)`.
- `scenes/enemies/Enemy.tscn` - enemy scene and contact damage area.
- `scenes/enemies/Enemy.gd` - chase movement, enemy health, contact damage.
- `scenes/enemies/SpawnDirector.tscn` - time-based spawn progression scene.
- `scenes/enemies/SpawnDirector.gd` - dynamic spawn settings and enemy variant selection.
- `scenes/enemies/EnemySpawner.tscn` - timer-based spawner scene.
- `scenes/enemies/EnemySpawner.gd` - spawn loop, spawn distance checks, max alive enemy limit, XP drops, powerup drop rolls.
- `scenes/player/PlayerBuffManager.tscn` - player buff manager scene.
- `scenes/player/PlayerBuffManager.gd` - timed buffs (move speed, attack speed) and shield charges.
- `scenes/passives/PassiveAbilityManager.gd` - runtime-only shared passive skill manager. Owns selected passive ids/levels, shield regeneration, shield/drone visuals, shared passive timers, visible arcs/pulses, magnet reach bonus, debug state, and cleanup. Never saves passive state.
- `scenes/powerups/PowerupManager.tscn` - powerup manager scene.
- `scenes/powerups/PowerupManager.gd` - applies powerup effects (heal, shield, bomb, magnet burst, speed boosts).
- `scenes/pickups/PowerupPickup.tscn` - generic in-run powerup pickup scene.
- `scenes/pickups/PowerupPickup.gd` - magnet movement and delegation to PowerupManager on collection.
- `scenes/effects/BombBurst.tscn` - bomb burst radius visual effect scene.
- `scenes/effects/BombBurst.gd` - expanding ring tween and cleanup logic.
- `scenes/events/EventDirector.gd` - timed event schedule per stage profile (`balanced`, `ranged_support`, `swarm_exploder`); fires `event_started`, `event_finished`, `elite_spawn_requested`, `miniboss_spawn_requested`; instantiated dynamically by Arena if not found as a scene child. Unknown profiles fall back to `balanced`.
- `scenes/ui/EventAnnouncement.tscn` - event announcement overlay scene.
- `scenes/ui/EventAnnouncement.gd` - fade-in/out label announcement for run events.
- `scenes/ui/MinibossHealthBar.tscn` - miniboss health bar overlay scene.
- `scenes/ui/MinibossHealthBar.gd` - tracks a miniboss enemy and displays its name, HP bar, and HP text.
- `scenes/enemies/MinibossAttackController.tscn` - miniboss combat brain scene (Node root).
- `scenes/enemies/MinibossAttackController.gd` - owns miniboss attack timing, attack selection, nova/barrage/charge execution, 2-phase logic, and phase_changed signal.
- `scenes/effects/AttackTelegraph.tscn` - short-lived visual warning zone scene (Node2D root).
- `scenes/effects/AttackTelegraph.gd` - plays circle or line danger zone using dynamically created Line2D; fades/pulses and queue_frees; never applies damage.
- `scenes/ui/DebugStatsOverlay.tscn` - minimal CanvasLayer root scene for the debug stats panel; all UI built programmatically in _ready().
- `scenes/ui/DebugStatsOverlay.gd` - live debug stats panel: player HP/level/XP/speed/dash, weapon stats, ability cooldowns/damage/synergy flags, build archetype/points/synergies/build-defining picks, passive ids/levels/timers, buff/shield state, spawner wiring, objective state (type, HP or portal count, portal pressure modifier), and boss state (ID, encounter state, phase, HP%, current attack, cooldown, attacking/arena flags). `setup_objective_manager(obj_manager)` wires it after `_setup_stage_objective()`; `setup_boss_controller(controller)` wires it after boss spawn. Safe if either ref is nil. Refreshes every 0.25s while visible. Display-only; never mutates gameplay state.
- `scenes/ui/VictoryScreen.tscn` - pause-time victory UI scene.
- `scenes/ui/VictoryScreen.gd` - displays run summary on victory and emits restart_requested / quit_to_menu_requested.
- `scenes/meta/MetaProgressionManager.tscn` - persistent meta manager node scene (instantiated at runtime by Main).
- `scenes/meta/MetaProgressionManager.gd` - owns soft currency, meta upgrade levels, fixed per-hero equipment levels, hero unlock state, lifetime stats, and save/load to user://superheroes_meta_progress.json. Calculates and applies run rewards. Never called directly by Arena.
- `scenes/meta/MetaApplier.gd` - static helper; applies purchased meta bonuses to Player, AutoAttack, and pickup_radius_bonus. Called by Arena after HeroApplier at run start.
- `scenes/ui/PostRunRewardsScreen.tscn` - post-run reward display CanvasLayer scene (instantiated at runtime by Main).
- `scenes/ui/PostRunRewardsScreen.gd` - display-only reward breakdown screen. Emits continue_requested. Shown between V/GO result screen and the next action (restart or menu).
- `scenes/ui/MetaUpgradeShop.tscn` - meta upgrade shop CanvasLayer scene (instantiated at runtime by Main).
- `scenes/ui/MetaUpgradeShop.gd` - display-only Training shop UI. Two-panel layout: left panel is Character Equipment preview (6 fixed hero equipment slots + hero preview); right panel is Training Upgrades scroll list. Header contains title, currency label, hero selector, and goals label. Footer has Back button. Equipment rows read definitions and levels only, show disabled "Upgrade coming next" buttons, and never emit purchase intent. Emits `buy_requested(hero_id, upgrade_id)` for Training only; Main handles the purchase. Accessed via "Training" button on MainMenu.
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
- `scenes/enemies/FinalBossController.gd` - owns final boss encounter state machine (intro/phase_1/phase_2/phase_3/defeated), 4-phase logic, 4 new attack patterns (aimed_barrage/ring_barrage/double_charge/pulse_nova), boss_id variant stat tuning, phase_changed signal, and `debug_get_boss_state()`. Attached dynamically as child of boss enemy on spawn. `stop()` halts all attack loops safely.
- `scenes/ui/BossHealthBar.tscn` - final boss health bar overlay scene (CanvasLayer layer=9).
- `scenes/ui/BossHealthBar.gd` - tracks a final boss enemy; shows "FINAL BOSS", name, HP bar, HP text, and phase label (Phase 1 white / Phase 2 amber / Phase 3 red). Positioned below MinibossHealthBar.
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

- `EventDirector` (`scenes/events/EventDirector.gd`) owns the run event schedule and fires signals when events trigger.
- Arena instantiates EventDirector dynamically if not found as a child node (script-only, no `.tscn` required).
- Arena wires `EventDirector.setup(run_manager)` and connects all event signals.
- Event types:
  - `"timed"` — emits `event_started(event_data)` immediately; Arena calls `SpawnDirector.apply_event_modifier(event_data)`. After `duration` seconds, emits `event_finished(event_id)` and Arena calls `SpawnDirector.clear_event_modifier(event_id)`.
  - `"announce_only"` — emits `event_started(event_data)` for the announcement; no modifier applied.
  - `"spawn_elite"` — emits `elite_spawn_requested(event_data)`; Arena calls `EnemySpawner.spawn_elite_enemy()`.
  - `"spawn_miniboss"` — emits `miniboss_spawn_requested(event_data)`; Arena calls `EnemySpawner.spawn_miniboss_enemy()`.
- Stage profiles and their scheduled events:
  - `"balanced"` (City Rooftop): wave warning (t=1:15), elite (t=1:30), wave surge (t=2:30), supply drop (t=3:50), elite (t=5:00), miniboss (t=7:00), pre-boss surge (t=8:00).
  - `"ranged_support"` (Neon Lab): ranged warning (t=1:00), elite (t=2:00), lab assault surge (t=3:20), reactor warning (t=4:50), miniboss (t=6:00), final lab assault (t=7:40).
  - `"swarm_exploder"` (Wasteland Gate): swarm warning (t=1:00), elite (t=1:30), swarm surge (t=3:00), miniboss (t=6:00), final siege (t=7:30).
  - Unknown profiles fall back to `"balanced"`.
- `start_final_phase_event()` applies a 60-second `spawn_pressure: 1.6, max_alive_bonus: 5` modifier.
- `stop_for_final_boss_encounter()` sets `_stopped = true` and clears all active timed modifiers.
- `EventAnnouncement` shows a fade-in/out announcement label when an event with non-empty announcement text starts.
- `MinibossHealthBar` is wired by Arena to `EnemySpawner.miniboss_spawned` and calls `track_enemy(enemy)`.
- Elite and miniboss enemies are spawned using the normal variant then `apply_special_modifier()` applies stat multipliers, color overrides, and flags.
- Elite and miniboss enemies always drop a powerup pickup on death (guaranteed drop).
- SpawnDirector reads `active_event_modifiers` in `get_spawn_interval`, `get_max_alive_enemies`, and `get_enemy_variant`.
- **No arena hazards**: EventDirector fires spawn/pressure events only. It must not add collision shapes, damage areas, or arena obstacles.

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
- `EventDirector._stopped: bool` — set by `stop_for_final_boss_encounter()`; causes `_process()` to return early, preventing new event triggers and active-timed-event ticks.

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
- `debug_get_objective_state()` returns an extended debug Dictionary including `portals_alive`, `portal_pressure_active`, and `portal_modifier`.
- `cleanup()` clears portal pressure modifier, removes spawned entities, and sets references to null; called by Arena in all restart/quit/death paths.
- **Portal pressure**: on `destroy_structures` setup, calls `spawn_director.apply_event_modifier("portal_pressure")` with a `spawn_pressure` bonus proportional to portals still alive (max +0.55 at full count). Updated on each `_on_portal_destroyed`; cleared when all portals are destroyed or on `cleanup()`.
- **No arena hazards**: StageObjectiveManager does not apply collision, damage areas, or environmental hazards to the arena.

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
- `EventDirector.set_event_profile(profile)` selects the active event schedule. Profiles: `"balanced"`, `"ranged_support"`, `"swarm_exploder"`. Unknown profiles fall back to `"balanced"`. Called by `StageApplier._apply_event_profile()` from Arena._ready().
- `SpawnDirector.set_stage_profile(profile)` stores the profile and applies per-variant weight bonuses in `_get_modified_weight()`.
- **Final boss victory gating**: when `RunManager.final_boss_required == true` (set from stage run_settings), reaching target time emits `target_time_reached` instead of victory. Arena spawns the boss. Victory only triggers after `register_final_boss_defeated()`.
- `EnemySpawner.spawn_final_boss(boss_id)` mirrors `spawn_miniboss_enemy` but calls `_attach_final_boss_controller()` instead. Emits `final_boss_spawned(enemy)` and `final_boss_defeated(enemy)`.
- `FinalBossController` is attached as a child of the boss enemy (auto-freed on death), same pattern as MinibossAttackController. Phase 2 at ≤50% HP emits `phase_changed(2)`.
- `BossHealthBar` is wired by Arena to `EnemySpawner.final_boss_spawned`; tracks the enemy until death. It is a permanent child of Arena (Arena.tscn).
- Run summary includes `stage_id`, `stage_display_name`, `final_boss_id`, and `final_boss_defeated` (from RunManager.get_stats()). MetaProgressionManager uses `final_boss_defeated` for the +35 reward.
- Debug: `Arena.debug_spawn_final_boss(boss_id)` spawns the final boss immediately. No key binding — call from the Godot remote console during a live run.

## Boss Encounter 2.0 Architecture

### Encounter State Machine

`FinalBossController` owns a string state machine on top of the existing 2-phase model:

| State | Entry condition | Attack behavior |
|-------|----------------|----------------|
| `intro` | Boss spawns | No attacks; `_intro_timer` counts up to `INTRO_DELAY` (1.8 s) |
| `phase_1` | Intro timer elapsed | Normal attack pool, full cooldown |
| `phase_2` | HP ≤ 50 % | Enraged pool, 0.65× cooldown multiplier |
| `phase_3` | HP ≤ 25 % | Desperation pool, 0.5× cooldown multiplier |
| `defeated` | Boss dies / `stop()` called | All loops halted |

Phase transitions are checked in `_check_phase()` called from the attack loop; transitions are one-way (phase can only increase). Transition from phase_1 → phase_2 emits `phase_changed(2)`; phase_2 → phase_3 emits `phase_changed(3)`.

### Boss Identities and Attack Pools

| boss_id | Phase 1 pool | Phase 2 pool | Phase 3 pool |
|---------|-------------|-------------|-------------|
| titan_guardian | nova, charge, nova | pulse_nova, charge, barrage | pulse_nova, double_charge, pulse_nova |
| prism_overlord | barrage, aimed_barrage, barrage | aimed_barrage, barrage, ring_barrage | aimed_barrage, ring_barrage, aimed_barrage |
| molten_colossus | nova, charge, nova | pulse_nova, charge, nova | pulse_nova, double_charge, nova |
| default | nova, barrage, charge | (same) | (same) |

`_get_attack_pool()` returns the correct array for `boss_id` + `_current_phase`. The attack loop cycles the pool round-robin via `_attack_index`.

### Boss Variant Stats (`_apply_boss_variant_stats`)

| boss_id | nova_radius | contact_damage | charge_speed_mult | attack_cooldown |
|---------|------------|---------------|-------------------|----------------|
| titan_guardian | 340 | 28 | 2.8 | 2.8 s |
| prism_overlord | 280 | 12 | 1.0 | 2.0 s |
| molten_colossus | 390 | 34 | 3.0 | 3.2 s |

prism_overlord overrides `barrage_count = 16` and `projectile_damage = 12`; molten_colossus overrides `barrage_count = 8` and `charge_speed_mult = 3.0`.

### New Attack Patterns

All new attacks use `AttackTelegraph.tscn` via `_spawn_telegraph()` and never apply unavoidable damage. Telegraph duration is always ≥ 0.55 s.

**aimed_barrage**
1. `play_line(boss_pos, player_pos, width, 0.7)` telegraph.
2. Await 0.7 s.
3. Fire 3 waves of 5 (phase 1/2) or 7 (phase 3) `EnemyProjectile`s aimed at the player's **current** position. Total capped at 20.
4. `await 0.18` between waves.

**ring_barrage**
1. `play_circle(boss_pos, nova_radius, 0.65)` telegraph.
2. Await 0.65 s.
3. Spawn 10 `EnemyProjectile`s at evenly spaced angles (360° / 10 = 36° apart), radially outward. No gap required.

**double_charge**
1. `play_line` toward player pos, await 0.6 s, execute first charge.
2. Await 0.3 s recovery.
3. `play_line` toward current player pos, await 0.6 s, execute second charge.

**pulse_nova**
1. `play_circle(boss_pos, nova_radius, 0.55)` (inner), await 0.55 s, apply inner AoE damage.
2. `play_circle(boss_pos, nova_radius * 1.6, 0.45)` (outer ring), await 0.45 s, apply outer AoE damage.

### Phase-Change HUD Updates

`Arena._on_final_boss_phase_changed(phase)` handles:
- Phase 2: announce "Final Boss Enraged!", call `hud.update_boss_phase(2)`, `boss_health_bar.show_phase(2)`, camera shake.
- Phase 3: boss-specific announcement (see identities table in README), call `hud.update_boss_phase(3)`, `boss_health_bar.show_phase(3)`, camera shake.

`GameHUD.update_boss_phase(phase)` updates the final boss label to `"Boss: <name>  [P2]"` or `"[P3]"` with amber/red color.

`BossHealthBar.show_phase(phase)` updates the PhaseLabel text and modulate color.

### Cleanup Invariant

`Arena._cleanup_boss_controller()` calls `controller.stop()` and nulls `_boss_controller`. It is called in:
- `_on_restart_requested()`
- `_on_quit_to_menu_requested()`
- `_on_confirm_dialog_confirmed()` for both "restart_run" and "quit_to_menu" cases.

`FinalBossController.stop()` sets `_stopped = true` and `_encounter_state = "defeated"`. All `await` loops check `_stopped` or `not is_instance_valid(self)` before each attack.

### Debug

`EnemySpawner.debug_get_boss_state()` calls `_boss_controller.debug_get_boss_state()` (if valid) and enriches the dict with `arena_active` and `boss_spawned`.

`DebugStatsOverlay.setup_boss_controller(controller)` is called by Arena after `_on_final_boss_spawned()`. The Boss section shows: ID, encounter_state, phase, HP%, current_attack, cooldown_remaining, is_attacking, arena_active. If the controller is freed the section shows `(no boss)`.

### Rules

- **No arena hazards.** Do not add collision shapes, damage zones, floor traps, or environmental damage.
- Do not change hero kits, evolutions, upgrades, stage objectives, saves, rewards, meta progression, or 4/4/4 slot rules.
- Projectile count per attack is capped (`aimed_barrage ≤ 20`, `ring_barrage = 10`).
- Phase 3 is a continuation — it does not re-spawn the boss or restart the encounter.
- `FinalBossController` is auto-freed as a child of the boss enemy; all its state is run-only.

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
- Vanguard keeps the `vanguard` id and is an original rage bruiser: close-range splash melee autoattack (`splash_melee`), Rage passive (builds from damage taken and damage dealt, decays over time, increases all damage up to 1.45× at max), Rage Wave (slot 1, circle AoE + slow), Mighty Clap (slot 2, cone AoE + knockback), Rage Leap (slot 3, dash + landing AoE + slow). Attack grid (9 lines): `splash_melee_damage`, `splash_melee_radius`, `splash_melee_speed`, `splash_melee_impact`, `splash_melee_frenzy`, `splash_melee_shockwave`, `splash_melee_lifesteal`, `splash_melee_combo`, `splash_melee_execute`. Active grid (9 lines, 3 per ability): `rage_wave_power/radius/deep_slow`, `mighty_clap_power/range/shockwave`, `rage_leap_power/radius/cooldown`. Removed lines (effects merged): `rage_wave_cooldown` → merged into `rage_wave_deep_slow`; `rage_wave_chain` → merged into `rage_wave_radius` and `rage_wave_deep_slow`; `mighty_clap_cooldown` → merged into `mighty_clap_shockwave`. Generic attack upgrades `attack_damage_up`, `attack_speed_up`, and `attack_range_up` are excluded from Vanguard (`hero_exclude: ["guardian", "vanguard"]`). Vanguard is excluded from all projectile-count, pierce, bounce, spread, multishot, and old nova/laser/slam ability upgrade lines.
- Vanguard upgrade grid schema rule: every Vanguard-only upgrade line must carry `upgrade_line_id`, `source_type` ("autoattack" or "ability"), `source_skill_id`, `grid_index` (1–9 unique per slot_category), `evolution_role` ("attack" or "active"), `hero_only: ["vanguard"]`. Active lines must also carry `evolution_target_active_skill`. Grid validation target: exactly 9 attack lines and 9 active lines for Vanguard.
- Vanguard new PlayerAutoAttack effect hooks: `splash_melee_shockwave_enabled` (bool, schedules a 0.5× AoE at 1.5× splash radius 0.18s after the swing), `splash_melee_lifesteal` (float, HP = value × enemies hit via `Player.heal()`), `splash_melee_combo_enabled` (bool) + `splash_melee_combo_bonus` (float, stacks up to 5 per 3s window), `splash_melee_execute_threshold` (float 0–0.6, 45% bonus to enemies at or below this HP ratio).
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

### 3/3/3 Triple Grid Schema

- `EvolutionManager` owns the triple definitions (27 total: 9 per hero), triple state computation, selection tracking, validation, debug output, and runtime-only application routing.
- Each hero has exactly 9 triples with `grid_index` 1-9 and a target distribution of exactly 3 `attack`, 3 `active`, and 3 `passive` evolutions.
- A triple still binds exactly 1 attack upgrade line + 1 passive upgrade line + 1 active upgrade line. All 3 required lines must be selected and maxed before the triple can become ready.
- Each hero attack line, each shared passive line, and each hero active line is used exactly once in that hero's triple grid.
- Triple definitions use `target_type` (`"attack"`, `"active"`, `"passive"`) and `target_id` (primary weapon id, active skill id, or passive id). Legacy `target_active_skill_id` is treated as `target_type: "active"` plus `target_id` for backward compatibility.
- `effect_status: "placeholder"` marks schema-only entries. Placeholder or otherwise unimplemented evolutions must not be offered in Overdrive or EvolutionRewardScreen.

### Triple Definition Schema

Each triple definition contains:
- `triple_id`: unique string slug.
- `hero_id`: `guardian`, `blaster`, or `vanguard`.
- `grid_index`: int 1-9, unique per hero.
- `attack_line_id`: hero-specific attack `upgrade_line_id`.
- `passive_line_id`: shared passive `upgrade_line_id`.
- `active_line_id`: hero-specific active `upgrade_line_id`.
- `target_type`: `attack`, `active`, or `passive`.
- `target_id`: evolved attack / active skill / passive skill id.
- `target_active_skill_id`: optional legacy active target field; kept only for compatibility on active targets.
- `evolution_id`: unique string slug for the evolved path.
- `title`, `description`, `effect_status`, and `required_levels`.

### Validation Rules

`EvolutionManager.validate_evolution_grid(hero_id, strict)` must check:
- exactly 9 triples per hero.
- exactly 3 attack, 3 active, and 3 passive targets per hero.
- no duplicate `grid_index`, `evolution_id`, `attack_line_id`, `passive_line_id`, or `active_line_id` per hero.
- valid `target_type` and non-empty `target_id`.
- active targets match real active source ids, attack targets match real attack source ids, and passive targets match real passive ids from `UpgradeManager.get_upgrade_definition_summary()`.
- implemented evolutions have target-matching handlers; no offerable implemented evolution may be a no-op.
- selected evolutions still match a real triple and a handler for their target type.

### Runtime State Rules

- `EvolutionManager.setup(player, auto_attack, ability_manager, upgrade_manager, passive_ability_manager = null)` wires run-only node refs. Hero data is read from `upgrade_manager.hero_data`.
- `EvolutionManager.reset_run_state()` clears `_selected_evolutions`; Arena scene reload also resets state naturally.
- `get_triple_state(hero_id)` returns `{triple_id -> state_dict}` with `state`, `selected_lines_count`, `maxed_lines_count`, `target_type`, `target_id`, `effect_status`, and `required_lines`.
- `get_evolution_type_counts(hero_id)` and `get_selected_evolution_type_counts(hero_id)` expose attack/active/passive counts for debug UI.
- Evolution state is runtime-only. Do not save selected evolutions, target counts, or placeholder state to meta, preferences, rewards, or any persistent file.

### apply_evolution() Routing

- `EvolutionManager.apply_evolution(evolution_id)` finds the triple, routes by `target_type`, and marks SELECTED only if the effect handler succeeds.
- `active` routes to `AbilityManager` and currently preserves the six implemented active effects through existing boolean flags.
- `attack` routes to `PlayerAutoAttack.apply_attack_evolution(evolution_id, target_id)`; implemented handlers return true and unknown or placeholder ids return false without marking selected.
- `passive` routes to `PassiveAbilityManager.apply_passive_evolution(evolution_id, target_id)`; implemented handlers return true and unknown ids return false without marking selected.
- Unknown `target_type`, missing handler, or placeholder effect must return false and must not silently apply a no-op.

### Overdrive and UI

- **OverdriveScreen** (`scenes/ui/OverdriveScreen.gd/.tscn`) is runtime-instantiated by Arena. It shows the evolution type label (ATTACK / ACTIVE / PASSIVE EVOLUTION), target type/name, title, description, required-line titles, current/max levels, and selected/maxed state. Keep the screen scrollable and readable in mobile landscape.
- `EvolutionManager.get_overdrive_options()` returns READY, not-yet-selected triples for the active hero, filtered to `effect_status: "implemented"` only.
- `EvolutionManager.get_synergy_info_for_upgrade_line(line_id)` and `get_evolution_grid_display_state(hero_id = "")` are read-only UI planning APIs. They may expose matching triples, missing line titles, ready/selected counts, target type, and closest progress, but must not apply effects, select upgrades, alter slot state, save data, or change eligibility rules.
- Arena may enrich LevelUpScreen option dictionaries with `evolution_synergy` hint data immediately before display. LevelUpScreen must treat those fields as display-only and still emit the original upgrade id.
- DebugStatsOverlay shows ready/selected totals, Attack / Active / Passive target and selected counts, selected attack evolution ids from `PlayerAutoAttack.debug_get_attack_evolutions()`, and selected passive evolution ids/titles from `PassiveAbilityManager.get_passive_state()`.
- BuildSlotsWindow remains read-only slot display. It may show applied evolution titles, ready count, selected count, closest triple progress, per-slot evolution hints, and compact progress/ready blocks, but must not mutate evolution state or slot rules.
- OverdriveScreen is blocking: no skip/close-without-selection while visible.
- Arena must block BuildSlotsWindow/PauseMenu interaction while OverdriveScreen is visible and close OverdriveScreen on victory, defeat, restart, and quit-to-menu. Evolution state is never persisted.

### Implemented Attack Evolution IDs

The Attack Evolutions Pack is implemented in `PlayerAutoAttack.gd`. These effects must be game-breaking behavior changes with obvious visuals/status text, not simple stat-only bonuses:

| evolution_id | hero_id | target_type | target_id |
|---|---|---|---|
| `solar_beam_sky_lance` | guardian | attack | `solar_ray` |
| `solar_beam_burning_judgment` | guardian | attack | `solar_ray` |
| `frost_breath_glacier_front` | guardian | attack | `solar_ray` |
| `smoke_screen_tactical_cover` | blaster | attack | `homing_rockets` |
| `smoke_screen_choking_zone` | blaster | attack | `homing_rockets` |
| `trap_cluster_minefield` | blaster | attack | `homing_rockets` |
| `rage_wave_earthsplitter` | vanguard | attack | `splash_melee` |
| `rage_wave_crushing_storm` | vanguard | attack | `splash_melee` |
| `mighty_clap_seismic_fan` | vanguard | attack | `splash_melee` |

Attack evolution state is runtime-only in `PlayerAutoAttack`; it is cleared on new run/restart through fresh Arena setup and `set_primary_weapon()`. Never save attack evolution state to meta, preferences, settings, rewards, or any persistent file.

### Implemented Active Evolution IDs

The Active Evolutions Pack is implemented in `AbilityManager.gd`. These effects must be game-breaking behavior changes with obvious visuals/status text, not simple stat-only bonuses:

| evolution_id | hero_id | target_type | target_id |
|---|---|---|---|
| `solar_beam_cataclysm` | guardian | active | `solar_beam` |
| `frost_breath_absolute_zero` | guardian | active | `frost_breath` |
| `death_dash_solar_execution` | guardian | active | `death_dash` |
| `smoke_screen_blackout` | blaster | active | `smoke_screen` |
| `trap_chain_detonation_evolution` | blaster | active | `explosive_trap` |
| `hook_execution_pull` | blaster | active | `grappling_hook` |
| `rage_wave_worldbreaker` | vanguard | active | `rage_wave` |
| `mighty_clap_thunderclap` | vanguard | active | `mighty_clap` |
| `rage_leap_meteor_crash` | vanguard | active | `rage_leap` |

The real active grid ids for the Final Flash and Rampage Impact effects are `death_dash_solar_execution` and `mighty_clap_thunderclap`. Active evolution state is runtime-only in `AbilityManager`; flags are set by `EvolutionManager.apply_evolution()` and reset by `AbilityManager.set_hero_kit()`.

### Implemented Passive Evolution IDs

The Passive Evolutions Pack is implemented in `PassiveAbilityManager.gd`. These effects must be game-breaking behavior changes with obvious visuals/status text, not simple stat-only bonuses:

| evolution_id | hero_id | target_type | target_id |
|---|---|---|---|
| `frost_breath_permafrost` | guardian | passive | `orbit_shields` |
| `death_dash_comet_path` | guardian | passive | `storm_relay` |
| `death_dash_final_flash` | guardian | passive | `recovery_field` |
| `trap_marked_blast` | blaster | passive | `guardian_drone` |
| `hook_shadow_line` | blaster | passive | `chain_lightning` |
| `hook_rapid_abduction` | blaster | passive | `time_dilator` |
| `mighty_clap_rampage_impact` | vanguard | passive | `static_field` |
| `rage_leap_blood_crater` | vanguard | passive | `battle_focus` |
| `rage_leap_final_impact` | vanguard | passive | `magnet_core` |

Passive evolution state is runtime-only in `PassiveAbilityManager`: `_selected_passive_evolutions` and `_passive_evolution_targets` are cleared by `cleanup()` and fresh Arena setup. Never save passive evolution state to meta, preferences, settings, rewards, stage data, or user files. Passive evolutions may read AbilityManager state such as Solar Empowered, Tactical Mark, or Rage, but PassiveAbilityManager owns the evolved passive behavior.

### Other Rules

- EvolutionRewardScreen is display-only for legacy evolution reward flow; OverdriveScreen is the triple-grid path.
- Arena coordinates opening screens, pausing/resuming, applying selected evolutions, and announcements.
- Miniboss defeat remains the main evolution reward path for legacy evolutions; elite rewards are optional through `elite_reward_chance` and default to off.
- Placeholder evolutions must not be offered. Do not add persistence, meta-progression, evolution unlock storage, evolution art assets, slot-rule changes, rewards changes, stage changes, enemy changes, boss-flow changes, or Build Evolution unless explicitly requested.

## Meta Progression Architecture

- `Main` owns `MetaProgressionManager`, `PostRunRewardsScreen`, and `MetaUpgradeShop`. All three are loaded and instantiated at runtime in `Main._ready()` via `load().instantiate()` — do not add them to Main.tscn directly.
- `Arena` emits `run_result_ready(summary: Dictionary)` before pausing the tree for the V/GO result screen. Arena never calls MetaProgressionManager directly.
- `Main._on_run_result_ready(summary)` calls `MetaProgressionManager.apply_run_result(summary)`, stores the reward data, and marks rewards as pending (`_rewards_shown = false`).
- When the player clicks Restart or Menu from the V/GO screen, Main intercepts via `_check_and_show_rewards(pending_action)`. If rewards have not been shown, it re-pauses the tree, opens PostRunRewardsScreen, and defers the action as `_pending_action`.
- `PostRunRewardsScreen.continue_requested` → Main hides the screen, unpauses, and executes the pending action (`_do_restart_run` or `_do_quit_to_menu`).
- `MetaApplier.apply_meta_progression(meta_manager, player, auto_attack, ability_manager)` is called by Arena after `_apply_selected_hero`, applying bonuses in this order: GameplayTuning → HeroApplier → MetaApplier. MetaApplier is loaded dynamically via `load("res://scenes/meta/MetaApplier.gd")`.
- `MetaUpgradeShop` emits `buy_requested(hero_id, upgrade_id)` → `Main._on_meta_buy_requested(hero_id, upgrade_id)` → `MetaProgressionManager.purchase_training_upgrade(hero_id, upgrade_id)`. The shop is display-only outside that Training buy intent.
- `MainMenu` emits `meta_shop_requested` → `Main._open_meta_shop()` hides MainMenu and opens MetaUpgradeShop. Shop back → `Main._close_meta_shop()` closes shop and re-shows MainMenu.
- `CharacterSelect.setup(hero_data_provider, meta_progression_manager)` accepts optional MetaProgressionManager. If provided and `is_hero_unlocked()` returns false, the hero button shows "[LOCKED — N currency]" and the start button is disabled. Currently all heroes are `unlocked_by_default: true` so no locking occurs in practice.
- `Player.pickup_radius_bonus` is a `@export float = 0.0`. `ExperienceGem._update_target_player()` reads it safely via `player_node.get("pickup_radius_bonus") or 0.0` to extend the magnet radius without hard coupling.
- Current `MetaProgressionManager` save format is JSON version 4. Keys include `currency`, `meta_upgrades`, `training_by_hero`, `equipment_by_hero`, `unlocked_heroes`, lifetime totals, `hero_mastery`, `stage_mastery`, and `goals`.
- Save migration must preserve existing currency, per-hero Training, unlocked heroes, lifetime totals, hero mastery, stage mastery, and goals. Version 4 adds default `equipment_by_hero` dictionaries when old saves are loaded.
- `Arena._build_run_summary()` adds objective result, final boss result, applied evolution count/titles/type counts, selected Attack/Passive/Active line counts, dominant archetype, and `run_grade`. Arena still never writes meta state directly.
- `MetaProgressionManager.apply_run_result(summary)` is the only owner for persistent hero mastery, stage mastery, goal evaluation, and post-run currency reward application.
- Hero mastery fields per hero: `runs_played`, `victories`, `kills`, `elite_kills`, `miniboss_kills`, `final_boss_kills`, `evolutions_selected`, `attack_evolutions_selected`, `active_evolutions_selected`, `passive_evolutions_selected`, and `highest_mastery_level`.
- Stage mastery fields per stage: `attempts`, `victories`, `objective_completions`, `final_boss_kills`, `best_grade`, and `best_time`.
- Goal definition schema: `id`, `title`, `description`, `category` (`hero`, `stage`, `evolution`, `boss`, or `general`), `reward_currency`, and `progress_target`. Goal progress API returns those fields plus `completed`, `claimed`, and `progress_current`.
- Goal rewards are auto-claimed inside `apply_run_result()` on the run that completes them. They are added to the post-run `total_reward` once, returned in `newly_completed_goals`, and persisted as `completed=true`, `claimed=true`.
- `MetaUpgradeShop` may show compact read-only goal progress from `get_goal_progress()`, but must not claim rewards, mutate goals, or change Training purchase rules.
- Post-run progression patches must not change combat balance, hero kits, evolution requirements, upgrade effects, stage objectives, enemies, boss flow, save data carelessly, or 4/4/4 slot rules.
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

## Character Equipment Foundation Architecture

- Each hero has exactly six fixed equipment items, one per slot: `core`, `suit`, `emblem`, `gauntlets`, `boots`, and `artifact`.
- Equipment definition schema lives in `MetaProgressionManager` dictionaries with `equipment_id`, `hero_id`, `slot_id`, `slot_name`, `display_name`, `description`, `max_level`, `base_cost`, `cost_growth`, `stat_bonus_type`, `stat_bonus_per_level`, and `tier`.
- Fixed hero equipment ids:
  - Guardian: `solar_core`, `radiant_suit`, `sun_emblem`, `power_gauntlets`, `flight_boots`, `aegis_artifact`.
  - Blaster: `tactical_core`, `shadow_suit`, `signal_emblem`, `gadget_gauntlets`, `grapnel_boots`, `drone_artifact`.
  - Vanguard: `rage_core`, `titan_suit`, `war_emblem`, `impact_gauntlets`, `heavy_boots`, `fury_artifact`.
- Persistent levels live in `equipment_by_hero`, shaped as `equipment_by_hero[hero_id][equipment_id] = level`. Defaults are `0`.
- `MetaProgressionManager` exposes read-only equipment APIs: `ensure_equipment_data_for_hero`, `ensure_equipment_data_for_all_heroes`, `get_equipment_definitions`, `get_equipment_definition`, `get_equipment_level`, `get_equipment_levels_for_hero`, `get_equipment_summary_for_hero`, and `debug_get_equipment_summary`.
- `can_purchase_equipment_upgrade` and `purchase_equipment_upgrade` are inert stubs that return `false` until a future explicit equipment upgrade patch.
- Equipment levels do not apply gameplay stats, rewards, Training costs, hero unlocks, gacha, inventory, item drops, swapping, or 4/4/4 in-run slot rules in this patch.

## Training Screen Two-Panel Layout Architecture

- `MetaUpgradeShop` uses a two-panel layout under the header: left panel = Character Equipment preview; right panel = Training Upgrades scroll list.
- **Header** (above both panels): title label, currency label, hero selector `HBoxContainer`, goals label.
- **Left panel** (`_build_equipment_panel()`): "Equipment" section title, hero preview (`PanelContainer` with color swatch, display name, subtitle, status), a slot grid (`HBoxContainer` with left column + center spacer + right column), and a note label.
- **Right panel** (`_build_training_panel()`): "Training Upgrades" section title, `ScrollContainer` containing `_list_vbox` with upgrade rows. This is identical to the previous single-panel list.
- **Slot grid layout**: left column holds Core/Suit/Emblem; right column holds Gauntlets/Boots/Artifact. Each slot is a `PanelContainer` with slot name, hero-specific display name, `Level current / max`, stat bonus text, and a disabled "Upgrade coming next" button.
- **Hero preview** updates via `_refresh_equipment_panel()` on every `refresh()` call and on hero switch. It reads `display_name`, `subtitle`/`playstyle`, and `color` from `_get_selected_hero_data()`.
- **Equipment rules for this patch**: slot levels are stored as foundation data only; no equipment purchase flow, no equipment stat application, no inventory, no item drops, no swapping, no gacha. Slots are display-only.
- `_get_selected_hero_data()` returns the selected hero dict from `_heroes` (already loaded via `HeroDataProvider`), with fallback to `_hero_data_provider.get_hero()`.
- `_update_equipment_slots()` reads `MetaProgressionManager.get_equipment_definitions(_selected_hero_id)` and `get_equipment_level()` only. Missing equipment data falls back to safe placeholder text.
- Existing Training buy flow (`_on_buy_pressed`, `_on_buy_pressed.bind(upgrade_id)`, `buy_requested.emit`) is unchanged.
- `open(hero_id)`, `close()`, `setup(meta_progression_manager, hero_data_provider)`, `refresh()`, `set_selected_hero(hero_id)` API unchanged.
- Signals `back_requested` and `buy_requested(hero_id, upgrade_id)` unchanged.
- Row flash on purchase (`_flash_row`) unchanged.
- Main.gd Training open/close flow unchanged.

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
  - `"splash_melee"` → `_tick_splash_melee()` — direct `take_damage()` on all enemies within `splash_melee_radius` of the player; no projectile spawned. Damage scales with Rage via `get_rage_damage_multiplier()` and an optional combo multiplier. Reports hits back to AbilityManager via `add_rage(rage_per_hit)`. Applies per-hit knockback, execute bonus, lifesteal, combo stack tracking, and schedules a shockwave ring if their respective flags/thresholds are set.
  - empty / unknown → `_tick_solar_bolt(enemy)` — standard projectile spawn via `_spawn_projectiles()` (fallback).
- Stable upgrade hooks that must not be renamed: `attack_damage`, `attack_interval`, `attack_range`, `projectile_count`, `projectile_pierce`, `projectile_size_multiplier`, `projectile_explosion_radius`, `projectile_bounce`, `projectile_speed`. All apply on top of weapon defaults regardless of weapon mode.
- Projectile-specific upgrades (`projectile_count`, `projectile_pierce`, `projectile_bounce`, `projectile_explosion_radius`, `projectile_size_multiplier`, `projectile_speed`) do not crash `splash_melee`; they simply have no effect since no projectile is spawned. Vanguard has `hero_exclude` on all projectile-category upgrade definitions so they never appear in the pool.
- `PlayerAutoAttack` splash_melee `@export` properties: `splash_melee_radius: float`, `splash_melee_knockback: float`, `splash_melee_shockwave_enabled: bool`, `splash_melee_lifesteal: float`, `splash_melee_combo_enabled: bool`, `splash_melee_combo_bonus: float`, `splash_melee_execute_threshold: float`. Runtime state: `_splash_combo_stacks: int`, `_splash_combo_decay_timer: float` (combo resets after 3s with no hit).
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
- Current layout: Settings button is top-left; Help / Controls button is top-right; Select Hero, Training, and Collection are horizontal neighbors in the bottom interface.
- The centered header panel keeps the SuperHeroes title, subtitle, and remembered `Last: Hero / Stage` hint.
- MainMenu reworks must not rename existing button signals or change Main's navigation ownership without a specific flow reason.
- Layout-only patches must not change gameplay balance, hero/stage data, rewards, runtime persistence, debug behavior, or add arena hazards.
- Do not directly copy licensed superhero names, characters, brands, or logos.

## Main Menu Collection Entry Architecture

- `MainMenu` emits `collection_requested` when the Collection button is pressed (after `_play_ui_click()`).
- `Main._show_main_menu()` connects `collection_requested` → `_open_hero_collection()` each time a new MainMenu is instantiated.
- `Main._init_hero_collection_screen()` loads and instantiates `HeroCollectionScreen.tscn` once at startup, calls `setup(meta_progression_manager, hero_data_provider)`, then connects `back_requested` → `_close_hero_collection()`.
- `Main._open_hero_collection()` guards against opening over Settings, Help, Training/MetaUpgradeShop, CharacterSelect, StageSelect, or RunBriefingScreen. If the guard passes it hides MainMenu and calls `hero_collection_screen.open()`.
- `Main._close_hero_collection()` calls `hero_collection_screen.close()` and shows MainMenu again.
- `Main._handle_menu_back_requested()` checks `_is_hero_collection_open()` after `_is_meta_shop_open()` so ESC / ui_cancel closes the Collection screen and returns to MainMenu.
- `HeroCollectionScreen` must remain pre-game only. It must not pause gameplay, affect in-run state, mutate saves, apply rewards, or open during a live run.
- Collection remains read-only. Do not add gacha pulls, shards, equipment grid/upgrade controls, inventory, or monetization.

## Hero Collection Screen Architecture

- `HeroCollectionScreen.setup(meta_progression_manager, hero_data_provider)` stores both refs. Call it once after instantiating the screen (in `Main._init_hero_collection_screen()`). Setup is safe to call before `_ready()` fires because it only stores refs.
- `open()` calls `_refresh()` (rebuilds card list, updates summary, restores selection), then `show()` and grabs focus on the Back button. This ensures the card list reflects the current meta/unlock state each time the screen opens.
- Hero cards are built in `_rebuild_card_list()` by iterating `HeroDataProvider.get_all_heroes()`. Each owned hero becomes a clickable `Button`; after the hero list, 3 disabled locked placeholder buttons are appended for future gacha heroes.
- Owned/locked state: `_check_owned(hero)` prefers `MetaProgressionManager.is_hero_unlocked(hero_id)` and falls back to `hero.unlocked_by_default`. Never mutates unlock state.
- Card selection via `_select_hero(hero_id)` updates `_selected_hero_id`, refreshes highlight colours on all card buttons, updates the detail panel, and emits `hero_selected(hero_id)`.
- Detail panel (`_update_detail_panel`) reads directly from the hero dictionary (color, name, subtitle, playstyle, description, ability_kit, primary_weapon, ability_names) and from `MetaProgressionManager.get_hero_mastery_summary()` for mastery stats (level, runs, victories). It never writes to any manager.
- Summary label (top-right) shows "Owned: N / Total  |  Currency: C" derived from the same read-only API calls.
- Placeholder locked cards: 3 disabled Buttons with fixed text "??? Locked Hero / Future hero  |  LOCKED". They must not be selectable, must not populate the detail panel, and must have no hero_id.
- `hero_selected(hero_id)` is emitted on card click but is NOT connected to CharacterSelect or any run-start flow. It is available for future in-Collection detail expansion only.
- Do not add gacha banner, shard cost, pull button, equipment grid, equipment upgrade controls, inventory, or hero unlock purchase UI in this screen. Those are future patches.

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
- Arena coordinates the level-up flow; LevelUpScreen and GameHUD are display-only. Arena may attach read-only evolution hint dictionaries to upgrade options after `UpgradeManager.get_upgrade_options()` returns them, but this must not alter option selection, weights, prerequisites, slot usage, or upgrade ids.
- `BuildSlotsWindow` is display-only and reads `UpgradeManager.get_slot_state()` plus `get_upgrade_definition_summary(upgrade_id)`; it may also read `EvolutionManager` progress hint APIs for labels, but it must not parse history manually or mutate upgrade/evolution state.
- Arena owns BuildSlotsWindow setup/open/close, modal blocking, and pause/resume safety. Opening the window pauses active gameplay; closing resumes only when no other blocking modal is open.
- MobileControls only emits `build_slots_pressed`; it must not inspect or mutate build state.
- Pause/Build buttons stay visible on desktop and mobile. Joystick, dash, and ability buttons remain touch/forced-mobile controls.
- DebugStatsOverlay may read `UpgradeManager.debug_get_slot_state()` and display selected upgrade ids by category, but must never mutate slot state.
- Slot state remains runtime-only and resets with each fresh Arena/UpgradeManager run.
- Hero-specific upgrade rewrites are not included in this patch.
- No Build Evolution in this patch.

## Passive Ability System Foundation

- `PassiveAbilityManager` is instantiated at runtime by `Arena._setup_passive_ability_manager()` using `load("res://scenes/passives/PassiveAbilityManager.gd").new()`. It is not part of Arena.tscn.
- `PassiveAbilityManager.setup(player, enemy_container, projectile_container, pickup_container, feedback_manager)` wires run references only. It owns `add_or_upgrade_passive(passive_id)`, `apply_passive_evolution(evolution_id, target_id)`, `has_passive_evolution(evolution_id)`, `debug_get_passive_evolutions()`, `get_passive_level(passive_id)`, `has_passive(passive_id)`, `get_passive_state()`, and `cleanup()`.
- Passive state is runtime-only. Selected passive ids/levels, timers, shield regeneration state, passive evolution ids/targets, and pickup radius bonuses must reset every run and must never be written to meta saves, settings, rewards, user preferences, or stage data.
- Current shared passive lines are exactly `orbit_shields`, `storm_relay`, `guardian_drone`, `magnet_core`, `chain_lightning`, `recovery_field`, `battle_focus`, `static_field`, and `time_dilator`. They are shared by all heroes and must not depend on hero kit identity.
- Passive abilities must provide visible gameplay feedback, not only hidden numeric state.
- Orbit Shields visuals must track `PlayerBuffManager.shield_changed` / `get_shield_charges()` so consumed and regenerated charges are visible around the player.
- Storm Relay, Guardian Drone, Chain Lightning, Battle Focus, Static Field, and Time Dilator must show clear hit or pulse feedback when they affect enemies, such as Line2D arcs, pulse rings, status text, and damage/heal text.
- Magnet Core must either rely on pickup scripts reading `player.pickup_radius_bonus` or provide an explicit runtime pull fallback; upgrades should show clear selection feedback.
- Passive upgrade definitions live in `UpgradeManager.gd` with the Shared Passive Skills 9-Line Pack schema fields, `tags` containing `"passive"`, conservative `max_level`, a display `description_template`, and normal weighting/archetype fields.
- `UpgradeManager` now supports passive upgrades by passing passive ids to `PassiveAbilityManager.add_or_upgrade_passive()`. Existing attack upgrades, active ability upgrades, hero-flavored text, synergy upgrades, and build-defining upgrades must keep their ids and behavior.
- `LevelUpScreen` may display passive options with a compact `PASSIVE` marker, but it remains display-only.
- `DebugStatsOverlay` may read `PassiveAbilityManager.get_passive_state()` for ids/levels/timers. It must never mutate passive or gameplay state.
- Slot limits are implemented in `UpgradeManager`; passive visibility hotfixes should preserve those limits rather than reimplementing them elsewhere.
- Hero-specific attack/active grid rewrites are not included in the shared passive pack.
- Passive evolutions are selected through Overdrive and routed by EvolutionManager; OverdriveScreen remains display-only and uses the existing PASSIVE EVOLUTION label path.

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
- Grunt is available from run start, Runner opens after about 30 seconds, Charger after about 45 seconds, Tank after about 60 seconds, Shooter after about 75 seconds, Exploder after about 120 seconds, Swarm after about 150 seconds, Shielded after about 180 seconds, Support after about 210 seconds, Splitter after 240 seconds, and Disruptor after 300 seconds.
- Variant XP values are copied onto the dropped `ExperienceGem`.
- Enemies should spawn near the player using `EnemySpawner` ring spawn, but never directly on top of the player.

## Run Director / Wave Director Architecture

`SpawnDirector` is the single source of truth for all enemy spawning difficulty. `EnemySpawner` calls its APIs and drives timers; `SpawnDirector` never spawns enemies directly. Future systems (Enemy Roles Pack, Stage Objectives Pack) must integrate through `SpawnDirector`, not alongside it. Do not add arena hazards unless explicitly requested.

### Phase Model

The 10-minute run is split into 5 named phases. Each phase definition contains `id`, `start_time`, `spawn_pressure_multiplier`, `max_alive_multiplier`, `wave_interval_multiplier`, and `preferred_roles`. Phases are stored in `SpawnDirector.RUN_PHASES` (constant array).

| Phase | Start | Spawn pressure | Wave interval mult |
|-------|-------|---------------|-------------------|
| early | 0 s | ×0.75 | ×1.3 |
| build | 120 s | ×0.9 | ×1.1 |
| pressure | 240 s | ×1.1 | ×0.95 |
| danger | 360 s | ×1.3 | ×0.85 |
| pre_boss | 480 s | ×1.5 | ×0.75 |

Phase API:
- `get_current_run_phase() -> String` — current phase id
- `get_current_phase_data() -> Dictionary` — full phase dict
- `get_phase_progress() -> float` — 0.0–1.0 within current phase
- `debug_get_run_director_state() -> Dictionary` — run_time, phase, phase_progress, spawn_interval, max_alive, wave_interval, last_wave_package, stage_profile, wave_budget_remaining
- `debug_get_wave_state()` is kept as an alias for backward compat.

### Spawn Pressure

`get_spawn_interval()` lerps base interval over 600 s (not 240 s), divides by `spawn_pressure_multiplier`, and applies event modifiers. Hard floor: 0.20 s. Result: early ~2.0 s between spawns, pre_boss approaches the hard floor.

### Wave Packages

`SpawnDirector.WAVE_PACKAGES` defines each package with: `id`, `role`, `variant_pool`, `min_count`, `max_count`, `weight`, `profile_bonus`, **plus** `phase_weights` (per-phase multiplier dict), `budget_cost`, `min_phase`, `max_phase`, `warning_level`, `warning_text`, `package_cooldown`.

`get_wave_package()` pipeline:
1. Filter by `min_phase` / `max_phase` (using phase_order index comparison).
2. Filter by `package_cooldown` (`_package_last_fired` tracks last selection time per id).
3. Filter by `budget_cost ≤ _wave_budget_remaining`.
4. Weight by `phase_weights[current_phase]` × `profile_bonus[stage_profile]`.
5. Weighted-random select; deduct budget; update cooldown tracker; fire wave warning if applicable.
6. Fallback to all available packages (no budget filter) if nothing fits — never returns empty if any package is unlocked.

`get_wave_interval()` returns `maxf(11.0 × wave_interval_multiplier, 5.0)`.

### Wave Budget

`PHASE_WAVE_BUDGETS` dict maps phase id → max budget float. Budget resets when setup() is called (run start). Packages deduct their `budget_cost` on selection. Budget prevents unbounded heavy-package spam per phase.

### Wave Warnings

`_maybe_fire_wave_warning(package)` fires a brief `EventAnnouncement.show_announcement()` for packages with `warning_level ≥ 1`. Enforces 12 s cooldown between warnings via `_last_warning_time`. No-ops if `_event_announcement` is null or lacks `show_announcement` — safe to call always.

### Stage Profiles

`_stage_profile_weight_bonuses` maps stage profile id → per-variant weight dict. `set_stage_profile(profile)` stores the profile; `_get_modified_weight()` applies variant-level bonuses for individual spawns; `profile_bonus` in each package applies package-level bonuses. Stubs exist for "defense_pressure" and "portal_pressure" (no bonuses yet).

### EnemySpawner Integration

- `EnemySpawner._wave_timer` fires `_on_wave_timer_timeout()` which calls `get_wave_package()` then `_spawn_from_package(package)`.
- Max alive cap is checked before each enemy in both the SpawnTimer path and the wave package path — no burst can overflow the cap.
- `EnemySpawner.debug_get_spawn_state()` calls `debug_get_run_director_state()` to populate `stage_profile`, `phase`, and `wave_budget` fields.
- `setup()` signature: `spawn_director.setup(run_manager, event_announcement)` — Arena passes its `event_announcement` node.
- Miniboss and final boss spawning remain unchanged: triggered by EventDirector and EnemySpawner dedicated methods, not by wave packages.

### Debug Overlay

`DebugStatsOverlay` Spawner section shows: `Phase: <id>  Profile: <profile>`, `MaxAlive: N  Budget: X.X`, `Interval: X.XX  WaveEvery: Xs`, `Last pkg: <id>`. All fields degrade gracefully if SpawnDirector is missing.

### Not Yet Implemented (do not add proactively)

- Stage Objectives Pack (defense / portal objective types)
- Boss Encounter 2.0
- Arena hazards

## Enemy Roles + Counterplay

### Role Metadata Fields

Every variant dict in `SpawnDirector._get_available_variants()` carries:
- `role` — machine-readable role id (swarmer, hunter, bruiser, shooter, disruptor)
- `role_display_name` — human-readable label
- `threat_level` — integer 1–5
- `counterplay_hint` — short hint string

`Enemy.gd` stores `role: String` (set in `apply_variant` when key present). All other metadata keys are informational and stay in the dict only.

### Supported behavior_id Values

| behavior_id | Owner | Description |
|-------------|-------|-------------|
| chase | Enemy.gd | Straight-line chase toward player |
| charger | Enemy.gd | Approach then charge at speed × multiplier with windup |
| shooter | Enemy.gd | Approach to preferred_distance, stop, fire projectiles |
| exploder | Enemy.gd | Chase, trigger on proximity, scale-pulse windup, explode |
| swarm | Enemy.gd | Orbit + approach; alternates between closing and circling |
| support | Enemy.gd | Stay near enemies; periodically buff speed + damage in radius |
| disruptor | Enemy.gd | Approach to standoff; pulse cyan + deal area damage every disrupt_interval |

### Splitter Safety Rules

- `split_on_death: bool` and `split_variant_id: String` are @export vars on Enemy.gd read via `apply_variant`.
- `is_split_child: bool` — when true, the enemy never spawns children on death (prevents recursion).
- `split_count` is hard-capped at 3 inside `EnemySpawner._spawn_split_children()`.
- `_spawn_split_children()` checks `_can_spawn()` and `max_alive` before each child — no cap overflow.
- Split children inherit the full enemy scene with `is_split_child = true` and `split_on_death = false` injected into the variant dict before spawning.
- Splitter uses `behavior_id = "chase"` — no new behavior needed.
- Split children are NOT spawned during the final boss encounter (`_can_spawn()` returns false).

### Disruptor Safety Rules

- `behavior_id = "disruptor"` is implemented in `Enemy.gd._tick_disruptor_behavior()`.
- Maintains `disrupt_standoff` distance from the player; approaches until within standoff, then stops.
- Every `disrupt_interval` seconds: fires `_fire_disrupt_pulse()` — cyan color flash, then `target.take_damage(disrupt_damage)` if player is within `disrupt_radius`.
- No slow, no arena hazard, no permanent modifier. Effect is instant and fully avoidable by distance.
- `_disrupt_pulse_tween` is killed before creating a new one — no tween leak.

### EnemySpawner Split Integration

- `EnemySpawner._on_enemy_died()` reads `split_on_death`, `is_split_child`, `split_variant_id`, `split_count` from the enemy node **before** it is freed.
- If split is needed, `call_deferred("_spawn_split_children", position, variant_id, count)` runs after the death feedback.
- `_spawn_split_children()` calls `spawn_director.get_enemy_variant_by_id(variant_id)` — always succeeds for "grunt" since `get_enemy_variant_by_id` passes `9999.0` seconds.
- Split children go through the normal `_spawn_enemy_with_variant()` path: they get XP gems, death bursts, and powerup rolls like any other enemy. Split children are not guaranteed powerup drops.

### DebugStatsOverlay Role Counts

`EnemySpawner.debug_get_spawn_state()` now includes `role_counts: Dictionary` — maps role string → alive count by iterating `enemy_container` children. `DebugStatsOverlay` shows this as `Roles: swarm:3  hunt:2  brus:1` (truncated to 4 chars). Safe if enemy_container is invalid.

### SpawnDirector Wave Packages for Roles

New packages added alongside the existing ones:
- `charger_rush` — hunter; build+ phase; cooldown 16 s
- `splitter_wave` — swarmer; danger+ phase; cooldown 22 s; budget 3.0
- `disruptor_squad` — disruptor; danger+ phase; cooldown 20 s; budget 2.5
- `chaos_wave` — mixed (charger+disruptor+splitter); pre_boss only; cooldown 28 s; budget 3.5

### No Arena Hazards

Do not add arena hazards in this project. Disruptor, Exploder, and Support create temporary in-game pressure via behavioral effects — they are not persistent world objects.

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
- The shared passive target is now implemented as the Shared Passive Skills 9-Line Pack below. Solar Guardian and Night Tactician attack/active grid normalization are both implemented; do not add Fury Vanguard attack/active grid normalization unless explicitly requested.

## Solar Guardian Upgrade Grid

- Guardian strict grid target is exactly 9 Attack lines and exactly 9 Active lines. Use `UpgradeManager.validate_upgrade_grid_for_hero("guardian", true)` as the release gate for this slice.
- Guardian Attack lines are exactly: `solar_ray_damage`, `solar_ray_range`, `solar_ray_width`, `solar_ray_pierce_burn`, `solar_ray_tick_rate`, `solar_ray_empowered_bonus`, `solar_ray_lingering_heat`, `solar_ray_focus`, and `solar_ray_execution`.
- Guardian Active lines are exactly: `solar_beam_damage_up`, `solar_beam_range_up`, `solar_beam_overheat`, `frost_breath_power`, `frost_breath_cone_up`, `frost_breath_freeze`, `death_dash_power`, `death_dash_distance`, and `death_dash_cooldown_down`.
- Every Guardian Attack line must include `hero_only: ["guardian"]`, `slot_category: "attack"`, `upgrade_line_id`, `source_type: "autoattack"`, `source_skill_id: "solar_ray"`, unique `grid_index` 1-9, `evolution_role: "attack"`, and tags containing weapon/solar/beam or equivalent.
- Every Guardian Active line must include `hero_only: ["guardian"]`, `slot_category: "active"`, `upgrade_line_id`, `source_type: "ability"`, `source_skill_id` for `solar_beam`, `frost_breath`, or `death_dash`, unique `grid_index` 1-9, `evolution_role: "active"`, `evolution_target_active_skill`, and ability/skill tags.
- Guardian must not receive projectile-count-only, multishot, spread, projectile-speed, projectile-pierce, bounce, rocket-only, melee, or rage-only upgrade lines. Generic duplicate autoattack damage/speed/range lines are also excluded from Guardian so the Solar Ray grid stays exactly 9 lines.
- Shared passive skills remain shared and available to Guardian; do not make shared passive lines Guardian-specific.
- This grid prepares future Evolution triples, but this patch does not implement new `EvolutionManager` behavior, Evolution triples, Overdrive UI, evolved active skills, rewards, saves, meta economy, enemies, stages, boss flow, hero kits, primary weapon identity, Build Evolution, or 4/4/4 slot-rule changes.

## Night Tactician Upgrade Grid

- Blaster strict grid target is exactly 9 Attack lines and exactly 9 Active lines. Use `UpgradeManager.validate_upgrade_grid_for_hero("blaster", true)` as the release gate for this slice.
- Blaster Attack lines are exactly: `rocket_damage`, `rocket_count`, `rocket_explosion_radius`, `rocket_reload`, `marked_target_payload`, `rocket_seek_range`, `rocket_split`, `rocket_cluster_payload`, and `rocket_priority_targeting`.
- Blaster Active lines are exactly: `smoke_screen_radius`, `smoke_screen_duration`, `smoke_screen_slow`, `trap_damage`, `trap_radius`, `trap_chain_detonation`, `hook_damage`, `hook_range`, and `hook_cooldown_down`.
- Deprecated lines `smoke_screen_damage_reduction`, `trap_cooldown_down`, `trap_mark_bonus`, and `hook_mark_bonus` carry `hero_exclude: ["blaster"]` and must never appear in the blaster grid count.
- Every Blaster Attack line must include `hero_only: ["blaster"]`, `slot_category: "attack"`, `upgrade_line_id`, `source_type: "autoattack"`, `source_skill_id: "homing_rockets"`, unique `grid_index` 1-9, `evolution_role: "attack"`, and tags containing weapon/rocket/tactical or equivalent.
- Every Blaster Active line must include `hero_only: ["blaster"]`, `slot_category: "active"`, `upgrade_line_id`, `source_type: "ability"`, `source_skill_id` for `smoke_screen`, `explosive_trap`, or `grappling_hook`, unique `grid_index` 1-9, `evolution_role: "active"`, `evolution_target_active_skill`, and ability/skill tags.
- `rocket_seek_range` uses the legacy match block in `apply_upgrade()` (no `effects` array) to call `refresh_attack_range()` after updating `attack_range`. It must not gain an `effects` array unless the legacy block is removed.
- `rocket_priority_targeting_enabled` is an `@export var bool` on PlayerAutoAttack; when true, `_tick_homing_rockets` partitions `valid_enemies` into marked-first order before round-robin assignment.
- `explosive_trap_chain_enabled` is an `@export var bool` on AbilityManager; when true, `_trigger_explosive_trap` collects and erases nearby traps from `_active_explosive_traps` before recursively triggering each chained trap.
- Blaster must not receive Solar Guardian, Vanguard, pierce, melee, rage, or splash-melee-only upgrade lines. Shared passive skills remain shared and available.
- This grid prepares future Evolution triples but does not implement `EvolutionManager`, Evolution triples, Overdrive UI, evolved active skills, rewards, saves, meta economy, enemies, stages, boss flow, hero kits, weapons, or 4/4/4 slot-rule changes.

## Shared Passive Skills 9-Line Pack

- Shared passive ids are exactly: `orbit_shields`, `storm_relay`, `guardian_drone`, `magnet_core`, `chain_lightning`, `recovery_field`, `battle_focus`, `static_field`, and `time_dilator`.
- Passive upgrade definitions must include `id`, `title`, `rarity`, `weight`, `max_level`, `description_template`, `type: "passive"`, `category: "passive"`, `slot_category: "passive"`, `upgrade_line_id`, `source_type: "passive"`, `source_skill_id`, `grid_index`, `evolution_role: "passive"`, and `tags` containing `passive`.
- Passive `grid_index` values must be unique and cover 1 through 9. Passive `upgrade_line_id` values must also be unique.
- Passive lines are shared by Solar Guardian, Night Tactician, and Fury Vanguard. Do not add `hero_id`, `hero_ids`, `hero_only`, or hero-specific filtering to shared passive lines unless a future task explicitly changes that rule.
- Passive state is runtime-only and must reset on restart, victory, defeat, quit, or Arena reload. Do not save passive levels, timers, buffs, or visuals.
- Every shared passive must be visible in gameplay through shield markers, arcs, pulse rings, floating damage/heal/status text, or equivalent built-in feedback.
- The 4 passive slot limit still applies: a new passive line consumes a Passive slot, while already selected passive lines can continue leveling after Passive slots are full.
- This pack does not add Night/Fury 9 attack grids, Night/Fury 9 active grids, new EvolutionManager behavior, Overdrive UI, evolved active skills, rewards, saves, meta economy, enemies, stages, boss flow, hero kits, primary weapons, or 4/4/4 slot-limit changes.

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
