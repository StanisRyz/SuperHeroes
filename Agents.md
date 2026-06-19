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
- `scenes/debug/DebugManager.tscn` - runtime-only debug input manager scene.
- `scenes/debug/DebugManager.gd` - F12/F1 debug mode input and debug signals.
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
- `scenes/enemies/EnemySpawner.gd` - spawn loop, spawn distance checks, max alive enemy limit, XP drops.

## Implemented Systems

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

- DebugManager handles F12/F1 input during an active Arena run.
- DebugManager requires `debug_toggle` and `debug_level_up` InputMap actions and should ignore key echo.
- DebugOverlay only displays DEBUG ON and does not own debug rules.
- Player owns `debug_invulnerable` and `debug_gain_one_level()`.
- Arena wires DebugManager to Player and DebugOverlay.
- Debug Mode is runtime-only, not persisted, and not exposed in SettingsMenu.
- Do not add debug cheats unless explicitly requested.

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
- Bosses/minibosses.
- Elite modifiers.
- Wave announcements.
- Biome or arena progression.
- Persistent records.
- Persistent high scores or saved run history.
- Persistent progression.
- Save persistence.
- Meta-progression.
- Yandex SDK integration.
- Ads, payments, monetization, leaderboards, or saves.

## Development Rules

- Inspect the current project before changing files.
- Do not duplicate existing systems.
- Keep patches small and focused.
- Update `README.md` and `Agents.md` on every task.
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
