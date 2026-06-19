# Agents.md

## Project

SuperHeroes is a Godot 4.x GDScript project for Web / HTML5, with Yandex Games integration planned later.

The game is an original superhero survivors-like: the player moves around an arena, enemies chase the player, defeated enemies drop XP gems, and future milestones will add upgrades and active abilities.

## Important Files

- `scenes/main/Main.tscn` - project entry scene.
- `scenes/main/Main.gd` - frontend flow coordinator and run scene replacement.
- `scenes/settings/SettingsManager.tscn` - local settings manager scene.
- `scenes/settings/SettingsManager.gd` - `user://settings.cfg` load/save helper for settings only.
- `scenes/audio/AudioManager.tscn` - audio playback manager scene.
- `scenes/audio/AudioManager.gd` - volume/mute application and optional SFX playback hooks.
- `scenes/debug/DebugManager.tscn` - runtime-only debug state manager scene.
- `scenes/debug/DebugManager.gd` - debug mode state and debug signals.
- `scenes/game/Arena.tscn` - arena composition.
- `scenes/game/Arena.gd` - arena bounds, player setup, spawner setup, level-up flow, run lifecycle.
- `scenes/game/RunManager.tscn` - runtime run state manager scene.
- `scenes/game/RunManager.gd` - run timer, kill counter, and run end signal.
- `scenes/abilities/AbilityManager.tscn` - player active ability manager scene.
- `scenes/abilities/AbilityManager.gd` - active ability input, Nova Pulse, cooldown tracking, and cast signals.
- `scenes/abilities/NovaPulseFeedback.tscn` - simple in-world Nova Pulse feedback scene.
- `scenes/abilities/NovaPulseFeedback.gd` - Nova Pulse feedback tween and cleanup logic.
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
- `scenes/projectiles/PlayerProjectile.gd` - projectile movement, lifetime, enemy hit damage, pierce, and explosion logic.
- `scenes/projectiles/EnemyProjectile.tscn` - enemy projectile scene.
- `scenes/projectiles/EnemyProjectile.gd` - non-homing enemy projectile damage and lifetime logic.
- `scenes/upgrades/UpgradeManager.tscn` - runtime upgrade manager scene.
- `scenes/upgrades/UpgradeManager.gd` - hardcoded upgrade definitions, option weighting, upgrade levels, and application logic.
- `scenes/ui/GameHUD.tscn` - player HP, XP, time, and kill counter HUD scene.
- `scenes/ui/GameHUD.gd` - player and run HUD binding.
- `scenes/ui/MobileControls.tscn` - mobile virtual joystick and Nova Pulse button scene.
- `scenes/ui/MobileControls.gd` - mobile movement and ability button signal source.
- `scenes/ui/MainMenu.tscn` - frontend main menu scene.
- `scenes/ui/MainMenu.gd` - main menu start and quit intent signals.
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
- `POWERUP_WIRING`, `POWERUP_ROLL`, `POWERUP_SPAWNED` diagnostics logs are intentionally active; remove only after drops are confirmed working in the target environment.
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
- AbilityManager on the player.
- Active ability input through `ability_1`.
- Nova Pulse active ability.
- Ability cooldown HUD display.
- Simple Nova Pulse visual feedback.
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
- A single `handled_debug_key` boolean prevents double-processing the same key press.
- Debug toggle supports F12 with F10 fallback; debug level supports F1 with F2 fallback.
- Debug level keys should not work while paused, game-over, level-up, or player-dead.
- DebugOverlay only displays DEBUG ON and does not own debug rules.
- Player owns `debug_invulnerable` and `debug_gain_one_level()`.
- Arena wires DebugManager to Player and DebugOverlay.
- Debug Mode is runtime-only, not persisted, and not exposed in SettingsMenu.
- Do not add debug cheats unless explicitly requested.

### Debug Diagnostics

- `DEBUG_INPUT:` — Arena prints raw key detection for F12/F10/F1/F2 on every non-echo press or release, before any condition checks.
- `DEBUG_WIRING:` — Arena prints whether DebugManager, DebugOverlay, and Player debug APIs were found and whether signals were connected.
- `DEBUG_MODE:` — DebugManager logs every toggle with the resulting enabled state.
- `DEBUG_LEVEL:` — DebugManager logs each request (accepted) or rejection with a short reason (disabled, tree paused, missing player, player dead).
- `DEBUG_PLAYER:` — Player logs `set_debug_invulnerable` changes and `debug_gain_one_level` level values.
- Diagnostic logs remain active until Debug Mode reliability is confirmed. Do not remove them prematurely.

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

## UpgradeManager V2 Notes

- Upgrade definitions are still hardcoded dictionaries, not Resource assets.
- Each upgrade has rarity, weight, max_level, current level, and effect_value.
- Maxed upgrades are excluded from future option rolls.
- Arena coordinates level-up pause/resume and does not own upgrade effects.

## Run Lifecycle

- `RunManager` tracks active run time and enemy kills.
- `EnemySpawner` reports enemy deaths to `RunManager`.
- Player emits `died` when health reaches zero.
- Arena ends the run, pauses the tree, hides level-up UI if needed, and shows `GameOverScreen`.
- `GameOverScreen` displays time survived, enemies defeated, and level reached.
- Restart emits through Arena/Main and creates a fresh run; it does not write saves, high scores, or meta-progression.

## Spawn Progression

- `SpawnDirector` owns time-based spawn scaling and variant selection.
- `EnemySpawner` spawns enemies and drops XP, but should not own long-term difficulty design.
- Enemy variants are currently hardcoded dictionaries, not Resources.
- Enemy variant dictionaries include `behavior_id`.
- Spawn interval and max alive enemy limits scale from run time.
- Grunt is available from run start, Runner opens after about 30 seconds, Charger after about 45 seconds, Tank after about 60 seconds, and Shooter after about 75 seconds.
- Variant XP values are copied onto the dropped `ExperienceGem`.

## Enemy Behavior Notes

- `behavior_id` comes from SpawnDirector variant dictionaries.
- `Enemy.gd` owns runtime behavior execution.
- SpawnDirector owns unlock timing and weighted selection.
- EnemySpawner should stay behavior-agnostic.
- EnemyProjectile should detect Player only.

## Active Ability Flow

- `AbilityManager` is a child of `Player`.
- Arena wires `AbilityManager` to the Player, EnemyContainer, HUD, and optionally UpgradeManager.
- Nova Pulse uses `ability_1`.
- HUD listens to `ability_cooldown_changed` and displays Nova Pulse readiness or remaining cooldown.
- Cooldowns pause naturally while the tree is paused.

## Input Flow

- Keyboard movement and ability input still use the Godot InputMap.
- `MobileControls` emits a movement signal instead of moving the Player directly.
- Arena wires `MobileControls.movement_changed` to `Player.set_external_move_vector`.
- Arena wires the mobile ability button to `AbilityManager.cast_ability_1`.
- Arena wires the mobile pause button to the same pause-open handler as keyboard pause.
- `MobileControls` may listen to AbilityManager cooldown changes to update its button text.

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
- Bounce projectiles.
- Chain lightning.
- Critical hits.
- Elemental/status effects.
- Projectile pooling.
- Dash damage.
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
- Mobile ability buttons for multiple abilities.
- Input rebinding.
- Character select.
- Multiple active abilities.
- Ability icons.
- Ability targeting indicators.
- Ability upgrade tree.
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

## Development Rules

- README.md and Agents.md must be updated on every task.
- Miniboss damage must always go through Player.take_damage() or existing EnemyProjectile collision logic.
- Do not re-enable Player/Enemy physical body collisions.
- Do not add persistence unless explicitly requested.
- Do not remove POWERUP_WIRING / POWERUP_ROLL / POWERUP_SPAWNED diagnostic logs until powerup drops are confirmed working.
- Inspect the current project before changing files.
- Do not duplicate existing systems.
- Keep patches small and focused.
- Update `README.md` and `Agents.md` on every task.
- Do not remove `DEBUG_INPUT`, `DEBUG_WIRING`, `DEBUG_MODE`, `DEBUG_LEVEL`, or `DEBUG_PLAYER` diagnostic logs until Debug Mode is confirmed working in the target environment.
- Do not add extra debug cheats unless explicitly requested.
- Enemy variants are currently dictionaries, not Resource assets.
- Keep long-term difficulty formulas in `SpawnDirector`, not `EnemySpawner`.
- Do not add monetization unless explicitly requested.
- Do not use copyrighted superhero names, brands, logos, or specific existing characters.
- Keep desktop browser and mobile landscape browser in mind.
- Keep 16:9 and wide 20:9 landscape layouts in mind.
- Do not add additional mobile ability buttons unless explicitly requested.
- Do not make `MobileControls` directly mutate gameplay except through signals.
- Do not add persistence unless explicitly requested.
- Do not use Yandex storage until explicitly requested.
- Do not add real audio assets unless explicitly requested.
- Do not add persistence for gameplay progression unless explicitly requested.
- Do not add bosses or elite systems unless explicitly requested.
- Do not re-enable Player/Enemy physical body collisions.
- Do not persist debug mode.
- Do not add debug cheats unless explicitly requested.

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
