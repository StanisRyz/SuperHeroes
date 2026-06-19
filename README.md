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

The project is currently in the foundation stage. It has the first playable loop pieces, projectile-based player autoattack, health feedback, XP pickup, a first level-up upgrade selection flow, basic run lifecycle handling, time-based spawn progression, the first active ability foundation, and basic mobile controls, but no Yandex SDK integration yet.

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
- Level-up pause screen.
- Three-option upgrade selection.
- Basic run upgrades for attack damage, attack speed, attack range, move speed, max HP, projectile speed, and Nova Pulse.
- Upgrade levels and max upgrade levels.
- Weighted upgrade option selection.
- Upgrade rarity labels.
- Dynamic upgrade descriptions.
- Run timer and enemy kill counter.
- Player death detection.
- Game over screen with current run stats.
- Restart current run from the game over screen.
- SpawnDirector with time-based spawn difficulty.
- Dynamic spawn interval and max alive enemy scaling.
- Enemy variants: Grunt, Runner, Tank, Charger, and Shooter.
- Spawn weighting by run time.
- Variant-based XP values.
- Player/enemy physical body collisions are separated so enemies do not push or displace the player.
- Enemy contact damage, projectiles, and XP pickups use Area2D detection.
- AbilityManager on the player.
- Active ability input through `ability_1`.
- Nova Pulse active ability.
- Ability cooldown display in the HUD.
- Simple in-world Nova Pulse visual feedback.
- Virtual joystick for mobile movement.
- Mobile Nova Pulse button.
- Keyboard and mobile input coexist.
- Mobile controls are hidden on desktop by default unless forced.
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
- Master, music, and SFX volume settings.
- Force mobile controls setting.
- Screen shake setting.
- AudioManager foundation.
- Enemy behavior expansion v1.
- Behavior IDs in SpawnDirector variants.
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

Not implemented yet:

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
- Reroll, skip, or banish upgrade actions.
- Upgrade icons.
- Resource-backed upgrade data files.
- XP vacuum upgrades.
- Projectile upgrades such as pierce, bounce, or spread.
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
- Ads, payments, leaderboards, saves, or monetization.

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
