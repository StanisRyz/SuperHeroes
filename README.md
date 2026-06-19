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

The project is currently in the balance, cleanup, and production-readiness stage. Core systems (combat, XP, upgrades, powerups, miniboss, mobile controls, events, victory/defeat flow, and build-defining synergies) are implemented. This pass centralizes tunable balance defaults, quiets verbose debug logs by default, adds a startup wiring health check, and adds lightweight performance safeguards.

### Gameplay Validation / Debug Pass

A debug toolset has been added to help verify all gameplay systems quickly without waiting for natural game time:

- **DebugStatsOverlay** — top-left panel that shows live player stats, weapon values, ability cooldowns, build archetype, buff state, and powerup wiring. Visible only while Debug Mode is ON.
- **F3–F8 debug actions** — in-game keyboard shortcuts active only while Debug Mode is ON (F12/F10).
- **docs/validation/gameplay_validation.md** — manual test checklist for all systems.
- Verbose diagnostic logs are configurable in the Inspector through `GameplayTuning`, `Arena.debug_input_logging`, `DebugManager.debug_input_logging`, `EnemySpawner.powerup_debug_logging`, and `EnemySpawner.spawn_debug_logging`; they are off by default for normal play.

#### Debug Keys

| Key | Action | Notes |
|-----|--------|-------|
| F12 / F10 | Toggle Debug Mode | F10 is a browser/editor fallback |
| F1 / F2 | +1 Level (debug) | Only while Debug Mode ON |
| F3 | Spawn powerup near player | Cycles: heal → shield → bomb → magnet → speed → haste |
| F4 | Spawn elite enemy | Uses existing spawn_elite_enemy() |
| F5 | Spawn miniboss | HP bar wires automatically |
| F6 | Add 50 XP to player | Goes through normal XP/level-up flow |
| F7 | Print stats to console + refresh overlay | Only when requested |
| F8 | Kill enemies within 500px | Uses take_damage() so drops/effects still work |

All F3–F8 keys do nothing when Debug Mode is OFF, when the tree is paused, or when the player is dead.

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
- Debug diagnostic logs remain available through Inspector flags but are off by default for normal play.
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

- Upgrade Pool v3 — Build Archetypes:
  - Every upgrade definition carries an optional `archetype` (projectile / nova / laser / slam / dash / tank / speed / utility) and `tags` array.
  - UpgradeManager tracks `archetype_points` (how many upgrades from each archetype the player has taken) and `selected_upgrade_history` per run.
  - Build-aware weighted option selection: upgrades from the player's dominant archetype receive a small weight bonus (up to +60 %). At least one offered option usually comes from a different archetype when alternatives exist.
  - Synergy upgrades are epic-rarity upgrades that appear only when `prerequisites` are met (minimum archetype points and/or upgrade levels). They apply multiple effects via an `effects` array.
  - Projectile synergy upgrades: Split Barrage (multishot + spread), Shrapnel Burst (explosion radius + power), Heavy Piercer (pierce + size).
  - Ability synergy upgrades: Nova Aftershock (radius + damage), Laser Overcharge (damage + range), Slam Quake (radius + damage).
  - Defensive synergy upgrades: Shielded Dash (invulnerability + cooldown), Heroic Endurance (max health + heal), Power Collector (movement speed).
  - Build summary label in GameHUD: shows "Build: Projectile" (or current dominant) / "Build: Mixed" when no archetype leads.
  - UpgradeManager emits `build_changed(dominant_archetype, points)` whenever an upgrade is applied.
  - `debug_print_upgrade_pool()` and `debug_get_available_upgrade_ids()` helpers available for console verification.

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
- Powerup spawn diagnostics (`POWERUP_WIRING`, `POWERUP_ROLL`, `POWERUP_SPAWNED`) are available when `EnemySpawner.powerup_debug_logging` is enabled.
- Guaranteed drop fallback to "heal" if roll unexpectedly returns empty.
- EnemySpawner.debug_spawn_powerup(id) helper for quick console verification.
- EventDirector with a timed event schedule (Runner Rush, Tank Wave, Elite, Miniboss).
- Timed events apply spawn modifier boosts through SpawnDirector.
- Enemy Content v2: Shooter stand-ground behavior, closer ring-based spawning, Exploder, Swarm, Shielded, and Support enemies.
- Exploder enemies chase, wind up near the player, and deal explosion damage through `Player.take_damage()`.
- Swarm enemies approach and orbit around the player using simple deterministic movement.
- Shielded enemies absorb incoming damage with shield value before HP damage.
- Support enemies periodically apply temporary speed/contact damage buffs to nearby non-support enemies.
- Enemy waves added: Exploder Wave, Swarm Incoming, Shielded Front, and Support Units.
- `EnemySpawner.debug_spawn_enemy_variant("exploder"|"swarm"|"shielded"|"support")` is available for console validation.
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

- Gameplay balance & debug validation pass:
  - DebugStatsOverlay (scenes/ui/DebugStatsOverlay.tscn / .gd): live stats panel for player, weapon, abilities, build, buffs, and spawner wiring. Shown only in Debug Mode.
  - Debug input actions F3–F8 added to project.godot and routed through Arena/DebugManager.
  - DebugManager: 6 new validation signals and request methods (spawn powerup, spawn elite, spawn miniboss, add XP, print stats, kill nearby).
  - Player.debug_add_experience(amount): adds XP through normal level-up flow.
  - EnemySpawner.debug_get_powerup_wiring_state(): returns pickup_scene/manager/container/drop_chance snapshot.
  - UpgradeManager.debug_get_build_state(): returns dominant_archetype, archetype_points, history size, available count, unlocked synergy IDs.
  - docs/validation/gameplay_validation.md: manual test checklist for all systems.

### Ability & Build Synergy v4

- **Build-defining upgrades** - synergy upgrades can now be marked as build-defining; LevelUpScreen displays `BUILD DEFINING` on those options.
- **Nova Aftershock Zone** - Nova Pulse can create a delayed second area hit at the cast position with its own feedback ring.
- **Laser Double Pulse** - Laser Beam can fire a delayed weaker second beam from the original cast origin and direction.
- **Slam Second Wave** - Hero Slam can create a delayed second wave at the original slam position.
- **Comet Dash** - dash can damage nearby enemies when the dash ends.
- **Bouncing Bolts** - player projectiles can bounce from a hit enemy to another nearby valid enemy.
- UpgradeManager effect arrays now support `set` operations for bool/int/float properties and fail safely when a target/property/operation is invalid.
- DebugStatsOverlay shows dash trail state, projectile bounce count, ability synergy flags, and build-defining option counts.

### UI Readability Polish

- **UIFormat** (`scenes/ui/UIFormat.gd`) — shared static helpers: `format_time`, `format_cooldown`, `format_percent`, `format_list`, `format_title_id`. Used across HUD and result screens to keep display formatting consistent.
- **UIStateColors** (`scenes/ui/UIStateColors.gd`) — shared static color helpers: `ready_color`, `cooldown_color`, `warning_color`, `danger_color`, `muted_color`, `positive_color`, `boss_color`, `final_phase_color`. Used to consistently apply state-driven colors.
- **Improved HUD grouping** — GameHUD panels reorganized into clear sections: Player (HP bar + XP bar), Run (time / kills / threat / objective / special kills / final phase), Combat (dash + 3 abilities), Buffs (shield / speed / haste), Build (hero / archetype / evolutions). AbilityPanel layout bug (overlapping RunPanel) fixed.
- **Ability cooldown states** — HUD shows `J  Nova: Ready` (green) or `J  Nova: 3.4s` (gray) for each ability and dash. Ready state uses ready_color; cooldown uses cooldown_color.
- **Low HP readability** — HP label turns amber at ≤30% HP and red with `LOW` prefix at ≤15% HP.
- **Final phase / boss HUD** — `★ FINAL PHASE` shown in magenta when final phase starts; `Final Boss: Boss Name` in orange when the boss spawns; `Boss defeated` in green when defeated.
- **Improved level-up cards** — LevelUpScreen shows title on top, then `[RARITY]  [ARCHETYPE]`, synergy/build-defining markers (`★ SYNERGY`, `◆ BUILD DEFINING`), level line, and description. Cards tinted by rarity (blue=rare, purple=epic, gold=legendary).
- **Improved evolution cards** — EvolutionRewardScreen shows `◆ EVOLUTION  [ARCHETYPE]` header, title, description. Cards tinted golden. Friendly message when no evolution is available.
- **Improved result screens** — VictoryScreen title is green; GameOverScreen title is red. Both show consistent stat labels (`Time:`, `Enemies:`, `Elites:`, `Minibosses:`, `Level:`, `Hero:`, `Stage:`, `Final Boss:`, `Build:`, `Upgrades:`, `Evolutions:`). GameOverScreen now also shows upgrade count.
- **Improved PostRunRewardsScreen** — Reward rows colored green for non-zero values, gray for zero. Total and currency labels colored.
- **Improved Training shop** — Buy button green when affordable, gray when not affordable or maxed.
- **Improved CharacterSelect** — Selected hero button turns green; locked hero buttons are gray.
- **Improved StageSelect** — Selected stage button turns green.
- **Help overlay section titles** — Section titles are uppercase amber with horizontal separators between sections.

Not implemented yet (UI):
- Custom art UI theme.
- Icon set for abilities, buffs, upgrades.
- Localization / text scaling.
- Remappable controls UI.
- Gamepad navigation polish.

### Controls Help Overlay

- **ControlsHelpOverlay** is a reusable pause-safe CanvasLayer shared by Main and Arena.
- MainMenu and PauseMenu now include a **Help / Controls** button that opens the controls reference without owning gameplay state.
- **H / F11** toggles Help / Controls through the `help_toggle` input action. F11 is available as a browser/editor fallback.
- During active gameplay, opening Help pauses the run and resets mobile controls; closing it resumes only when Help created that pause.
- If Help is opened from PauseMenu, closing it returns to the paused menu state.
- Help does not open over Settings, LevelUpScreen, EvolutionRewardScreen, VictoryScreen, or GameOverScreen.
- The content is centralized in `ControlsHelpContent.gd` and covers basic controls, active abilities, run systems, meta progression, debug mode, and mobile controls.

### Balance / Cleanup / Production Readiness

- **GameplayTuning** (`scenes/game/GameplayTuning.tscn`) centralizes exported balance defaults for debug logging, run timing, spawn distances/caps, powerup drop chance, core ability values, and player defaults.
- **Configurable debug logs** keep debug tools functional while disabling noisy `DEBUG_*` and `POWERUP_*` logs by default.
- **ProjectHealthCheck** runs once at Arena startup and prints concise warnings only when critical wiring is missing.
- **Lightweight safeguards** clamp max alive enemies, projectile count, projectile bounce count, explosion radius, and miniboss barrage count.
- Current balance review areas: enemy spawn progression, ability cooldown/damage roles, projectile synergies, powerup drop pressure, miniboss readability, restart/victory/game-over flow, and browser-friendly runtime load.

### Character Select & Hero Roster v1

- **CharacterSelect** sits between MainMenu and Arena; Main owns the menu/selection/run transition.
- **HeroDataProvider** owns three hardcoded starter heroes for now: Guardian, Blaster, and Vanguard.
- **Guardian** is balanced and beginner-friendly: 120 HP, 245 speed, no damage penalty.
- **Blaster** is projectile-focused: 90 HP, 265 speed, +3 attack damage, +1 starting projectile, slightly slower attack interval.
- **Vanguard** is ability/burst-focused: 100 HP, 275 speed, 0.9x ability cooldowns, +4 Nova damage, +6 Slam damage.
- **HeroApplier** applies run-only starting stats to Player, AutoAttack, and AbilityManager before gameplay systems start.
- Selected hero appears in GameHUD and in Victory/GameOver run summaries.
- Restart from Victory/GameOver keeps the same selected hero; returning to MainMenu allows choosing a different hero.

### Post-Run Rewards & Meta Progression v1

- **Soft currency** — earned after every run (victory or defeat) and persisted in `user://superheroes_meta_progress.json`.
- **Reward formula**: base participation (10) + time bonus (floor(time/30)×2) + kill bonus (floor(kills/10)) + elite kills (×5) + miniboss kills (×15) + victory bonus (+40) + evolution bonus (×10) + reward-training bonus.
- **PostRunRewardsScreen** — appears between the Victory/GameOver result screen and the next action (restart or main menu). Shows the full reward breakdown and new currency total. Display-only; Continue button returns to the pending action.
- **MetaProgressionManager** — persistent Node in Main; owns save/load, currency, meta upgrades, hero unlock state, and lifetime stats. Saves to `user://superheroes_meta_progress.json` (JSON, versioned). Handles corrupt/missing save safely by starting fresh.
- **MetaUpgradeShop (Training)** — accessible from MainMenu via the new "Training" button. Shows all meta upgrade definitions with current level, next cost, and a Buy button. Display-only except emitting buy intent to Main.
- **Meta upgrades** (persist between runs):
  - **Training: Vitality** — +5 max HP per level (max 10).
  - **Training: Power** — +1 starting attack damage per level (max 10).
  - **Training: Awareness** — +8 XP pickup/magnet radius per level (max 8).
  - **Training: Mobility** — +3 starting movement speed per level (max 8).
  - **Training: Rewards** — +2 currency after each run per level (max 5).
- **MetaApplier** — static helper called at Arena start (after HeroApplier) to apply purchased meta bonuses to Player, AutoAttack, and pickup radius.
- **Hero unlock foundation** — heroes carry `unlocked_by_default` and `unlock_cost` fields. CharacterSelect accepts optional MetaProgressionManager and shows locked state. All three heroes are currently unlocked by default to avoid blocking testing.
- **Persistent local save** — `user://superheroes_meta_progress.json`. Saved after every purchase and every run result. Safe to delete to reset manually. No cloud save, no online services.

Not implemented yet (meta):
- Advanced hero unlock purchase UI.
- Online leaderboard.
- Cloud save / Yandex save.
- Ads, paid purchases, or monetization.
- Achievements.
- Prestige or season resets.

### Bosses, Stages & Content Expansion v1

- **StageSelect** screen between CharacterSelect and Arena; shows stage list (left) and detail panel (right: color swatch, name, subtitle, difficulty, description, final boss name). Back returns to CharacterSelect; Start Run advances to Arena.
- **StageDataProvider** owns 3 hardcoded stage presets:
  - **City Rooftop** (Normal difficulty, `balanced` event profile, final boss: Titan Guardian, 10 min run)
  - **Neon Lab** (Hard difficulty, `ranged_support` event profile, final boss: Prism Overlord, 8 min run)
  - **Wasteland Gate** (Hard difficulty, `swarm_exploder` event profile, final boss: Molten Colossus, 9 min run)
- **StageApplier** (static helper) applies the selected stage to Arena at startup: background colors on Ground/CenterGuide/HorizontalGuide/VerticalGuide, run settings to RunManager, event profile to EventDirector + SpawnDirector.
- **Stage event profiles** in EventDirector: `balanced` uses the default schedule; `ranged_support` adds earlier shooter flanker and support surge events; `swarm_exploder` adds earlier exploder and swarm rush events.
- **Stage spawn profiles** in SpawnDirector: `ranged_support` gives shooter/support a +25% weight bonus; `swarm_exploder` gives exploder/swarm a +30% weight bonus.
- **Final boss spawn flow**: RunManager emits `target_time_reached` when the run time is reached (instead of triggering victory). Arena shows "Final Boss Incoming!" announcement and calls `EnemySpawner.spawn_final_boss(boss_id)`. Victory only occurs after the final boss is defeated.
- **FinalBossController** (attached dynamically, like MinibossAttackController): 3 attacks — Nova (area damage circle), Barrage (radial projectile spread), Charge (telegraphed speed burst with boosted contact damage). Phase 2 at 50% HP reduces cooldowns and scales attack count/radius. Boss variant stats differ per boss_id.
- **BossHealthBar** — CanvasLayer (layer 9) positioned below MinibossHealthBar. Shows "FINAL BOSS", boss display name, HP bar, and HP text. Wired by Arena to `EnemySpawner.final_boss_spawned`.
- **HUD stage name** — `GameHUD.set_stage_name()` dynamically adds a StageLabel to RunPanel showing "Stage: City Rooftop".
- **Victory/GameOver stage display** — both screens show "Stage: <name>" below the hero name row (added dynamically on `show_stats()`).
- **Final boss meta reward** — `+35 currency` if `final_boss_defeated == true`; shown as "Final boss" row in PostRunRewardsScreen.
- **Debug**: `Arena.debug_spawn_final_boss(boss_id: String = "")` can be called from the Godot remote console. No new key binding.
- Restart from Victory/GameOver keeps the same hero and stage. Quit to MainMenu clears both selections.

### Weapon / Ability Evolution System

- **EvolutionManager** owns runtime-only evolution definitions and applied evolution state for the current run.
- **EvolutionRewardScreen** is a display-only paused reward screen; Arena opens it and applies selected evolutions.
- Evolutions added: Projectile Storm, Supernova Core, Prism Laser, Earthbreaker Slam, and Comet Engine.
- Miniboss defeat checks available evolutions and opens the reward screen when prerequisites are met.
- Elite evolution rewards are supported behind `EvolutionManager.elite_reward_chance`, defaulting to `0.0`.
- GameHUD shows current evolution state, and Victory/GameOver summaries list applied evolutions.
- Debug Mode F9 can open the evolution reward screen when evolutions are available.

### Run Progression & Victory

- **Run target duration** — 10 minutes (600 seconds) by default, configurable per RunManager inspector.
- **Final Phase** — begins at 9 minutes (540 seconds); "Final Phase!" announcement; spawn pressure and max alive enemies increase.
- **VictoryScreen** — shown when target duration is reached; displays time survived, kills, elite kills, miniboss kills, player level, dominant build, and upgrades taken.
- **Run Summary** — both VictoryScreen and GameOverScreen receive full enriched stats (time, kills, elites, miniboss kills, level, dominant build, upgrade count).
- **Elite and miniboss kill tracking** — RunManager counts elite and miniboss kills separately; HUD shows "Elite N | Boss N".
- **Victory/defeat flow** — reaching target time triggers VictoryScreen; player death before that triggers GameOverScreen. Both have Restart and Main Menu.
- **Main Menu button** on GameOverScreen — added alongside Restart.
- **Debug-shortened runs** — set `use_debug_run_duration = true` and `debug_target_run_time = 60` in RunManager inspector for quick local testing (not enabled by default, not persisted).

Not implemented yet:

- Persistent records or run history.
- Hero portraits.
- Hero-specific unique abilities.
- Persistent selected hero.
- Persistent selected stage.
- Persistent evolution unlocks.
- Evolution art/icons.
- Evolution sound effects.
- Evolution chest animation.
- Stage-specific evolutions.
- Localized help text.
- Icon-based controls guide.
- Runtime input remapping UI.
- Stage unlocks (all 3 stages are unlocked by default).
- Arena hazards / floor zones / obstacles.
- Leaderboard.
- Persistent high scores.
- Yandex SDK integration.
- Ads, payments, or monetization.
- Reroll, skip, or banish upgrade actions.
- Upgrade icons.
- Upgrade codex / full history UI.
- Data-driven Resource upgrade files.
- Mouse/manual ability aiming.
- Ability icons.
- Complex targeting indicators.
- Status effects from abilities.
- Ability loadouts or per-run selection.
- Boss-specific art assets.
- Boss sound effects.
- More than 2 final boss phases.
- Complex bullet patterns or homing projectiles.
- Boss arena or cutscene.
- Buff icons.
- Powerup rarity tiers.
- Powerup upgrade scaling.
- Pickup object pooling.
- Advanced particle effects for powerups.
- Chain lightning.
- Critical hits.
- Elemental/status effects.
- Projectile pooling.
- Dash trail particles.
- Stamina.
- Advanced dodge perks.
- Controller remapping.
- Enemy art assets.
- Enemy sound effects.
- Advanced support healing.
- Flocking AI.
- Enemy pathfinding.
- Enemy spawn warning indicators.
- Enemy projectile patterns.
- Real audio assets.
- Music playback.
- Yandex/cloud save integration.
- Persistent debug mode.
- Sound effects.
- Advanced particles.
- Crit text.
- Damage type colors.
- Pickup magnet upgrades.
- Input rebinding.
- Ability upgrade tree.
- Resource-backed upgrade data files.
- XP vacuum upgrades.
- Additional stages beyond 3.
- TileMap-based arena layouts.

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
