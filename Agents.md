# Agents.md

## Project

SuperHeroes is a Godot 4.x GDScript project for Web / HTML5, with Yandex Games integration planned later.

The game is an original superhero survivors-like: the player moves around an arena, enemies chase the player, defeated enemies drop XP gems, and future milestones will add upgrades and active abilities.

## Important Files

- `scenes/main/Main.tscn` - project entry scene.
- `scenes/game/Arena.tscn` - arena composition.
- `scenes/game/Arena.gd` - arena bounds, player setup, spawner setup, level-up flow, run lifecycle.
- `scenes/game/RunManager.tscn` - runtime run state manager scene.
- `scenes/game/RunManager.gd` - run timer, kill counter, and run end signal.
- `scenes/pickups/ExperienceGem.tscn` - XP pickup scene.
- `scenes/pickups/ExperienceGem.gd` - XP pickup collection logic.
- `scenes/projectiles/PlayerProjectile.tscn` - player autoattack projectile scene.
- `scenes/projectiles/PlayerProjectile.gd` - projectile movement, lifetime, and enemy hit damage.
- `scenes/upgrades/UpgradeManager.tscn` - runtime upgrade manager scene.
- `scenes/upgrades/UpgradeManager.gd` - hardcoded upgrade options and application logic.
- `scenes/ui/GameHUD.tscn` - player HP, XP, time, and kill counter HUD scene.
- `scenes/ui/GameHUD.gd` - player and run HUD binding.
- `scenes/ui/LevelUpScreen.tscn` - pause-time upgrade selection UI.
- `scenes/ui/LevelUpScreen.gd` - displays options and emits selected upgrade IDs.
- `scenes/ui/GameOverScreen.tscn` - pause-time game over UI.
- `scenes/ui/GameOverScreen.gd` - displays run stats and emits restart requests.
- `scenes/player/Player.tscn` - player scene with camera.
- `scenes/player/Player.gd` - movement, bounds clamp, health state.
- `scenes/player/PlayerAutoAttack.gd` - autoattack range tracking and periodic enemy damage.
- `scenes/enemies/Enemy.tscn` - enemy scene and contact damage area.
- `scenes/enemies/Enemy.gd` - chase movement, enemy health, contact damage.
- `scenes/enemies/EnemySpawner.tscn` - timer-based spawner scene.
- `scenes/enemies/EnemySpawner.gd` - spawn loop, spawn distance checks, max alive enemy limit.

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
- Level-up pause screen.
- Three-option upgrade selection.
- Basic run upgrades.
- Separated collision layers/masks to prevent Player and Enemy bodies from physically pushing each other.

## Level-Up Flow

- Player emits `level_up_available(level)` after XP crosses a threshold.
- Arena pauses the tree.
- Arena asks `UpgradeManager` for three options.
- `LevelUpScreen` displays options while paused.
- Arena applies the selected upgrade through `UpgradeManager`.
- Arena unpauses gameplay.

## Run Lifecycle

- `RunManager` tracks active run time and enemy kills.
- `EnemySpawner` reports enemy deaths to `RunManager`.
- Player emits `died` when health reaches zero.
- Arena ends the run, pauses the tree, hides level-up UI if needed, and shows `GameOverScreen`.
- `GameOverScreen` displays time survived, enemies defeated, and level reached.
- Restart reloads the current scene and does not write saves, high scores, or meta-progression.

## Collision Notes

- Player body uses the Player layer and should not physically collide with Enemy bodies.
- Enemy bodies use the Enemies layer and should not physically collide with Player or other Enemy bodies.
- Enemy contact damage is handled by `ContactDamageArea`, which detects Player bodies.
- Player autoattack range detects Enemy bodies through `Area2D`.
- Player projectiles detect Enemy bodies through `Area2D`.
- Experience gems detect Player bodies through `Area2D`.
- Do not re-enable Player/Enemy physical body collisions unless explicitly requested.

## Not Implemented Yet

- Upgrade icons, rarities, weights, or Resource-backed data.
- Active abilities.
- Projectile upgrades.
- XP magnet/vacuum.
- Floating damage numbers.
- Pause menu.
- Persistent high scores or saved run history.
- Meta-progression.
- Mobile joystick.
- Yandex SDK integration.
- Ads, payments, monetization, leaderboards, or saves.

## Development Rules

- Inspect the current project before changing files.
- Do not duplicate existing systems.
- Keep patches small and focused.
- Update `README.md` and `Agents.md` on every task.
- Do not add monetization unless explicitly requested.
- Do not use copyrighted superhero names, brands, logos, or specific existing characters.
- Keep desktop browser and mobile landscape browser in mind.
- Keep 16:9 and wide 20:9 landscape layouts in mind.

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
- Enemy contact reduces player health at the configured interval.
- Player autoattack fires visible projectiles toward the nearest valid enemy in range.
- Projectiles damage enemies on hit and expire after `max_lifetime` if they miss.
- Enemies eventually die and disappear after enough projectile hits.
- Player HP HUD updates when player health changes.
- Enemy HP bars update when enemies take damage.
- Player and enemies briefly flash when damaged.
- Dead enemies drop XP gems.
- Player collects XP gems by touching them.
- XP HUD updates after pickup.
- Run timer advances during gameplay.
- Enemy kill counter increases when enemies die.
- Player death pauses gameplay and shows the game over screen.
- Game over screen displays time survived, enemies defeated, and player level.
- Restart button reloads the current run.
- No script errors appear.
