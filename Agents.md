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
- `scenes/settings/SettingsManager.tscn` - local settings manager scene.
- `scenes/settings/SettingsManager.gd` - `user://settings.cfg` load/save helper for settings only.
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
- `scenes/ui/MainMenu.gd` - main menu start and quit intent signals.
- `scenes/ui/CharacterSelect.tscn` - hero selection screen between MainMenu and Arena.
- `scenes/ui/CharacterSelect.gd` - display-only hero list/details UI; emits selected hero id.
- `scenes/ui/PauseMenu.tscn` - pause-time run menu scene.
- `scenes/ui/PauseMenu.gd` - pause menu resume, restart, and quit intent signals.
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
- `docs/validation/gameplay_validation.md` - manual test checklist for all gameplay systems (debug keys, powerups, abilities, weapon upgrades, build archetypes, miniboss, run flow, run victory, expected console log patterns).

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

## Run Victory Architecture

- `RunManager` owns the run objective state (is_final_phase_active, has_victory, elite_kill_count, miniboss_kill_count, target_run_time, final_phase_start_time).
- `Arena` owns screen coordination: connects RunManager signals, builds enriched run summaries, and shows/hides VictoryScreen and GameOverScreen.
- `VictoryScreen` and `GameOverScreen` are display-only — they show stats and emit intent signals only.
- `Main` owns scene replacement for restart and main menu navigation.
- Run summary is built by `Arena._build_run_summary(base_stats)` on both victory and defeat and is not persisted.
- Final phase: `RunManager` emits `final_phase_started` → Arena shows announcement → Arena calls `EventDirector.start_final_phase_event()` → EventDirector applies pressure modifier via SpawnDirector.
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
- HeroDataProvider owns hardcoded hero dictionaries for now; do not migrate to Resources until explicitly requested.
- HeroApplier applies run-only selected hero stats to Player, AutoAttack, and AbilityManager.
- Arena stores selected hero data for the active run summary and HUD display.
- Restart from GameOver/Victory should reuse the same selected hero id; Quit to Menu should allow choosing a different hero next run.
- Do not persist selected hero or add hero unlocks/meta-progression unless explicitly requested.

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
- Nova Pulse active ability (slot 1).
- Laser Beam active ability (slot 2): line damage in aim direction.
- Hero Slam active ability (slot 3): close-range burst.
- 3-slot ability cooldown HUD display.
- Nova Pulse, Laser Beam, Hero Slam visual feedback (built-in nodes only).
- Laser Beam and Hero Slam runtime upgrades (damage, cooldown, width/radius).
- Player.get_aim_direction() for Laser Beam targeting.
- Mobile ability buttons for all 3 slots.
- Virtual joystick mobile movement foundation.
- Mobile Nova Pulse button.
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

## Frontend Flow

- Main owns frontend flow and run scene replacement.
- Main owns SettingsManager and AudioManager.
- MainMenu emits `start_requested`; it does not start Arena directly.
- Arena emits `restart_run_requested` and `quit_to_menu_requested`.
- PauseMenu only emits UI intents.
- GameOver restart goes through Arena/Main, not direct scene reload.

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
- Slot 1: Nova Pulse uses `ability_1` (J) — radial area damage.
- Slot 2: Laser Beam uses `ability_2` (K) — line damage in player's aim direction.
- Slot 3: Hero Slam uses `ability_3` (L) — close-range burst damage.
- All abilities are available from run start; no unlock system.
- HUD listens to `ability_cooldown_changed` and displays readiness for all 3 slots.
- MobileControls emits ability intents (ability_1/2/3_pressed) only; Arena wires them to AbilityManager.
- GameHUD displays ability states only; no gameplay logic.
- Cooldowns pause naturally while the tree is paused.
- `Player.get_aim_direction()` returns the last non-zero movement direction; Laser Beam uses this as its cast direction.
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
- `MobileControls` emits a movement signal instead of moving the Player directly.
- Arena wires `MobileControls.movement_changed` to `Player.set_external_move_vector`.
- Arena wires `ability_1_pressed` → `AbilityManager.cast_ability_1`.
- Arena wires `ability_2_pressed` → `AbilityManager.cast_ability_2`.
- Arena wires `ability_3_pressed` → `AbilityManager.cast_ability_3`.
- Arena wires the mobile pause button to the same pause-open handler as keyboard pause.
- `MobileControls` listens to `ability_cooldown_changed` and updates all 3 button texts.

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
- Player owns the Camera2D shake helper.
- Feedback scenes use built-in nodes only and do not own gameplay rules.

## Not Implemented Yet

- Reroll, skip, or banish upgrade actions.
- Upgrade icons.
- Upgrade codex or full upgrade history UI.
- Hero unlocks.
- Hero portraits.
- Hero-specific unique abilities.
- Persistent selected hero.
- Weapon/ability evolution.
- Stage selection.
- Arena hazards.
- Persistent builds or meta-progression.
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
- Persistent records.
- Persistent high scores or saved run history.
- Persistent progression.
- Save persistence.
- Meta-progression.
- Yandex SDK integration.
- Ads, payments, monetization, leaderboards, or saves.

## Validation Notes

- Use debug tools (F3–F8) to verify gameplay systems before adding new content.
- Keep POWERUP_WIRING / POWERUP_ROLL / POWERUP_SPAWNED diagnostics available behind `powerup_debug_logging`.
- docs/validation/gameplay_validation.md is the canonical manual test checklist; update it when systems change.
- Run `godot --headless --editor --quit` from the repo root to confirm no parse errors after every patch.

## Development Rules

- README.md and Agents.md must be updated on every task.
- docs/validation/gameplay_validation.md must be updated for new gameplay flows.
- Do not add persistence unless explicitly requested.
- Do not add arena hazards.
- Do not add meta-progression or persistence.
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
- Do not use Yandex storage until explicitly requested.
- Do not add real audio assets unless explicitly requested.
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
- Restart button reloads the current run.
- No script errors appear.
