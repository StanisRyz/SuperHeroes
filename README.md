# SuperHeroes

SuperHeroes is a Godot 4.x survivors-like / horde survival / bullet heaven game with an original superhero theme. The player moves through a large arena, fights chasing enemies, collects XP gems, and will later choose upgrades and use active abilities.

## Target Platform

- Godot 4.x
- GDScript
- Web / HTML5
- Yandex Games

## Supported Devices

- Desktop browser
- Mobile browser
- Landscape orientation

## Layout Assumptions

- Main target aspect ratio: 16:9.
- Wide landscape phones around 20:9 should not break the UI.
- Important UI should stay inside a central safe zone.

## Development Status

The project is currently in the foundation stage. It has the first playable loop pieces, projectile-based player autoattack, health feedback, and a basic XP pickup loop, but no level-up overlay, upgrades, manual abilities, mobile controls, or Yandex SDK integration yet.

Implemented foundation:

- Main scene.
- Arena scene with a large placeholder field.
- Player movement with WASD and arrow keys.
- Camera follow with arena limits.
- Arena bounds and player clamping.
- Enemy scene with simple chase behavior.
- EnemySpawner with timer-based spawning, spawn distance checks, an enemy container, and a max alive enemy limit.
- Basic HP/contact damage foundation for player and enemies.
- Projectile-based player autoattack that fires at the nearest enemy inside range.
- Player HP HUD.
- Enemy HP bars.
- Hit flash feedback when player or enemies take damage.
- XP gem drops after enemy death.
- XP pickup by the player.
- XP bar in the HUD.
- Player/enemy physical body collisions are separated so enemies do not push or displace the player.
- Enemy contact damage, projectiles, and XP pickups use Area2D detection.

Not implemented yet:

- Manual active abilities or ability buttons.
- Active abilities.
- Level-up overlay.
- Upgrade cards.
- Upgrade system.
- XP magnet/vacuum.
- Projectile upgrades such as pierce, bounce, or spread.
- Floating damage numbers.
- Game over screen.
- Mobile joystick.
- Yandex SDK integration.
- Ads, payments, or monetization.

## Architecture Principles

- Separate runtime state, config data, UI, gameplay formulas, and Yandex SDK calls.
- Keep patches small and focused.
- Avoid broad rewrites unless explicitly requested.
- Keep the superhero theme original. Do not use copyrighted superhero names, brands, logos, or specific existing characters.

## Validation

Run the Godot editor validation from the repository root:

```sh
godot --headless --editor --quit
```

## Web Export Notes

The Web export preset should export to:

```text
export/index.html
```

Test exported builds through a local web server instead of opening the HTML file directly:

```sh
cd export
python -m http.server 8000
```

## Yandex Games Notes

- Yandex SDK integration will be added later through a wrapper.
- Ads, payments, monetization, leaderboards, saves, and meta-progression are not implemented yet.
- Localhost SDK unavailability during development is acceptable.
