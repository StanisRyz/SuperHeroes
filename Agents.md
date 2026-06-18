# Agents.md

## Project

SuperHeroes is a Godot 4.x GDScript project for Web / HTML5, with Yandex Games integration planned later.

The game is an original superhero survivors-like: the player moves around an arena, enemies chase the player, and future milestones will add XP, upgrades, and active abilities.

## Important Files

- `scenes/main/Main.tscn` - project entry scene.
- `scenes/game/Arena.tscn` - arena composition.
- `scenes/game/Arena.gd` - arena bounds, player setup, spawner setup.
- `scenes/player/Player.tscn` - player scene with camera.
- `scenes/player/Player.gd` - movement, bounds clamp, health state.
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

## Not Implemented Yet

- Player attacks or autoattack.
- XP drops, pickups, level-up, or upgrades.
- Active abilities.
- HUD.
- Mobile joystick.
- Yandex SDK integration.
- Ads, payments, monetization, leaderboards, saves, or meta-progression.

## Development Rules

- Inspect the current project before changing files.
- Do not duplicate existing systems.
- Keep patches small and focused.
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
- No script errors appear.
