# SuperHeroes

SuperHeroes is a Godot 4.x survivors-like / horde survival / bullet heaven game with an original superhero theme. The player moves through a large arena, fights chasing enemies, collects XP gems, chooses upgrades, and uses active ability foundations.

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
- AbilityManager on the player with 3 active ability slots.
- Active ability input through `ability_1` (J), `ability_2` (K), `ability_3` (L).
- Nova Pulse active ability (slot 1 / J): area damage within radius.
- Laser Beam active ability (slot 2 / K): line damage in front of player.
- Hero Slam active ability (slot 3 / L): close-range burst damage around player.
- 3-slot ability cooldown display in the HUD.
- Simple in-world Nova Pulse visual feedback.
- Laser Beam visual feedback (built-in Line2D beam with fade).
- Hero Slam visual feedback (built-in expanding ring with fade).
- Laser Beam and Hero Slam runtime upgrades (damage, cooldown, width/radius).
- Player exposes get_aim_direction() used by Laser Beam direction targeting.
- Virtual joystick for mobile movement.
- Mobile Nova Pulse button (ability_1).
- Mobile Laser Beam button (ability_2 / Beam).
- Mobile Hero Slam button (ability_3 / Slam).
- Mobile ability buttons show cooldown timers.
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
- Debug Mode toggle with F12, with F10 fallback for browser/editor cases.
- Debug Mode input actions for F12/F10 and F1/F2.
- DEBUG ON runtime overlay (CanvasLayer layer 10, bottom-left label).
- Debug Mode player invulnerability.
- F1 debug level gain while Debug Mode is enabled, with F2 fallback.
- F12/F1 may be intercepted by browsers or the editor, so fallback debug keys are supported.
- Runtime-only Debug Mode for development/testing, not progression.
- Arena coordinates Debug Mode input: raw F12/F10/F1/F2 detection prints to console before any condition checks.
- Debug toggle: F12 or F10 (direct key detection first, InputMap fallback).
- Debug level gain: F1 or F2, only while Debug Mode is enabled (direct key detection first, InputMap fallback).
- DebugManager logs mode changes and level-up accept/reject reasons to the console.
- Player logs debug invulnerability changes and level gains to the console.
- Debug diagnostic logs are intentionally kept active until debug reliability is confirmed.
- SettingsMenu works from both MainMenu and PauseMenu.
- MainMenu Settings is hidden before gameplay starts.
- Projectile pierce.
- Multishot.
- Projectile spread angle.
- Projectile size upgrade.
- Explosive projectile upgrade.
- Weapon modifier upgrades.
- Multishot uses a visible minimum spread by default when no spread upgrade is active.
- Projectile homing is disabled for spread and multishot shots so fired projectiles do not collapse back onto one line.
- Separate multishot projectile instances can damage the same enemy independently.
- Per-projectile hit lists only prevent duplicate hits from the same projectile instance.
- Weapon upgrade direction generation has a headless sanity check at `scripts/tests/WeaponUpgradeSanityCheck.gd`.

- PowerupPickup foundation (generic in-run pickup that delegates to PowerupManager).
- PowerupManager (applies powerup effects to player and world).
- PlayerBuffManager (owns timed buffs and shield charges).
- Heal pickup (restores 25 HP, capped at max HP).
- Shield pickup (adds shield charges that block the next hit).
- Bomb pickup (damages all enemies within radius around player).
- Magnet burst pickup (pulls all XP gems within radius toward player).
- Move speed boost (temporary 1.35× speed for 6 seconds, shown in HUD).
- Attack speed boost (temporary 1.35× attack speed for 6 seconds, shown in HUD).
- Active buff HUD display (shield charges, move speed timer, attack speed timer).
- Enemy death rolls a 6% chance to drop a random powerup pickup.
- BombBurst visual effect on bomb pickup.
- PowerupPickup scene is assigned in EnemySpawner.tscn (was missing — was the root bug).
- BombBurst scene is assigned in PowerupManager.tscn (was missing).
- Elite and miniboss guaranteed powerup drops now actually spawn (fixed via scene assignment).
- PowerupPickup collision_mask explicitly set to player layer 1.
- Powerup ids have distinct placeholder colors (heal=green, shield=blue, bomb=red, magnet=purple, speed=cyan, haste=yellow).
- Powerup spawn diagnostics: POWERUP_WIRING, POWERUP_ROLL, POWERUP_SPAWNED logs active while being verified.
- Guaranteed drop fallback to "heal" if roll unexpectedly returns empty.
- EnemySpawner.debug_spawn_powerup(id) helper for quick console verification.
- EventDirector with a timed event schedule (Runner Rush, Tank Wave, Elite, Miniboss).
- Timed events apply spawn modifier boosts through SpawnDirector.
- Elite enemy spawning with health, damage, XP, and color overrides.
- Miniboss enemy spawning with large stat multipliers and a dedicated health bar.
- MinibossHealthBar UI tracks a miniboss enemy and hides when it dies.
- EventAnnouncement UI shows timed fade-in/out labels for event names.
- Guaranteed powerup drop for elite and miniboss enemies.
- MinibossAttackController: dedicated miniboss combat brain attached dynamically on spawn.
- Miniboss Nova attack: circular telegraph warning zone, then area damage via Player.take_damage().
- Miniboss projectile barrage: radial spread of EnemyProjectiles, more in phase 2.
- Miniboss charge slam: line telegraph toward player, then locked-direction speed burst with boosted contact damage.
- AttackTelegraph: short-lived visual warning zone (circle or line) using built-in Line2D nodes only; never applies damage.
- 2-phase miniboss: phase 2 starts at 50% HP, reduces cooldowns, increases barrage count and nova radius, and shows "Miniboss Enraged!" announcement.
- Miniboss defeated announcement: "Miniboss Defeated!" shown via EventAnnouncement on miniboss death.

Not implemented yet:

- Mouse/manual ability aiming.
- Ability unlock system (all 3 are available by default).
- Ability icons.
- Complex targeting indicators.
- Status effects from abilities.
- Ability loadouts or per-run selection.
- Persistent ability progression.
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
- Persistent debug mode.
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
- Bosses.
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

Run the weapon upgrade sanity check from the repository root:

```sh
godot --headless --script res://scripts/tests/WeaponUpgradeSanityCheck.gd
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
