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
- `scenes/game/RunManager.gd` - run timer, kill counter, and run end signal.
- `scenes/abilities/AbilityManager.tscn` - player active ability manager scene (3 slots wired).
- `scenes/abilities/AbilityManager.gd` - 3-slot active ability logic, Nova/Laser/Slam, cooldown tracking, cast signals.
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
- `scenes/upgrades/UpgradeManager.gd` - hardcoded upgrade definitions, option weighting, upgrade levels, and application logic.
- `scenes/ui/GameHUD.tscn` - player HP, XP, time, and kill counter HUD scene.
- `scenes/ui/GameHUD.gd` - player and run HUD binding.
- `scenes/ui/MobileControls.tscn` - mobile virtual joystick and 3 ability buttons scene.
- `scenes/ui/MobileControls.gd` - mobile movement and ability button signal source (ability_1/2/3_pressed).
- `scenes/ui/MainMenu.tscn` - frontend main menu scene.
- `scenes/ui/MainMenu.gd` - main menu start, settings, training, help, and quit intent signals.
- `scenes/ui/ControlsHelpOverlay.tscn` - reusable help and controls CanvasLayer scene.
- `scenes/ui/ControlsHelpOverlay.gd` - display-only help overlay API (`open`, `close`, `toggle`, `is_open`) and close handling.
- `scenes/ui/ControlsHelpContent.gd` - centralized help content sections.
- `scenes/ui/ConfirmDialog.tscn` - reusable pause-safe confirmation CanvasLayer scene for active-run destructive actions.
- `scenes/ui/ConfirmDialog.gd` - display-only confirmation dialog API (`open`, `close`, `is_open`, `get_action_id`) and confirmed/cancelled action-id signals.
- `scenes/ui/CharacterSelect.tscn` - hero selection screen between MainMenu and Arena.
- `scenes/ui/CharacterSelect.gd` - display-only hero list/details UI; emits selected hero id.
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
- `scenes/ui/DebugStatsOverlay.gd` - live debug stats panel: player HP/level/XP/speed/dash, weapon stats, ability cooldowns/damage/synergy flags, build archetype/points/synergies/build-defining picks, buff/shield state, spawner wiring. Refreshes every 0.25s while visible. Display-only; never mutates gameplay state.
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
- `scenes/stages/StageDataProvider.gd` - dictionary-backed City Rooftop / Neon Lab / Wasteland Gate stage presets. Returns stage dicts with id, display_name, difficulty_label, display-only identity metadata, background_colors, run_settings, event_profile, final_boss_id.
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

## Stage & Final Boss Architecture

- `Main` owns the navigation flow: MainMenu → CharacterSelect → StageSelect → Arena. Back from StageSelect returns to CharacterSelect. Restart keeps same hero + stage. Quit to menu clears both.
- `StageDataProvider` is a persistent Node in Main (child of Main.tscn). It owns stage definitions and is passed to StageSelect.setup().
- `StageApplier` (static) is called by Arena._ready() after GameplayTuning.apply_to() when stage_data is non-empty. It applies background colors, run settings, and event/spawn profiles.
- StageSelect is display-only: it may show stage cards, remembered-stage markers, color swatches, threat summaries, run objectives, recommended playstyle, and boss previews, but it must not mutate stage data or gameplay state.
- Stage identity metadata in StageDataProvider is for UI presentation only. Do not wire `threat_summary`, `stage_goal`, `recommended_playstyle`, `enemy_pressure`, or `boss_preview` into spawn logic, run settings, rewards, persistence, or final boss behavior.
- StageSelect must emit the original stable stage id (`city_rooftop`, `neon_lab`, or `wasteland_gate`) when Start Run is pressed.
- Do not add arena hazards unless the user explicitly requests hazards.
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
- Guardian is an original solar/flying powerhouse fantasy with strength, beam, durability, and aerial-impact presentation.
- Guardian may override ability display names through hero data, but global input slots and ability ids must stay stable.
- Blaster keeps the `blaster` id and is an original dark gadget tactician fantasy with precision tools, tactical mobility, controlled burst damage, and close control presentation.
- Blaster may override ability display names through hero data as Smoke Charge, Grapnel Shot, and Shock Trap, but global input slots and ability ids must stay stable.
- Vanguard keeps the `vanguard` id and is an original rage bruiser fantasy with durability, heavy impact, leap-like presentation, close-range fury, and ground-smash presentation.
- Vanguard may override ability display names through hero data as Rage Burst, Crushing Leap, and Titan Slam, but global input slots and ability ids must stay stable.
- Final hero roster ids and display names: `guardian` = Solar Guardian, `blaster` = Night Tactician, `vanguard` = Fury Vanguard.
- Final hero ability display names: Solar Guardian = Solar Burst / Solar Beam / Aerial Impact; Night Tactician = Smoke Charge / Grapnel Shot / Shock Trap; Fury Vanguard = Rage Burst / Crushing Leap / Titan Slam.
- Hero-specific ability display names must come from hero data and flow through HeroApplier/AbilityManager or direct hero data reads in display-only roster UI.
- UI, HUD, mobile controls, debug overlays, and debug logs must prefer hero-specific ability display names from AbilityManager state instead of hardcoded global ability labels.
- Level-up option descriptions may substitute hero-specific ability display names at presentation time, but upgrade ids, archetypes, effects, weights, and save-facing data must stay stable.
- Hero-specific upgrade flavor is display-only. Upgrade ids, effects, weights, rarity, max levels, prerequisites, archetype points, synergies, build-defining logic, and selected upgrade history remain shared and stable.
- LevelUpScreen must always store and emit the original `upgrade_id`; flavored titles/descriptions must never become gameplay identifiers.
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
- Mobile pause button.
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
- `UpgradeManager` returns option dictionaries with title, rarity, level info, max level, and dynamic description.
- `LevelUpScreen` displays option dictionaries from `UpgradeManager` while paused.
- Arena applies the selected upgrade through `UpgradeManager`.
- Arena unpauses gameplay.

## UpgradeManager V3 Notes

- Upgrade definitions remain hardcoded dictionaries (not Resource assets).
- Each upgrade now optionally carries `archetype`, `tags`, `prerequisites`, `tier`, and `unlock_hint` fields.
- Supported archetypes: `projectile`, `nova`, `laser`, `slam`, `dash`, `tank`, `speed`, `utility`.
- `archetype_points: Dictionary` tracks how many upgrades per archetype the player has taken this run.
- `selected_upgrade_history: Array[Dictionary]` stores compact history entries (id, title, archetype, level_after_pick, tags).
- Both are run-only state — they reset naturally when Arena reloads. Not saved to disk.
- `build_changed(dominant_archetype, points)` signal is emitted after every successful upgrade application.
- Build-aware weighted selection: archetype bias multiplier = `1.0 + min(archetype_points * 0.12, 0.6)`. The system remains non-deterministic.
- Diversity protection: `get_upgrade_options` tries to ensure at least 1 option from outside the dominant archetype when enough off-archetype candidates exist.
- Synergy upgrades carry a `prerequisites` dictionary with optional keys: `archetype_points` (AND), `upgrade_levels` (AND), `any_archetype_points` (OR), `any_upgrade_levels` (OR), and `any_of` (OR over nested prerequisite dictionaries).
- `is_upgrade_available` checks max_level AND prerequisites. Locked synergy upgrades never appear in the option pool.
- Synergy upgrades use an `effects: Array[Dictionary]` field; `_apply_effects_array` handles bool/int/float properties, supports `add`, `subtract`, `multiply`, and `set`, applies optional min/max clamping, and fails safely on invalid target/property/operation.
- Build-defining synergy upgrades set `is_build_defining = true`; LevelUpScreen appends `BUILD DEFINING`, and DebugStatsOverlay reports selected/available build-defining counts.
- Build-defining v4 upgrades: Aftershock Zone, Double Pulse, Seismic Echo, Comet Dash, and Bouncing Bolts.
- Base upgrades retain their `effect_value` + match-statement path unchanged.
- `heroic_endurance` uses the existing `_apply_max_health_upgrade` helper via the match statement.
- Public methods added: `get_archetype_points`, `get_dominant_archetype`, `get_selected_upgrade_history`, `get_upgrade_definition_summary`.
- Prerequisite helpers: `_meets_prerequisites`, `_get_tag_count`, `_get_archetype_count`, `_has_upgrade_level`.
- Debug helpers (not bound to keys): `debug_get_available_upgrade_ids`, `debug_print_upgrade_pool`.
- `LevelUpScreen._format_option_text` now shows `[RARITY] [ARCHETYPE]`, appends `SYNERGY` for synergy upgrades, and appends `BUILD DEFINING` for build-defining upgrades.
- `GameHUD` connects to `build_changed` via `setup_upgrade_manager(upgrade_manager)` and displays "Build: Archetype" or "Build: Mixed".
- Arena calls `hud.setup_upgrade_manager(upgrade_manager)` inside `_setup_level_up_flow` after `upgrade_manager.setup(...)`.
- UpgradeManager remains the owner of the upgrade pool and all run build state.
- Arena coordinates the level-up flow; LevelUpScreen and GameHUD are display-only.

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

- `SpawnDirector` owns time-based spawn scaling and variant selection.
- `EnemySpawner` spawns enemies and drops XP, but should not own long-term difficulty design.
- Enemy variants are currently hardcoded dictionaries, not Resources.
- Enemy variant dictionaries include `behavior_id`.
- Spawn interval and max alive enemy limits scale from run time.
- Grunt is available from run start, Runner opens after about 30 seconds, Charger after about 45 seconds, Tank after about 60 seconds, Shooter after about 75 seconds, Exploder after about 120 seconds, Swarm after about 150 seconds, Shielded after about 180 seconds, and Support after about 210 seconds.
- Variant XP values are copied onto the dropped `ExperienceGem`.
- Enemies should spawn near the player using `EnemySpawner` ring spawn, but never directly on top of the player.

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
- Slot 1 uses `ability_1` (J) with hero-specific display text and radial area damage.
- Slot 2 uses `ability_2` (K) with hero-specific display text and line damage in player's aim direction.
- Slot 3 uses `ability_3` (L) with hero-specific display text and close-range burst damage.
- All abilities are available from run start; no unlock system.
- HUD listens to `ability_cooldown_changed` and displays readiness for all 3 slots.
- MobileControls emits ability intents (ability_1/2/3_pressed) only; Arena wires them to AbilityManager.
- GameHUD displays ability states only; no gameplay logic.
- Cooldowns pause naturally while the tree is paused.
- `Player.get_aim_direction()` returns the last non-zero movement direction; slot 2 uses this as its cast direction.
- Ability enemy scans happen only on cast, not every frame.
- Ability synergy delayed hits are owned by AbilityManager and stay anchored to their original cast origin/direction.
- Nova Aftershock uses `NovaAftershockFeedback`; Laser Double Pulse and Slam Second Wave reuse the existing Laser/Slam feedback scenes at the delayed cast position.

## Build Synergy v4 Notes

- `AbilityManager` owns Nova Aftershock, Laser Double Pulse, and Slam Second Wave runtime state/effects.
- `Player` owns dash damage trail state and applies the Comet Dash damage burst when dash ends.
- `PlayerAutoAttack` owns bounce configuration and passes it into spawned `PlayerProjectile` instances.
- `PlayerProjectile` owns per-projectile bounce target selection and never damages the same enemy twice from the same projectile instance.
- `UpgradeManager` owns all build-defining unlock rules and effect application.
- `LevelUpScreen`, `GameHUD`, and `DebugStatsOverlay` are display-only for build/synergy information.

## Input Flow

- Keyboard movement and ability input still use the Godot InputMap.
- `help_toggle` uses H with F11 fallback and opens/closes the Help / Controls overlay where allowed.
- `MobileControls` emits a movement signal instead of moving the Player directly.
- Arena wires `MobileControls.movement_changed` to `Player.set_external_move_vector`.
- Arena wires `ability_1_pressed` → `AbilityManager.cast_ability_1`.
- Arena wires `ability_2_pressed` → `AbilityManager.cast_ability_2`.
- Arena wires `ability_3_pressed` → `AbilityManager.cast_ability_3`.
- Arena wires the mobile pause button to the same pause-open handler as keyboard pause.
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
- Stun or knockback from abilities.
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
- Exploder enemies.
- Swarm/orbit enemies.
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
