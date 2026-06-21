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
- Basic run upgrades for attack damage, attack speed, attack range, move speed, max HP, projectile speed, and active abilities.
- Shared passive skill upgrades for automatic in-run effects.
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
- Slot 1 / J: hero-specific area ability behavior.
- Slot 2 / K: hero-specific forward ability behavior.
- Slot 3 / L: hero-specific impact/control ability behavior.
- 3-slot ability cooldown display in the HUD.
- Simple in-world slot 1 visual feedback.
- Slot 2 visual feedback (built-in Line2D beam with fade).
- Slot 3 visual feedback (built-in expanding ring with fade).
- Slot 2 and slot 3 runtime upgrades (damage, cooldown, width/radius).
- Player exposes get_aim_direction() used by slot 2 direction targeting.
- Virtual joystick for mobile movement.
- Mobile slot 1 button (`ability_1`).
- Mobile slot 2 button (`ability_2`).
- Mobile slot 3 button (`ability_3`).
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
- Desktop/mobile Pause button.
- Desktop/mobile Build button under Pause.
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
  - Runs now use a 12-line upgrade structure: 4 Attack lines, 4 Passive lines, and 4 Active lines.
  - A new upgrade id consumes one slot in its category; repeated levels of an already selected upgrade id do not consume extra slots.
  - When a category is full, new lines from that category stop appearing, but already selected non-maxed lines remain eligible.
  - Attack lines cover primary weapon / autoattack upgrades, Passive lines cover shared passives plus defense / mobility / utility run-stat lines, and Active lines cover slot 1/2/3 ability upgrades.
  - Build-aware weighted option selection: upgrades from the player's dominant archetype receive a small weight bonus (up to +60 %). At least one offered option usually comes from a different archetype when alternatives exist.
  - Synergy upgrades are epic-rarity upgrades that appear only when `prerequisites` are met (minimum archetype points and/or upgrade levels). They apply multiple effects via an `effects` array.
  - Projectile synergy upgrades: Split Barrage (multishot + spread), Shrapnel Burst (explosion radius + power), Heavy Piercer (pierce + size).
  - Ability synergy upgrades: Nova Aftershock (radius + damage), Laser Overcharge (damage + range), Slam Quake (radius + damage).
  - Defensive synergy upgrades: Shielded Dash (invulnerability + cooldown), Heroic Endurance (max health + heal), Power Collector (movement speed).
  - Build summary label in GameHUD: shows "Build: Projectile" (or current dominant) / "Build: Mixed" when no archetype leads.
  - UpgradeManager emits `build_changed(dominant_archetype, points)` whenever an upgrade is applied.
  - `debug_print_upgrade_pool()`, `debug_get_available_upgrade_ids()`, and `debug_get_slot_state()` helpers available for console verification.

- Upgrade Grid Schema foundation:
  - Upgrade definitions now support optional grid metadata: `upgrade_line_id`, `slot_category`, `hero_id` / `hero_ids`, `hero_exclude`, `source_type`, `source_skill_id`, `grid_index`, `triple_id`, `evolution_role`, `evolution_target_active_skill`, and `evolution_candidate_id`.
  - Missing `upgrade_line_id` falls back to `id`; missing `slot_category` is inferred from existing category/type/tags/effect targets so old definitions keep working.
  - Future target grid: 9 Attack lines per hero, 9 Active lines per hero, and 9 shared Passive lines.
  - Future Evolution triples will link one attack line, one passive line, one active line, and one evolved active skill.
  - Solar Guardian now has a complete Guardian-only future grid slice: 9 Solar Ray Attack lines and 9 Active lines across Solar Beam, Frost Breath, and Death Dash.
  - This patch does not add new evolutions, Overdrive UI, new evolved active skills, or Evolution triples.
  - `UpgradeManager.validate_upgrade_grid(false)` reports incomplete target counts as warnings, while strict mode can promote target-count gaps for future content gates.
  - `debug_get_upgrade_grid_state()` exposes warning/error counts and current hero line counts; DebugStatsOverlay displays a compact grid audit summary.

- Solar Guardian Upgrade Grid:
  - Attack lines for Solar Ray: `solar_ray_damage`, `solar_ray_range`, `solar_ray_width`, `solar_ray_pierce_burn`, `solar_ray_tick_rate`, `solar_ray_empowered_bonus`, `solar_ray_lingering_heat`, `solar_ray_focus`, and `solar_ray_execution`.
  - Active lines for Solar Beam: `solar_beam_damage_up`, `solar_beam_range_up`, and `solar_beam_overheat`.
  - Active lines for Frost Breath: `frost_breath_power`, `frost_breath_cone_up`, and `frost_breath_freeze`.
  - Active lines for Death Dash: `death_dash_power`, `death_dash_distance`, and `death_dash_cooldown_down`.
  - Guardian-specific attack and active lines include explicit grid metadata for future Evolution triples, but this does not implement Evolution triples or Overdrive.
  - Guardian no longer receives generic projectile-only or duplicate generic autoattack lines; shared passive skills remain available and the 4/4/4 slot limits still apply.

- Fury Vanguard Upgrade Grid:
  - Attack lines for Fury Strikes (splash_melee, 9 total): `splash_melee_damage`, `splash_melee_radius`, `splash_melee_speed`, `splash_melee_impact`, `splash_melee_frenzy`, `splash_melee_shockwave`, `splash_melee_lifesteal`, `splash_melee_combo`, and `splash_melee_execute`.
  - Active lines for Rage Wave: `rage_wave_power`, `rage_wave_radius`, and `rage_wave_deep_slow` (includes merged cooldown and rage-scaling radius).
  - Active lines for Mighty Clap: `mighty_clap_power`, `mighty_clap_range` (also widens cone), and `mighty_clap_shockwave` (merged cooldown reduction).
  - Active lines for Rage Leap: `rage_leap_power`, `rage_leap_radius`, and `rage_leap_cooldown` (also increases leap distance).
  - New PlayerAutoAttack effect hooks: `splash_melee_shockwave_enabled` (delayed 0.5× AoE at 1.5× radius), `splash_melee_lifesteal` (HP restored per enemy hit), `splash_melee_combo_enabled` / `splash_melee_combo_bonus` (stacking per-swing damage), `splash_melee_execute_threshold` (45% bonus to low-HP enemies).
  - Removed 3 redundant active lines (`rage_wave_cooldown`, `rage_wave_chain`, `mighty_clap_cooldown`); effects merged into the surviving 9 active lines.
  - Generic attack upgrades `attack_damage_up`, `attack_speed_up`, and `attack_range_up` excluded from Vanguard — hero-specific equivalents cover the same role.
  - All 18 Vanguard lines carry full grid schema: `upgrade_line_id`, `source_type`, `source_skill_id`, `grid_index` 1–9, `evolution_role`, and `evolution_target_active_skill` on active lines.
  - This patch does not implement Evolution triples, Overdrive UI, or EvolutionManager.

- Night Tactician Upgrade Grid:
  - Attack lines for homing rockets (9 total): `rocket_damage`, `rocket_count`, `rocket_explosion_radius`, `rocket_reload`, `marked_target_payload`, `rocket_seek_range`, `rocket_split`, `rocket_cluster_payload`, and `rocket_priority_targeting`.
  - Active lines for Smoke Screen: `smoke_screen_radius`, `smoke_screen_duration`, and `smoke_screen_slow`.
  - Active lines for Explosive Trap: `trap_damage`, `trap_radius`, and `trap_chain_detonation`.
  - Active lines for Grappling Hook: `hook_damage`, `hook_range`, and `hook_cooldown_down`.
  - Deprecated blaster lines (hero_exclude: ["blaster"]): `smoke_screen_damage_reduction`, `trap_cooldown_down`, `trap_mark_bonus`, `hook_mark_bonus`.
  - New effect hooks: `rocket_priority_targeting_enabled` on PlayerAutoAttack (sorts marked enemies first); `explosive_trap_chain_enabled` on AbilityManager (chain-detonates nearby traps on blast).
  - All blaster attack and active lines carry full grid metadata (`upgrade_line_id`, `source_type`, `source_skill_id`, unique `grid_index` 1-9, `evolution_role`, `evolution_target_active_skill` on active lines) for future Evolution triples.
  - This patch does not implement Evolution triples, Overdrive, EvolutionManager, or any other hero's grid.

- Shared Passive Skills 9-Line Pack:
  - Passive skills are shared by all heroes, selected through the normal level-up upgrade pool, and reset every run.
  - `PassiveAbilityManager` is instantiated by Arena at run startup and is never saved to meta/progression data.
  - The shared passive grid now contains exactly 9 passive lines: Orbit Shields, Storm Relay, Guardian Drone, Magnet Core, Chain Lightning, Recovery Field, Battle Focus, Static Field, and Time Dilator.
  - The original four passive ids and behavior are preserved: `orbit_shields`, `storm_relay`, `guardian_drone`, and `magnet_core`.
  - New shared passive ids: `chain_lightning` (periodic bouncing lightning arcs), `recovery_field` (small periodic heal pulse), `battle_focus` (periodic focus strike plus short attack-speed buff), `static_field` (nearby electric damage pulse), and `time_dilator` (nearby enemy slow pulse through temporary enemy modifiers).
  - Passive effects have visible runtime feedback: shield indicators track charges, shield blocks show `SHIELD BLOCK`, Storm/Drone/Chain/Focus hits draw Line2D arcs, field effects draw pulse rings, and damage/heal/status text appears in-world.
  - Passive upgrade definitions use `type/category/slot_category: "passive"`, `source_type: "passive"`, `source_skill_id`, `upgrade_line_id`, `grid_index` 1-9, `evolution_role: "passive"`, and `tags: ["passive", ...]`; LevelUpScreen marks them with `PASSIVE`.
  - The 4/4/4 upgrade slot limits now apply to new upgrade lines, while repeated levels stay within the already owned line. Solar Guardian attack/active grid normalization is implemented separately; Night/Fury 9-line attack/active grids, Overdrive, and Build Evolution are not included in this pack.
  - Build Slots Overview Window: an in-run `Build` button under Pause opens a compact read-only window showing Attack, Passive, and Active slot usage plus the filled/empty rows for all 12 build slots.
  - The Build Slots window reads runtime slot state from `UpgradeManager`; it does not change slot rules, upgrade weights, upgrade effects, saves, rewards, or meta progression.
  - DebugStatsOverlay shows selected passive ids/levels, timers, shield count/max, pickup radius bonus, and the last passive event while Debug Mode is enabled.
  - This patch does not add Night/Fury attack or active 9-line grids, Overdrive UI, or new Evolution/Overdrive behavior.

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
  - UpgradeManager.debug_get_build_state(): returns dominant_archetype, archetype_points, history size, available count, unlocked synergy IDs, and 4/4/4 slot state.
  - docs/validation/gameplay_validation.md: manual test checklist for all systems.

### Ability & Build Synergy v4

- **Build-defining upgrades** - synergy upgrades can now be marked as build-defining; LevelUpScreen displays `BUILD DEFINING` on those options.
- **Aftershock Zone** - slot 1 can create a delayed second area hit at the cast position with its own feedback ring.
- **Double Pulse** - slot 2 can fire a delayed weaker second line hit from the original cast origin and direction.
- **Second Wave** - slot 3 can create a delayed second wave at the original cast position.
- **Comet Dash** - dash can damage nearby enemies when the dash ends.
- **Bouncing Bolts** - player projectiles can bounce from a hit enemy to another nearby valid enemy.
- UpgradeManager effect arrays now support `set` operations for bool/int/float properties and fail safely when a target/property/operation is invalid.
- DebugStatsOverlay shows dash trail state, projectile bounce count, ability synergy flags, and build-defining option counts.

### Primary Weapon / Autoattack Rework

Each hero now has a distinct primary weapon identity routed by `PlayerAutoAttack`. The upgrade system is fully compatible: all existing upgrade hooks (`attack_damage`, `attack_interval`, `attack_range`, `projectile_count`, `projectile_pierce`, `projectile_size_multiplier`, `projectile_explosion_radius`, `projectile_bounce`, `projectile_speed`) apply on top of per-hero weapon defaults.

#### Hero Primary Weapons

| Hero | Weapon ID | Style |
|------|-----------|-------|
| Solar Guardian | `solar_ray` | Direct beam autoattack. Damages all enemies in a narrow corridor toward the nearest target. No projectile spawned. Empowered x2 damage when Solar Energy is full. |
| Night Tactician | `homing_rockets` | Homing rockets that auto-track enemies. Round-robin target distribution across multiple enemies. No pierce, no bounce. Explosion on hit (aoe). Marked enemies take bonus damage. |
| Fury Vanguard | `splash_melee` | Close-range splash melee. Hits all enemies within splash radius. No projectile spawned. Damage scales with current Rage level. |

#### Architecture

- `HeroDataProvider` stores a `primary_weapon` dict per hero (`weapon_id`, `display_name`, and weapon-specific property defaults).
- `HeroApplier.apply_hero()` calls `PlayerAutoAttack.set_primary_weapon(hero_id, weapon_id, weapon_data)` and wires the AbilityManager reference for Tactical Mark access.
- `PlayerAutoAttack._physics_process` routes by `_primary_weapon_id`: `solar_ray` → `_tick_solar_ray`, `homing_rockets` → `_tick_homing_rockets`, `shockwave_strike` → `_tick_shockwave_strike`, default → `_tick_solar_bolt` (fallback projectile path).
- The generic projectile path remains the fallback for any unrecognized weapon id.
- `GameHUD` shows `Weapon: <display name>` in the BuildPanel.
- `DebugStatsOverlay` shows `Primary: <weapon_id>`, plus damage, interval, range, count, pierce, and bounce.

Build Evolution is not included in this patch. No arena hazards were added.

### Hero Signature Kits Real Mechanics

- **AbilityManager hero-kit routing** - active ability inputs and public cast methods remain `ability_1` / `ability_2` / `ability_3`, but casts now route by the selected hero's `kit_id`.
- **Regression hotfix** - ready ability casts no longer silently fail when they hit zero enemies. A valid press now plays available feedback/status, enters cooldown, emits `ability_cast`, and updates cooldown UI immediately.
- **Solar Guardian kit** - passive Solar Energy charges at +2/sec (not from hits). At 100 energy, a 15-second empowered state activates doubling all damage, then energy resets to 0 and resumes. Solar Beam (slot 1) fires a long direct red beam in aim direction. Frost Breath (slot 2) delivers a cone attack that damages and slows all enemies in range. Death Dash (slot 3) moves the player forward while damaging enemies along the path with brief invulnerability. Guardian autoattack (`solar_ray`) is a direct beam — no projectile spawned.
- **Night Tactician kit** - passive Tactical Mark is multi-enemy, duration-based (Dictionary of enemy→seconds_remaining), applied by all active abilities. Smoke Screen creates a persistent zone that slows enemies, applies marks every 0.5s, and reduces player damage while inside. Explosive Trap is placed at the player position and triggers on enemy contact with a large explosion radius that marks all hit enemies. Grappling Hook dashes the player toward the nearest enemy in range, deals high damage, and applies a mark on impact. Homing Rockets never pierce or bounce; each rocket tracks a different target (round-robin) and applies the tactical mark multiplier on marked targets.
- **Fury Vanguard kit** (reworked) - passive Rage builds from damage taken and from dealing damage with autoattacks or abilities, then decays over time. Higher Rage increases all damage (up to 1.45× at max). **Rage Wave** (slot 1) — circle AoE that damages and slows all enemies in radius; radius scales slightly with Rage. **Mighty Clap** (slot 2) — cone AoE that damages and knocks back enemies in front. **Rage Leap** (slot 3) — dashes toward aim direction with brief invulnerability, then deals AoE damage + slow at the landing point. Vanguard autoattack is `splash_melee` — no projectile, hits all enemies within splash radius, damage scales with Rage. Public helpers `add_rage()`, `get_rage_damage_multiplier()`, and `get_rage_state()` allow PlayerAutoAttack to report hits and read Rage state.
- Vanguard uses dedicated `rage_wave_*`, `mighty_clap_*`, `rage_leap_*`, and `splash_melee_*` properties. Old `nova_*`, `laser_*`, and `slam_*` ability upgrade lines are excluded from Vanguard. Projectile-count, pierce, bounce, spread, and projectile size upgrades are also excluded since Vanguard has no projectiles.
- DebugStatsOverlay shows current kit and passive resource/mark state when Debug Mode is enabled.
- Level-up upgrade selection now hides the LevelUpScreen before Arena resumes, fixing a paused-with-no-modal regression after choosing an upgrade.
- This patch does not add Enemy Roles, Boss Rework, Build Evolution, Stage Objectives, arena hazards, enemy changes, stage changes, reward changes, meta economy changes, or save-format changes. Primary Weapon Rework was added in the subsequent patch.

### UI Readability Polish

- **UIFormat** (`scenes/ui/UIFormat.gd`) — shared static helpers: `format_time`, `format_cooldown`, `format_percent`, `format_list`, `format_title_id`. Used across HUD and result screens to keep display formatting consistent.
- **UIStateColors** (`scenes/ui/UIStateColors.gd`) — shared static color helpers: `ready_color`, `cooldown_color`, `warning_color`, `danger_color`, `muted_color`, `positive_color`, `boss_color`, `final_phase_color`. Used to consistently apply state-driven colors.
- **Improved HUD grouping** — GameHUD panels reorganized into clear sections: Player (HP bar + XP bar), Run (time / kills / threat / objective / special kills / final phase), Combat (dash + 3 abilities), Buffs (shield / speed / haste), Build (hero / archetype / evolutions). AbilityPanel layout bug (overlapping RunPanel) fixed.
- **Ability cooldown states** — HUD shows the selected hero's ability names, such as `J  Burst: Ready` or `K  Grapnel: 3.4s`, for each ability and dash. Ready state uses ready_color; cooldown uses cooldown_color.
- **Hero-specific upgrade flavor** — LevelUpScreen upgrade titles/descriptions use selected-hero wording for Solar Guardian, Night Tactician, and Fury Vanguard while keeping upgrade ids, effects, weights, rarity, prerequisites, synergies, and balance unchanged.
- **Low HP readability** — HP label turns amber at ≤30% HP and red with `LOW` prefix at ≤15% HP.
- **Final phase / boss HUD** — `★ FINAL PHASE` shown in magenta when final phase starts; `Final Boss: Boss Name` in orange when the boss spawns; `Boss defeated` in green when defeated.
- **Improved level-up cards** — LevelUpScreen shows title on top, then `[RARITY]  [ARCHETYPE]`, synergy/build-defining markers (`★ SYNERGY`, `◆ BUILD DEFINING`), level line, and description. Cards tinted by rarity (blue=rare, purple=epic, gold=legendary).
- **Improved evolution cards** — EvolutionRewardScreen shows `◆ EVOLUTION  [ARCHETYPE]` header, title, description. Cards tinted golden. Friendly message when no evolution is available.
- **Improved result screens** — VictoryScreen title is green; GameOverScreen title is red. Both show consistent stat labels (`Time:`, `Enemies:`, `Elites:`, `Minibosses:`, `Level:`, `Hero:`, `Stage:`, `Final Boss:`, `Build:`, `Upgrades:`, `Evolutions:`). GameOverScreen now also shows upgrade count.
- **Improved PostRunRewardsScreen** — Reward rows colored green for non-zero values, gray for zero. Total and currency labels colored.
- **Improved Training shop** — Buy button green when affordable, gray when not affordable or maxed.
- **Improved CharacterSelect** — Selected hero button turns green; locked hero buttons are gray.
- **CharacterSelect hero detail cards** — hero cards now show display name, playstyle, and compact state markers; the selected hero detail card shows subtitle, description, ability names, strengths, and read-only per-hero Training summary.
- **CharacterSelect scrollable details** — hero detail cards stay inside a bounded right-side scroll panel so Back and Start Run remain visible.
- **Improved StageSelect** — stage cards now show display name, difficulty, threat identity, and remembered-stage state; selected stage details are bounded in a scrollable right panel so Back / Start Run remain visible.
- **Run Briefing Screen** — after confirming a stage, a compact display-only briefing shows selected hero, stage, ability names, per-hero Training summary, objective, and final boss preview before Arena starts.
- **Help overlay section titles** — Section titles are uppercase amber with horizontal separators between sections.
- **Pause / Restart / Exit Safety QoL** — active-run Restart and Main Menu actions now use a reusable confirmation dialog, Escape / Back behavior is centralized across pause/settings/help overlays, and duplicate transition guards prevent repeated restarts, exits, reward screens, or Arena creation from rapid clicks.
- **Main Menu Rework** — Settings now sits top-left, Help / Controls top-right, and Select Hero plus Training are grouped as a bottom horizontal interface. Existing menu, training, settings, help, hero/stage select, and run flows are preserved.
- **Main Menu Collection Entry** — A third bottom-bar button "Collection" sits alongside Select Hero and Training. Opens `HeroCollectionScreen`. Back or ESC returns to the main menu. The screen is pre-game only and does not affect gameplay, saves, rewards, or meta balance.
- **Hero Collection Screen Foundation** — `HeroCollectionScreen` shows a two-panel layout: left is a scrollable card list, right is a detail panel for the selected hero. The three current heroes (Solar Guardian, Night Tactician, Fury Vanguard) each appear as an owned hero card showing display name, playstyle, passive name, and owned status. Three locked placeholder cards are present for future gacha heroes. Selecting a card shows the hero's color, name, status, playstyle, passive, weapon, ability names, mastery stats (runs / victories / mastery level from MetaProgressionManager), and description. Emits `hero_selected(hero_id)` but does not connect to CharacterSelect. Gacha pulls, shards, equipment, and inventory are future work.

Not implemented yet (UI):
- Custom art UI theme.
- Icon set for abilities, buffs, upgrades.
- Localization / text scaling.
- Remappable controls UI.
- Gamepad navigation polish.
- Full controller navigation.
- Platform-specific back button support.
- Autosave mid-run.
- Pause menu animations.

### Pause / Restart / Exit Safety QoL

- **ConfirmDialog** is a reusable display-only CanvasLayer for destructive active-run actions. It emits action ids and never owns gameplay pause state.
- **Restart confirmation** appears from PauseMenu with "Restart Run?" before abandoning current run progress.
- **Main Menu exit confirmation** appears from PauseMenu with "Return to Main Menu?" before abandoning current run progress.
- **Unified Escape / Back behavior** closes ConfirmDialog, Help, Settings, or PauseMenu in priority order, and ignores pause toggles on LevelUp, EvolutionReward, Victory, and GameOver screens.
- **Safe reward screen transition** keeps Victory/GameOver Restart and Main Menu on the existing post-run reward path. PostRunRewardsScreen shows once per completed run and Continue can only fire once per pending action.
- **Duplicate transition protection** guards active-run restart/quit signals, CharacterSelect/StageSelect confirms, reward Continue, and rapid result-screen clicks.
- Gameplay balance values, progression formulas, enemy behavior, player stats, and reward formulas are unchanged.

### Controls Help Overlay

- **ControlsHelpOverlay** is a reusable pause-safe CanvasLayer shared by Main and Arena.
- MainMenu and PauseMenu now include a **Help / Controls** button that opens the controls reference without owning gameplay state.
- **H / F11** toggles Help / Controls through the `help_toggle` input action. F11 is available as a browser/editor fallback.
- During active gameplay, opening Help pauses the run and resets mobile controls; closing it resumes only when Help created that pause.
- If Help is opened from PauseMenu, closing it returns to the paused menu state.
- Help does not open over Settings, LevelUpScreen, EvolutionRewardScreen, VictoryScreen, or GameOverScreen.
- The content is centralized in `ControlsHelpContent.gd` and covers basic controls, active abilities, run systems, meta progression, debug mode, and mobile controls.

### Remember Last Choice QoL

- **UserPreferencesManager** stores small non-gameplay preferences separately from meta progression and settings.
- Last confirmed hero and stage are saved to `user://superheroes_user_preferences.json`.
- CharacterSelect preselects the remembered hero when it is valid and playable; otherwise it falls back to the default hero.
- StageSelect preselects the remembered stage when it is valid; otherwise it falls back to the default stage.
- RunBriefingScreen appears after StageSelect confirmation and before Arena start, using the remembered/confirmed hero and stage.
- MainMenu shows a compact `Last: Hero / Stage` hint when remembered choices are available.
- Restart keeps the current run hero/stage, while returning to MainMenu and starting a new flow uses the remembered choices.
- Preference reset is available through `UserPreferencesManager.reset_preferences()` and does not reset meta progression or settings.

### Feedback Polish Pack

- **FeedbackManager** (`scenes/feedback/FeedbackManager.gd/.tscn`) — central non-gameplay feedback router. Gameplay scripts request visual/audio feedback without duplicating logic.
- **Configurable screen shake** — `SettingsManager` stores `screen_shake_enabled` (bool) and `screen_shake_intensity` (float 0–2). SettingsMenu exposes a checkbox and a slider. All shake calls go through FeedbackManager and scale by intensity.
- **Configurable floating text** — `floating_text_enabled` (bool) in SettingsManager. FeedbackManager gates all floating text spawns; critical texts (player damage, heal, evolution) bypass the cap while the throttle limits non-critical spawns to 6 per 0.08 s window.
- **Configurable impact flash** — `impact_flash_enabled` (bool) in SettingsManager. Enemy and player hit flashes are routed through FeedbackManager.
- **Improved powerup feedback** — Each powerup type shows a distinct colored label: `+HP` (green), `SHIELD` (blue), `BOMB` (red), `MAGNET` (purple), `SPEED` (cyan), `HASTE` (yellow). Bomb also triggers a small screen shake.
- **Improved hit feedback** — Enemy hit flash brightened (red→white over 0.12 s). Shielded enemies show a blue-white flash when shield absorbs a hit instead of the normal red-white flash.
- **Improved player damage feedback** — Real HP damage triggers small screen shake + floating damage number. Shield block shows `BLOCK` floating text instead. Dash/debug invulnerability suppresses all feedback.
- **Improved ability feedback** — slot 1 and slot 3 casts route their shakes through FeedbackManager to respect the intensity setting.
- **Improved boss/evolution feedback** — Elite, miniboss, and final boss spawns show announcements with shake. Evolution shows `EVOLVED` floating text near player + small shake.
- **Improved MetaUpgradeShop** — Purchased row briefly flashes green on successful buy.
- **DebugStatsOverlay** — `-- Feedback --` section shows current screen shake, intensity, floating text, and impact flash settings when Debug Mode is ON (F12).

Not implemented yet (feedback):
- Custom VFX asset pack.
- Sound effect pack.
- Object pooling for floating text.
- Advanced particles.
- Hit stop.
- Controller rumble.

### Miniboss + Final Boss Encounter Rework

- **Miniboss remains a normal-wave pressure event.** Miniboss spawns during regular waves via EventDirector (at 2:30). Normal enemies continue spawning around the player while the miniboss is alive. The miniboss health bar tracks the miniboss; defeat still grants the existing evolution reward flow. No enemies are cleared and no arena is created for the miniboss.
- **Final boss is now a separate arena duel.** When the run timer reaches the target time (`target_time_reached`), the game transitions into a dedicated final boss encounter instead of directly spawning the boss in the open field:
  1. EnemySpawner's regular spawn timer and wave timer are stopped.
  2. EventDirector stops firing new events (elite, miniboss, timed modifiers).
  3. All non-final-boss enemies are silently despawned (`queue_free`) with no XP or powerup drops.
  4. A 1200×900 temporary boss arena `Rect2` is built centered on the player, clamped to the full playable field.
  5. `Player.set_playable_rect()` and `Player.set_camera_limits()` are applied to the smaller arena, so the player is bounded inside it.
  6. An orange `Line2D` outline draws the arena boundary in world space (purely visual — no collision, no damage).
  7. "Final Boss Arena!" is announced via EventAnnouncement with a screen shake.
  8. The final boss spawns at the center of the boss arena. BossHealthBar and HUD track the boss as before.
  9. Existing boss phases (phase 2 at 50% HP, enraged announcement) still work.
- **No arena hazards were added.** The boundary Line2D is display-only and applies no damage to the player or enemies.
- **Cleanup:**
  - On final boss defeat: boundary is removed; victory flow triggers as before.
  - On player death, restart, or quit to menu: boundary is cleared before the transition.
- **XP gems and powerup pickups** already on the ground are kept; they can still be collected during the boss fight.
- **Enemy projectiles** already in flight are kept; they expire naturally by their max_lifetime.

### Stage Objectives & Win Conditions

Each stage now has a distinct gameplay objective that shapes how the run plays out. The final boss remains the victory climax for all stages. No damaging arena hazards were added.

#### Stage Objectives

| Stage | Objective Type | Win Condition |
|-------|---------------|---------------|
| City Rooftop | **Survival** | Survive 10:00, then defeat the Titan Guardian. |
| Neon Lab | **Defense** | Defend the Lab Reactor for 10:00, then defeat the Prism Overlord. Reactor reaching 0 HP ends the run in defeat. |
| Wasteland Gate | **Destroy Structures** | Destroy all 3 Dark Portals to trigger the final boss, then defeat the Molten Colossus. |

#### City Rooftop — Survival

- Classic timer-based survival. Enemies spawn in waves for 10:00.
- Final Phase begins at 9:00. Boss phase triggers at 10:00.
- HUD shows "Survive MM:SS / 10:00" as before.
- No new objective entities spawned.

#### Neon Lab — Defense

- A **Lab Reactor** structure spawns near the player at arena start.
- Enemies deal contact damage to the Reactor (15 HP/s per enemy in contact).
- The player must stay near the Reactor to prevent enemies from destroying it.
- **HUD** shows live Reactor HP (color-coded: blue → amber at 60% → red at 30%).
- If the Reactor HP reaches 0, the run ends immediately in defeat ("Reactor Destroyed!").
- If the Reactor survives until 10:00, the final boss phase triggers normally.

#### Wasteland Gate — Destroy Structures

- Three **Dark Portals** spawn at spread positions across the arena.
- Portals are damageable by player attacks and abilities (150 HP each, pulsing purple).
- **HUD** shows "Portals: N / 3".
- Destroying all 3 portals immediately triggers the final boss encounter.
- No timer countdown required — portals can be destroyed at any time.
- Player death still ends the run in defeat regardless of portal count.

#### Architecture Notes

- `StageObjectiveManager` (new, `scenes/objectives/`) is instantiated at Arena start for defense and destroy_structures stages; survival stages require no extra node.
- `DefenseObjective` (new) detects enemy contact via its own Area2D (mask=2); enemies never need to know about the structure.
- `PortalObjective` (new) extends `StaticBody2D` on the enemy collision layer so existing player projectile and auto-attack systems naturally damage it.
- `RunManager.mark_boss_phase_triggered()` (new) lets the objective manager signal the end of the portal phase without waiting for the timer.
- For destroy_structures, `Arena._setup_run_lifecycle()` skips connecting `target_time_reached` to the boss phase handler; the objective completion fires the trigger instead.
- Restart and quit-to-menu paths call `StageObjectiveManager.cleanup()` before transitioning.

### Enemy Roles & Wave Director 2.0

Waves now feel intentional, role-based, and stage-specific. This patch sits entirely inside `SpawnDirector` and `EnemySpawner`; hero kits, bosses, upgrades, rewards, and saves are unchanged.

#### Enemy Roles

Each enemy variant now carries a `role` field used by the Wave Director for package selection:

| Role | Variants | Pressure style |
|------|----------|---------------|
| swarmer | grunt, swarm | Weak mass pressure |
| hunter | runner, charger | Fast chase pressure |
| bruiser | tank, shielded | Slow durable body-block |
| shooter | shooter | Ranged pressure |
| disruptor | exploder, support | Special / area pressure |

All existing `behavior_id` values remain unchanged.

#### Run Director / Wave Director 2.0

`SpawnDirector` is the single source of truth for all enemy spawning. It has been reworked into a full **Run Director** with a 5-phase model, wave budget system, package phase-weighting, and wave warnings. `EnemySpawner` calls its APIs and drives the timers; `SpawnDirector` never spawns enemies directly.

##### Run Phases

The 10-minute run is divided into 5 named phases. Each phase controls spawn pressure, max-alive scaling, wave interval, and preferred enemy roles.

| Phase | Time | Spawn Pressure | Wave Interval | Character |
|-------|------|---------------|---------------|-----------|
| early | 0–120 s | ×0.75 (slower) | ~14.3 s | Readable — grunts/runners only |
| build | 120–240 s | ×0.9 | ~12.1 s | Ramps up — mixed roles |
| pressure | 240–360 s | ×1.1 | ~10.5 s | Noticeable — bruiser/shooter/disruptor |
| danger | 360–480 s | ×1.3 | ~9.4 s | Intense — stronger mixed waves |
| pre_boss | 480–600 s | ×1.5 | ~8.3 s | Peak tension — disruptor/mixed/bruiser |

Phase API:
- `get_current_run_phase() -> String` — current phase id
- `get_current_phase_data() -> Dictionary` — full phase dict
- `get_phase_progress() -> float` — 0.0–1.0 progress within current phase
- `debug_get_run_director_state() -> Dictionary` — run_time, phase, phase_progress, spawn_interval, max_alive, wave_interval, last_wave_package, stage_profile, wave_budget_remaining

##### Wave Packages

Wave packages are role-themed enemy bursts fired on a separate timer. Each package has `phase_weights` (per-phase weight multipliers), `budget_cost`, `min_phase` / `max_phase` gating, `warning_level`, and `package_cooldown`.

| Package | Role | Count | Min Phase | Budget Cost |
|---------|------|-------|-----------|-------------|
| early_grunts | swarmer | 2–3 | early | 0.5 |
| runner_pack | hunter | 2–3 | early | 0.5 |
| bruiser_wall | bruiser | 1–2 | build | 1.0 |
| shooter_screen | shooter | 1–2 | build | 1.0 |
| exploder_pressure | disruptor | 1–2 | pressure | 1.5 |
| swarm_rush | swarmer | 2–4 | pressure | 1.5 |
| shielded_push | bruiser | 1–2 | pressure | 1.5 |
| support_pair | disruptor | 1–2 | danger | 2.0 |
| mixed_late_wave | mixed | 2–3 | danger | 2.5 |

##### Wave Budget

Each phase has a maximum wave budget. Packages are filtered to those whose `budget_cost` fits the remaining budget. If no package fits, all available packages are used as a safety fallback. Budget resets each time a new phase begins.

| Phase | Budget |
|-------|--------|
| early | 2.5 |
| build | 3.5 |
| pressure | 5.0 |
| danger | 6.0 |
| pre_boss | 6.0 |

##### Wave Warnings

High-intensity packages (warning_level ≥ 1) trigger a brief `EventAnnouncement` before spawning. A 12 s cooldown prevents warning spam. Warnings are silently skipped if `EventAnnouncement` is unavailable.

##### Stage Wave Identity

Stage event profiles bias package selection via per-profile weight bonuses on specific packages:

| Stage | Profile | Favoured packages |
|-------|---------|------------------|
| City Rooftop | balanced | Mixed — bruiser_wall and mixed_late_wave get small bonus |
| Neon Lab | ranged_support | shooter_screen ×1.5, support_pair ×1.4, shooter/support variants ×1.25 |
| Wasteland Gate | swarm_exploder | swarm_rush ×1.5, exploder_pressure ×1.5, swarm/exploder variants ×1.3 |
| (future) | defense_pressure | stub |
| (future) | portal_pressure | stub |

##### Spawn Safety

- Every package spawn checks `enemy_container.get_child_count() >= _get_current_max_alive_enemies()` before each enemy.
- If the cap is reached mid-package, remaining enemies are skipped (no burst overflow).
- Package size is capped at `max_count + 2` even at maximum time scaling.
- Individual per-enemy timer runs alongside wave packages; together they respect the cap.
- Spawn interval has a hard floor of 0.20 s regardless of phase or event modifiers.

##### Debug

`DebugStatsOverlay` (F12) Spawner section shows:
- `Phase: <id>  Profile: <stage_profile>`
- `MaxAlive: <cap>  Budget: <remaining>`
- `Interval: <spawn interval>`
- `WaveEvery: <wave interval in seconds>`
- `Last pkg: <last wave package id>`

`EnemySpawner.spawn_debug_logging = true` prints `WAVE_PACKAGE: id=... role=... alive=N/M` each time a package fires.

Not included in Wave Director 2.0 patch: Boss Encounter 2.0, Stage Objectives Pack, arena hazards.

#### Enemy Roles + Counterplay Pack

Every enemy variant carries role metadata (`role`, `role_display_name`, `threat_level`, `counterplay_hint`) and is designed with a distinct visual color, behavior, and readable counterplay.

##### Enemy Roles and Counterplay

| Variant | Role | Threat | Behavior | Counterplay |
|---------|------|--------|----------|-------------|
| Grunt | swarmer | 1 | Chase | Easy target; manageable in small groups. |
| Runner | hunter | 2 | Fast chase | Keep moving; fragile but fast. |
| Charger | hunter | 2 | Charge windup | Sidestep the charge; vulnerable during cooldown. |
| Tank | bruiser | 3 | Slow chase | High HP, slow; kite around it. |
| Shooter | shooter | 3 | Ranged + preferred distance | Break line of sight or close the gap fast. |
| Exploder | disruptor | 4 | Chase + windup explode | Do not let it reach you; move away from the pulse. |
| Swarm | swarmer | 2 | Orbit + approach | AoE or keep moving; dangerous in numbers. |
| Shielded | bruiser | 3 | Chase with shield HP | Burst through shield or use AoE; shield doesn't last. |
| Support | disruptor | 4 | Buff nearby enemies | Kill it before it buffs the wave. |
| **Splitter** | swarmer | 3 | Chase + split on death | Kill before it splits; children swarm you. |
| **Disruptor** | disruptor | 3 | Standoff + pulse damage | Stay out of its pulse radius or prioritize it. |

##### Splitter

The Splitter (yellow-green, unlocks at 240 s) chases the player with `behavior_id = "chase"` and **splits into 2 Grunts on death**. Split children have `is_split_child = true` so they cannot split again. Spawning respects `max_alive_enemies` and is capped at 3 children. Not spawned during the final boss encounter.

##### Disruptor

The Disruptor (bright cyan, unlocks at 300 s) uses `behavior_id = "disruptor"`. It maintains a standoff distance from the player (~140 px) and fires a **cyan pulse** every 3 s. If the player is within `disrupt_radius` (200 px) when the pulse fires, it deals 10 damage. The pulse is telegraphed by a bright color flash. Kill it or maintain distance to avoid damage.

##### Visual Feedback

- **Charger**: yellow windup flash before charge.
- **Exploder**: scale pulse + orange windup glow during countdown.
- **Support**: yellow burst when applying buff to nearby enemies.
- **Shielded**: blue-white hit flash when shield absorbs damage.
- **Splitter**: yellow-green body; death produces grunt children with standard death burst.
- **Disruptor**: cyan body; pulses bright cyan before dealing area damage.

##### Wave Package Pacing by Phase

| Phase | Available packages |
|-------|--------------------|
| early | early_grunts, runner_pack |
| build | + bruiser_wall, shooter_screen, charger_rush |
| pressure | + exploder_pressure, swarm_rush, shielded_push, support_pair |
| danger | + mixed_late_wave, splitter_wave, disruptor_squad |
| pre_boss | + chaos_wave (charger + disruptor + splitter mixed) |

Not included in this patch: Boss Encounter 2.0, Stage Objectives Pack, arena hazards.

### Balance / Cleanup / Production Readiness

- **GameplayTuning** (`scenes/game/GameplayTuning.tscn`) centralizes exported balance defaults for debug logging, run timing, spawn distances/caps, powerup drop chance, core ability values, and player defaults.
- **Configurable debug logs** keep debug tools functional while disabling noisy `DEBUG_*` and `POWERUP_*` logs by default.
- **ProjectHealthCheck** runs once at Arena startup and prints concise warnings only when critical wiring is missing.
- **Lightweight safeguards** clamp max alive enemies, projectile count, projectile bounce count, explosion radius, and miniboss barrage count.
- Current balance review areas: enemy spawn progression, ability cooldown/damage roles, projectile synergies, powerup drop pressure, miniboss readability, restart/victory/game-over flow, and browser-friendly runtime load.

### Character Select & Hero Roster v1

- **CharacterSelect** sits between MainMenu and Arena; Main owns the menu/selection/run transition.
- **HeroDataProvider** owns three hardcoded starter heroes for now: Guardian, Blaster, and Vanguard.
- **Solar Guardian** is an original solar/flying powerhouse archetype: durable beam attacker with Solar Energy passive, a focused beam ability, frost cone with slow, and a damage dash with invulnerability. Autoattack is a direct beam (no projectile). Guardian does not receive multishot, spread, or nova/laser/slam upgrades — uses dedicated solar_ray / solar_beam / frost_breath / death_dash upgrade lines.
- **Night Tactician** keeps the `blaster` hero id and is a rocket tactician: 90 HP, 275 speed, +2 attack damage, +1 starting projectile, slightly faster attacks (0.98×), faster ability cooldowns (0.95×). Fires homing rockets that track individual enemies (no pierce, no bounce). Active abilities apply Tactical Mark (multi-enemy, duration-based). Upgrade lines: rocket_damage/count/explosion_radius/reload/marked_target_payload (attack slots); smoke_screen_radius/duration/slow/damage_reduction, trap_radius/damage/cooldown_down/mark_bonus, hook_damage/range/cooldown_down/mark_bonus (active slots).
- **Fury Vanguard** keeps the `vanguard` hero id and is a rage bruiser: 125 HP, 245 speed, +2 attack damage, slightly heavier attack timing (1.08×). Autoattack is `splash_melee` (Fury Strikes) — close-range AoE, no projectile, Rage-scaled damage. Abilities: Rage Wave (circle AoE + slow), Mighty Clap (cone AoE + knockback), Rage Leap (dash + landing AoE + slow). Rage passive builds from damage taken and dealt, decays over time, and scales all damage. Upgrade lines: `splash_melee_damage/radius/speed/impact/frenzy/shockwave/lifesteal/combo/execute` (9 attack slots); `rage_wave_power/radius/deep_slow`, `mighty_clap_power/range/shockwave`, `rage_leap_power/radius/cooldown` (9 active slots).
- CharacterSelect hero detail cards list the current identities: `guardian` = Solar Guardian, `blaster` = Night Tactician, `vanguard` = Fury Vanguard.
- CharacterSelect remains UI-only and display-only: it reads hero data and Training summaries, but does not change hero stats, balance, Training levels, rewards, saves, stages, enemies, arena logic, or persistence.
- **HeroApplier** applies run-only starting stats to Player, AutoAttack, and AbilityManager before gameplay systems start.
- Solar Guardian, Night Tactician, and Fury Vanguard use hero-specific ability presentation names and combat kit behavior while preserving the global ability slots and input actions.
- Final integrated hero ability names:
  - Solar Guardian: Solar Beam, Frost Breath, Death Dash.
  - Night Tactician: Smoke Screen, Explosive Trap, Grappling Hook.
  - Fury Vanguard: Rage Wave, Mighty Clap, Rage Leap.
- Night Tactician presents slot 1/2/3 as Smoke Screen, Explosive Trap, and Grappling Hook. The underlying ability ids and input actions remain unchanged.
- Fury Vanguard presents slot 1/2/3 as Rage Wave, Mighty Clap, and Rage Leap. The underlying ability ids and input actions remain unchanged.
- Hero kit ids are `solar_guardian`, `night_tactician`, and `fury_vanguard`; stable hero ids remain `guardian`, `blaster`, and `vanguard`.
- Hero rework integration polish keeps balance, persistence, rewards, enemy values, stage values, and meta economy unchanged.
- HUD, mobile controls, debug overlays/logs, and level-up ability descriptions now use the selected hero's display names while preserving internal ability ids.
- Selected hero appears in GameHUD and in Victory/GameOver run summaries.
- Restart from Victory/GameOver keeps the same selected hero; returning to MainMenu allows choosing a different hero.
- No licensed superhero names, brands, or protected character identities are used.

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

#### Per-Hero Training

- Guardian, Blaster, and Vanguard have separate Training upgrade levels.
- Meta currency remains shared/global.
- Training purchases apply only to the selected Training hero.
- Runs apply only the selected run hero's Training bonuses.
- Existing old global Training saves are migrated by copying global levels to each existing hero.
- The reward-training bonus is read from the selected run hero's Training.

#### Post-Run Progression & Unlock Goals

- **Run summary enrichment** - Arena adds objective result, final boss result, applied evolution counts/titles, Attack/Passive/Active slot counts, dominant archetype, and a conservative run grade (`S/A/B/C`) before emitting `run_result_ready`.
- **Hero Mastery** - `MetaProgressionManager` tracks per-hero runs, victories, kills, elite/miniboss/final-boss kills, total selected evolutions, selected Attack/Active/Passive evolution counts, and highest mastery level. Mastery is derived from conservative run milestones and updates only for the selected run hero.
- **Stage Mastery** - City Rooftop, Neon Lab, and Wasteland Gate track attempts, victories, objective completions, final boss kills, best grade, and best victory time separately.
- **Unlock Goals / Challenges** - goals expose id/title/description/category/reward/progress/completed/claimed fields through `get_goal_progress()`. Current goals cover stage wins/objectives, hero-specific evolution milestones, final boss kills, elite kills, and beginner mastery.
- **Goal rewards** - goal rewards are auto-claimed on the run that completes them and are added to the post-run currency total once. `claim_goal_reward(goal_id)` remains available as a safe manual API for future non-auto-claim UI.
- **Save migration** - save version 3 adds `hero_mastery`, `stage_mastery`, and `goals` with defaults while preserving existing currency, per-hero Training, unlocked heroes, and lifetime totals.
- **Training Goals snapshot** - MetaUpgradeShop shows a compact read-only goals progress line above Training rows. It does not claim rewards or mutate goals.
- **Character Equipment Foundation** - save version 4 adds `equipment_by_hero`, a per-hero dictionary of fixed equipment levels. Existing currency, per-hero Training, hero mastery, stage mastery, goals, unlocked heroes, rewards, and lifetime totals are preserved during migration.
- **Equipment Upgrade Integration** - fixed hero equipment can now be upgraded with shared currency. Equipment levels are per-hero, emit `equipment_upgrade_changed`, and save after each successful purchase.

### Inventory Data & Equipment Swapping Foundation

- Each hero has a persistent inventory (`inventory_by_hero`) and equipped item tracking (`equipped_by_hero`) added in save version 5.
- Items are instances with unique `instance_id`, referencing a `template_id` from equipment definitions or alternative item templates.
- Starter inventory: 6 equipped items + 2 alternative items per hero (one alternative in the Core slot, one in the Gauntlets slot).
- Players can select any inventory item and equip it into its matching slot using the Equip button.
- Equipping is free — no currency cost.
- Gameplay modifiers (`get_equipment_stat_modifiers_for_hero`) come only from currently equipped items.
- The Equipped Gear panel shows the name and level of whichever item instance is currently equipped in each slot.
- Save migration: existing saves without `inventory_by_hero` are automatically populated with starter inventory data, copying existing equipment upgrade levels into the equipped item instances.
- No gacha, random loot, or item drops in this patch.

### Inventory Item Details & Compare UI

- Selecting an inventory item shows: name, slot, level/max, status (EQUIPPED / In Inventory), stat bonus per level, and total bonus.
- Comparison panel shows the currently equipped item in the same slot with stat delta (+/− better/worse/equal).
- When the selected item IS the equipped item: compare section says "This item is currently equipped."
- When no item is equipped in the slot: compare section says "No item currently equipped in this slot."
- Empty cells display "[Empty Slot] / No item selected." as a placeholder hint.
- Inventory cell color states: equipped = green tint, selected+equipped = bright green highlight, selected+unequipped = yellow-white highlight, empty = muted gray.
- Equip button: "Equip" (enabled, green) for compatible unequipped items; "Equipped" (disabled, muted) if already equipped or nothing selected.
- Clicking an equipped slot panel on the left Equipped Gear panel selects that item in the inventory grid and updates the detail panel.
- Detail label is inside a ScrollContainer so longer text scrolls without pushing other UI.
- New read-only MetaProgressionManager helpers: `get_item_template_for_instance`, `get_equipped_instance_id_for_slot`, `get_item_stat_total`.
- No drag-and-drop, gacha, random loot, item drops, or random affixes in this patch.

### Training UI Tabs + Inventory Shell

The screen now has these tabs:

- **Equipment tab**: Uses a horizontal layout. The left panel is Equipped Gear with selected hero preview, Core, Suit, Emblem, Gauntlets, Boots, Artifact, levels, stat bonuses, and existing upgrade buttons. The right panel is Inventory with live item instances.
- **Inventory grid**: Shows at least 20 square cells. Each owned item appears as a cell showing short name, slot, level, and `[E]` tag when equipped. Clicking a cell updates the detail label and enables or disables the Equip button. Clicking Equip swaps the item into its slot immediately.
- **Training tab**: Shows the existing scrollable Training upgrades list with buy buttons, level display, currency gating, max state, and per-hero levels unchanged.

The Training screen (`MetaUpgradeShop`) is now a tabbed character progression screen. The large top Training HUD was compacted into a persistent navigation row with **Equipment**, **Training**, a small currency label, and an always-visible **Main Menu** button. `ui_cancel` / Escape still closes the screen through Main's existing safe back flow.

- **Navigation row**: Equipment tab, Training tab, compact currency, and Main Menu button remain visible above tab content.

Current behavior: the visible hero selector buttons and the large standalone Training title are removed from this screen; selected hero context is shown inside tab content, and the top row stays compact.

Equipment slots are backed by fixed hero equipment definitions:

- **Solar Guardian**: Solar Core, Radiant Suit, Sun Emblem, Power Gauntlets, Flight Boots, Aegis Artifact.
- **Night Tactician**: Tactical Core, Shadow Suit, Signal Emblem, Gadget Gauntlets, Grapnel Boots, Drone Artifact.
- **Fury Vanguard**: Rage Core, Titan Suit, War Emblem, Impact Gauntlets, Heavy Boots, Fury Artifact.

Each definition includes `equipment_id`, `hero_id`, `slot_id`, `slot_name`, `display_name`, `description`, `max_level`, `base_cost`, `cost_growth`, `stat_bonus_type`, `stat_bonus_per_level`, and `tier`. Levels persist in `equipment_by_hero`, default to `0`, and upgrade costs use the definition's `base_cost` / `cost_growth`.

The equipment panel hero preview updates from the hero id resolved by Main when Training opens. Each slot shows hero-specific equipment name, `Level current / max_level`, bonus per level, current total bonus, next-level bonus, and a currency-gated Upgrade button. Buttons show `Upgrade X` when affordable, `Need X` when unaffordable, and `MAX` at max level. The Collection detail panel also shows a compact read-only equipment summary.

Supported equipment bonuses are applied at run start for the selected hero only through `MetaApplier`, after hero stats and alongside Training: max health, move speed, XP gain, attack damage, ability damage, ability cooldown reduction, Tactical Mark damage, Rage gain, and starting shield charges. Future-facing stat ids remain aggregated/debuggable but are ignored by gameplay until a safe system exists for them.

### Training Equipment Polish / Inventory Reset

- Hero dropdown (OptionButton) in the Training nav row selects the active hero for both Equipment and Training tabs
- Static starter inventory items cleared on load via migration flag `inventory_static_items_cleared` (idempotent — runs once per save)
- Equipped slots are now clickable: clicking a slot panel opens a popup showing item name, level, stat bonus, and description
- Popup has an Unequip button that moves the item back to inventory without deleting it; empty slots show Unequip disabled
- Empty equipped_by_hero is a valid state — runs start normally with zero gear equipped and zero equipment modifiers
- Inventory grid remains 5 columns (72 px cells)
- Equipped Gear panel is wider (580 px min) and Inventory panel is narrower (410 px min) for a tighter fit
- Save version incremented to 6; old saves are migrated automatically
- No gacha, random loot, item drops, affixes, crafting, or fusion

### Inventory Filters & Sorting

- Filter by slot: All / Core / Suit / Emblem / Gauntlets / Boots / Artifact
- Filter by state: All / Equipped / Unequipped
- Sort by: Default / Slot / Level High / Level Low / Name
- Empty cells are always shown after filtered results
- Selection is preserved when the selected item remains visible after filtering
- Inventory remains static/deterministic — no gacha, random loot, item drops, affixes, crafting, or fusion

Not implemented yet (equipment):
- Item drops or gacha pulls.
- Random item stats or item ownership lists.
- Locking items to prevent accidental equip.
- More than 2 alternative items per hero.

Not implemented yet (meta):
- Gacha pulls, shards, and banner system (collection screen foundation exists).
- Advanced hero unlock purchase UI.
- Per-hero favorite presets.
- Build loadouts.
- Training reset UI.
- Hero-specific currencies.
- Online leaderboard.
- Cloud save / Yandex save.
- Ads, paid purchases, or monetization.
- Achievements.
- Prestige or season resets.

### Bosses, Stages & Content Expansion v1

- **StageSelect** screen between CharacterSelect and RunBriefingScreen; shows stage list cards (left) and a scrollable detail panel (right: color swatch, name, subtitle, difficulty, description, threat summary, run objective, recommended playstyle, and final boss preview). Back returns to CharacterSelect; Start Run advances to briefing with the original stage id.
- **RunBriefingScreen** is a display-only confirmation screen before Arena. It shows selected hero, selected stage, hero ability names, compact per-hero Training summary, stage objective, and final boss preview. Start Run advances to Arena; Back returns to StageSelect.
- The briefing screen is UI-only and does not change gameplay balance, hero stats, stage settings, enemy values, rewards, upgrade values, save format, persistence, or arena hazards.
- **StageDataProvider** owns 3 hardcoded stage presets:
  - **City Rooftop** - balanced rooftop pressure, Normal difficulty, `balanced` event profile, final boss: Titan Guardian, 10 min run.
  - **Neon Lab** - ranged support pressure, Hard difficulty, `ranged_support` event profile, final boss: Prism Overlord, 10 min run.
  - **Wasteland Gate** - swarm / exploder pressure, Hard difficulty, `swarm_exploder` event profile, final boss: Molten Colossus, 10 min run.
- Stage identity metadata (`threat_summary`, `stage_goal`, `recommended_playstyle`, `enemy_pressure`, `boss_preview`) is display-only. This StageSelect polish does not change stage balance, event profile behavior, final boss behavior, rewards, persistence, or arena hazards.
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

### 3/3/3 Evolution System

- **EvolutionManager** owns runtime-only evolution definitions and applied evolution state for the current run.
- **EvolutionRewardScreen** is a display-only paused reward screen; Arena opens it and applies selected evolutions.
- Each hero has 9 evolution triples organized as 3 attack targets, 3 active targets, and 3 passive targets.
- Each triple still requires exactly 1 attack upgrade line, 1 passive upgrade line, and 1 active upgrade line, all selected and maxed.
- Triple definitions use `target_type` (`attack`, `active`, `passive`) plus `target_id`; old `target_active_skill_id` remains supported as active-evolution compatibility data.
- The current implemented packs include all nine Attack, Active, and Passive Evolutions Pack effects. Evolution state remains runtime-only and is selected through Overdrive.
- Elite evolution rewards are supported behind `EvolutionManager.elite_reward_chance`, defaulting to `0.0`.
- GameHUD shows current evolution state, and Victory/GameOver summaries list applied evolutions.
- Debug Mode F9 can open the evolution reward screen when implemented evolutions are available.

### Overdrive Trigger & First Game-Breaking Evolutions

The Evolution Triple Grid (27 triples, 9 per hero) now fires an **Overdrive** choice screen whenever a triple becomes READY after an upgrade is applied, but only implemented effects are offered.

#### Overdrive Flow

1. Player picks an upgrade from LevelUpScreen.
2. Arena calls `EvolutionManager.get_overdrive_options()` to collect READY, not-yet-selected triples for the active hero.
3. Placeholder/future evolutions are filtered out so no no-op evolution is offered.
4. If any implemented READY triples exist, **OverdriveScreen** opens (paused, layer 22, no skip). Player must select one.
5. `EvolutionManager.apply_evolution(evolution_id)` routes by `target_type`: active to AbilityManager, attack to PlayerAutoAttack, passive to PassiveAbilityManager.
6. Only a successfully applied evolution is marked SELECTED and announced.
7. The evolved skill permanently replaces its base behavior for the rest of the run. Only one evolution per triple; no stacking.

#### Implemented Evolutions (27 of 27)

| Evolution ID | Hero | Target Type | Target ID | Effect |
|---|---|---|---|---|
| `solar_beam_cataclysm` | Solar Guardian | active | `solar_beam` | 3x damage, 1.8x range/width, fires a delayed burn pulse (0.18 s); status: CATACLYSM |
| `solar_beam_sky_lance` | Solar Guardian | attack | `solar_ray` | Solar Ray gains much longer range and a wider red lance corridor; status: SKY LANCE |
| `solar_beam_burning_judgment` | Solar Guardian | attack | `solar_ray` | Solar Ray adds burning heat pulses after hits, doubled during Solar Empowered; status: BURNING JUDGMENT |
| `frost_breath_absolute_zero` | Solar Guardian | active | `frost_breath` | 2x damage, 1.8x cone angle, double slow (0.08 speed + 0.02 freeze), status: ABSOLUTE ZERO |
| `frost_breath_glacier_front` | Solar Guardian | attack | `solar_ray` | Despite the legacy id, evolves Solar Ray with a delayed radiant line pulse; status: SOLAR GLACIER FRONT / SOLAR PULSE |
| `frost_breath_permafrost` | Solar Guardian | passive | `orbit_shields` | Solar Aegis: more/faster shields and solar AoE on shield block; status: SOLAR AEGIS |
| `death_dash_solar_execution` | Solar Guardian | active | `death_dash` | Real active grid id for Final Flash: long execution dash, low-health bonus damage, solar flash pulse after multi-hit dashes; status: FINAL FLASH |
| `death_dash_comet_path` | Solar Guardian | passive | `storm_relay` | Solar Storm: frequent multi-target solar lightning, stronger while Solar Empowered; status: SOLAR STORM |
| `death_dash_final_flash` | Solar Guardian | passive | `recovery_field` | Radiant Renewal: stronger heal, damaging radiant pulse, and brief damage reduction; status: RADIANT RENEWAL |
| `smoke_screen_blackout` | Night Tactician | active | `smoke_screen` | Huge longer Blackout field with repeated slow/marks and stronger player damage reduction inside; status: BLACKOUT |
| `smoke_screen_tactical_cover` | Night Tactician | attack | `homing_rockets` | Homing Rockets fire extra support rockets and spread cover fire across targets; status: TACTICAL COVER |
| `smoke_screen_choking_zone` | Night Tactician | attack | `homing_rockets` | Rocket impacts leave choking slow/mark bursts; status: CHOKING ZONE |
| `trap_chain_detonation_evolution` | Night Tactician | active | `explosive_trap` | 2x damage, 2x explosion radius, two aftershock pulse rings (0.2 s + 0.42 s), marks all hit enemies; status: CHAIN DETONATION |
| `trap_cluster_minefield` | Night Tactician | attack | `homing_rockets` | Rocket impacts split into clustered secondary explosions; status: CLUSTER MINEFIELD |
| `trap_marked_blast` | Night Tactician | passive | `guardian_drone` | Tactical Drone Swarm: multiple drone shots that apply Tactical Mark; status: DRONE SWARM |
| `hook_execution_pull` | Night Tactician | active | `grappling_hook` | 3x damage; if target was already Tactically Marked, triggers AoE mark explosion on hit enemies; status: EXECUTION |
| `hook_shadow_line` | Night Tactician | passive | `chain_lightning` | Shock Net: prefers marked enemies, bounces farther, and marks hit enemies; status: SHOCK NET |
| `hook_rapid_abduction` | Night Tactician | passive | `time_dilator` | Stasis Field: larger near-freeze slow pulse, stronger against marked enemies; status: STASIS FIELD |
| `rage_wave_worldbreaker` | Fury Vanguard | active | `rage_wave` | 2x damage, fires 3 expanding shockwaves (0 / 0.22 / 0.44 s), heavy 0.22x speed slow; status: WORLDBREAKER |
| `rage_wave_earthsplitter` | Fury Vanguard | attack | `splash_melee` | Fury Strikes carve a forward ground crack beyond normal melee reach; status: EARTHSPLITTER |
| `rage_wave_crushing_storm` | Fury Vanguard | attack | `splash_melee` | Fury Strikes scale harder with Rage and emit a slowing pressure pulse; status: CRUSHING STORM |
| `mighty_clap_thunderclap` | Fury Vanguard | active | `mighty_clap` | Real active grid id for Rampage Impact: huge Rage-scaled cone, heavy knockback, delayed second clap; status: RAMPAGE IMPACT |
| `mighty_clap_seismic_fan` | Fury Vanguard | attack | `splash_melee` | Fury Strikes emit a forward seismic fan; status: SEISMIC FAN |
| `mighty_clap_rampage_impact` | Fury Vanguard | passive | `static_field` | Rage Field: Rage-scaling damage aura with larger/faster pulses at high Rage; status: RAGE FIELD |
| `rage_leap_meteor_crash` | Fury Vanguard | active | `rage_leap` | 2x damage, 1.5x radius, ring visual, delayed second impact at 0.45 s (0.2x speed slow); status: METEOR CRASH |
| `rage_leap_blood_crater` | Fury Vanguard | passive | `battle_focus` | Berserker Focus: Rage-scaling focus strikes plus stronger attack-speed burst; status: BERSERKER FOCUS |
| `rage_leap_final_impact` | Fury Vanguard | passive | `magnet_core` | Gravity Rage: much stronger pickup reach plus periodic gravity pull/slow pulse; status: GRAVITY RAGE |

#### Architecture

- **OverdriveScreen** (`scenes/ui/OverdriveScreen.gd/.tscn`) builds UI procedurally. Cards show ATTACK / ACTIVE / PASSIVE EVOLUTION, title, target type/name, game-changing description, and all required attack/passive/active lines with current/max level and selected/maxed state. It uses a scroll area so the three-card choice fits mobile landscape.
- **EvolutionManager.get_overdrive_options()** returns merged dicts: triple definition + computed state (including `required_lines` for card display), filtered to implemented effects only.
- **EvolutionManager.get_evolution_grid_display_state()** and `get_synergy_info_for_upgrade_line(line_id)` expose read-only progress data for UI planning hints. These helpers report selected/ready/closest triples, missing line titles, target type, and 3/3 line/max progress; they never apply effects or mutate build slots.
- **EvolutionManager.apply_evolution()** calls `_apply_evolution_effect(evolution_id, triple)`, routes by `target_type`, then marks triple SELECTED only on success and emits `evolution_applied`.
- **AbilityManager evolution flags** are the current active-effect implementation surface. All flags reset in `set_hero_kit()`. The full active pack flags are `solar_beam_cataclysm_enabled`, `frost_breath_absolute_zero_enabled`, `death_dash_final_flash_enabled`, `smoke_screen_blackout_enabled`, `explosive_trap_chain_evolution_enabled`, `grappling_hook_execution_enabled`, `rage_wave_worldbreaker_enabled`, `mighty_clap_rampage_impact_enabled`, and `rage_leap_meteor_crash_enabled`.
- **PlayerAutoAttack.apply_attack_evolution(evolution_id, target_id)** is the attack-effect implementation surface. Attack evolutions are runtime-only, reset with the primary weapon on each fresh run, and expose `debug_get_attack_evolutions()` for debug UI.
- **PassiveAbilityManager.apply_passive_evolution(evolution_id, target_id)** is the passive-effect implementation surface. Passive evolutions are runtime-only, reset by `cleanup()`/fresh Arena setup, and expose `debug_get_passive_evolutions()` plus passive evolution ids/titles in `get_passive_state()`.
- **LevelUpScreen** can show compact Evolution hint lines on upgrade cards when the offered upgrade contributes to a known 3/3/3 triple. Arena enriches option dictionaries with read-only hint data before display; `UpgradeManager` still owns option generation and all selected upgrade state.
- **BuildSlotsWindow** remains read-only and shows selected evolution titles, ready evolution count, selected count, closest triple progress, per-slot evolution hints, and a compact ready/progress block. Evolutions do not consume build slots.
- **DebugStatsOverlay** (F12) shows total and selected Attack / Active / Passive evolution counts (`x/3`), ready count, closest triple progress, selected evolution titles, attack evolution ids, and passive evolution ids/titles when evolutions are applied.
- OverdriveScreen is closed (hidden) on victory, defeat, restart, and quit-to-menu. No evolution state is saved to meta.

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
- Cloud sync for user preferences.
- Settings UI reset button for user preferences.
- Last build preset.
- Favorite heroes or stages.
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
- Boss cutscene or elaborate transition animation.
- Buff icons.
- Powerup rarity tiers.
- Powerup upgrade scaling.
- Pickup object pooling.
- Advanced particle effects for powerups.
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

## Evolution Triple Grid Foundation

Each hero has a 9-line evolution grid using the 3/3/3 target schema:

- **3 attack evolution targets** for the hero primary weapon (`target_type: "attack"`).
- **3 active evolution targets** for hero active skills (`target_type: "active"`).
- **3 passive evolution targets** for shared passive skills (`target_type: "passive"`).

Every evolution triple still binds exactly:

- **1 attack upgrade line** (hero-specific autoattack upgrades)
- **1 passive upgrade line** (shared passives: Orbit Shields, Storm Relay, etc.)
- **1 active upgrade line** (hero-specific active skill upgrades)

### Triple Rule

```text
attack line + passive line + active line = evolution candidate for target_type / target_id
```

Each upgrade line can appear in only one triple per hero. Each hero has exactly 9 triples, one per grid index (1-9). Every hero attack line, every shared passive line, and every hero active line is used exactly once in that hero's triple grid.

### Ready Conditions

An evolution becomes **ready** only when:
1. All 3 required upgrade lines have been selected (any level taken).
2. All 3 required upgrade lines are at max level.
3. The effect is implemented. Unknown future placeholders remain hidden until their real handlers exist.

### Triple States

| State | Condition |
|-------|-----------|
| `locked` | No lines from this triple selected |
| `partial` | 1-2 lines selected |
| `collected` | All 3 lines selected, not all maxed |
| `ready` | All 3 lines selected AND all 3 at max level |
| `selected` | Evolution was chosen and applied |

### Implementation Status

- EvolutionManager tracks triple definitions, target schema, runtime state, selection, routing, and validation.
- Triple readiness is computed live from UpgradeManager slot state.
- 9 triples per hero (Guardian, Blaster, Vanguard) are defined with 3 attack / 3 active / 3 passive targets.
- Six active evolutions are implemented and preserved.
- The nine attack evolution definitions are implemented and offerable through Overdrive. Passive evolution definitions remain placeholders and are not offered to players.
- Evolution state is runtime-only: no save/meta persistence.

## Equipment Item Progression Rework

Equipment levels now belong to individual inventory item instances, not abstract hero slots. Every item in `inventory_by_hero` has its own `level` field that can be independently upgraded.

### What changed

- **Instance-level upgrading** — Each inventory item instance (equipped or unequipped) can be upgraded independently using shared currency. Upgrading an item increments its `level` field directly on the instance.
- **Two upgrade entry points**:
  1. **Equipped Gear slot** — The existing "Upgrade" button on each equipped slot still works. It now routes through `upgrade_inventory_item` internally so there is no double currency spend.
  2. **Inventory details panel** — Selecting any inventory item now shows an "Upgrade N" button in the inventory panel header. This upgrades the item regardless of whether it is currently equipped.
- **Gameplay modifiers** — Only equipped items affect gameplay. Unequipped items can be upgraded freely, but their stat bonuses do not apply until the item is equipped. The details panel shows "Affects gameplay: YES / NO" accordingly.
- **Legacy compatibility** — `purchase_equipment_upgrade(hero_id, equipment_id)` routes through `upgrade_inventory_item` when an equipped instance is found, so all existing callers (including Main.gd's `equipment_buy_requested` handler) work without changes. The `equipment_by_hero` legacy dictionary is kept in sync automatically.
- **No gacha, random loot, item drops, random affixes, crafting, or fusion.** Item levels are the only progression dimension.

### Detail panel additions

The inventory detail label now shows:
- **"Affects gameplay: YES / NO"** — whether this item is currently equipped and contributing to run stats.
- **"Next Level: +X.XX StatName"** — projected total stat at the next level (hidden at max level).
- **Upgrade button states**: "Upgrade N" (affordable), "Need N" (insufficient currency), "MAX" (at max level).

### No change to

- `MetaApplier` — still calls `get_equipment_stat_modifiers_for_hero`, which already reads only equipped instances.
- `Arena.gd` — not touched.
- Combat, hero kits, evolutions, rewards, stages, boss flow, in-run 4/4/4 rules.

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

## Stage Events & Objective Pressure

This patch makes each stage play differently through objectives and timed stage events. No arena hazards are added. Boss Encounter 2.0 is not part of this patch.

### Objective Types

| Type | Stage | Behavior |
|------|-------|----------|
| `survival` | City Rooftop | Survive until the final timer triggers the boss phase. Standard flow unchanged. |
| `defense` | Neon Lab | A **Lab Reactor** spawns at the arena center. Enemies in contact deal damage to it over time. If the Reactor reaches 0 HP the run ends in defeat. The HUD shows Reactor HP. |
| `destroy_structures` | Wasteland Gate | Three **Dark Portals** spawn across the arena. Each portal is damageable and targetable. Portals increase spawn pressure while alive. Destroying all portals triggers the final boss encounter. The HUD shows portal count. |

### Stage Objective Details

**City Rooftop — Survival**
- Standard arena survival to the 10:00 mark, then the Titan Guardian.
- EventDirector fires timed events: emergency wave warning (t=1:15), elite spawn (t=1:30), wave surge with spawn pressure boost (t=2:30), supply drop announcement (t=3:50), second elite (t=5:00), miniboss (t=7:00), pre-boss surge (t=8:00).
- No arena hazards.

**Neon Lab — Defense**
- Lab Reactor object placed at center of arena.
- Enemies touching the Reactor deal damage at a fixed rate. Final boss enemies do not damage the Reactor.
- Reactor HP is shown in the HUD objective label, color-coded by health ratio.
- If Reactor HP reaches 0 the run triggers defeat — game over screen shown.
- EventDirector fires: ranged support warning (t=1:00), elite (t=2:00), lab assault spawn pressure (t=3:20), reactor threat warning (t=4:50), miniboss (t=6:00), final lab assault (t=7:40).
- Run failure via objective does not rewrite the final boss flow.

**Wasteland Gate — Portal Closure**
- Three Dark Portals placed at fixed spread positions across the arena.
- Portals are `StaticBody2D`, added to the `enemies` group so player projectiles hit them.
- Each portal has HP (default 150). Portals take damage from player attacks via `take_damage()`.
- While portals are alive, `portal_pressure` event modifier is applied to SpawnDirector, scaling with number of portals remaining.
- Destroying a portal reduces pressure, shows updated HUD count.
- Destroying all portals clears pressure, emits `objective_completed`, and triggers the final boss encounter.
- EventDirector fires: swarm warning (t=1:00), elite (t=1:30), swarm surge (t=3:00), miniboss (t=6:00), final siege (t=7:30).
- Portals do not spawn enemies directly and do not create permanent arena hazards.

### EventDirector

`scenes/events/EventDirector.gd` — runtime-only staged event scheduler.

- Created dynamically by Arena if not found as a child node.
- Reads `run_time` from RunManager each frame.
- Fires scheduled events per profile: `balanced`, `ranged_support`, `swarm_exploder`.
- Unknown profiles fall back to `balanced`.
- Event types: `announce_only` (announcement only), `timed` (applies SpawnDirector modifier for duration), `spawn_elite`, `spawn_miniboss`.
- Final phase event (`start_final_phase_event()`) applies a heavy 60-second spawn pressure burst.
- Stops cleanly on `stop_for_final_boss_encounter()`.

### StageObjectiveManager

`scenes/objectives/StageObjectiveManager.gd` — runtime-only objective coordinator.

- Receives `arena`, `player`, `enemy_container`, `playable_rect`, and `stage_data` at setup.
- Spawns `DefenseObjective` (Neon Lab) or `PortalObjective` × N (Wasteland Gate).
- Emits `objective_completed`, `objective_failed`, `objective_state_changed`.
- Portal pressure: calls `spawn_director.apply_event_modifier("portal_pressure")` on setup and updates it as portals are destroyed.
- Cleared automatically on `cleanup()`.
- No saves, no meta persistence, resets on restart / victory / defeat / quit.

### Objective Structures

- `scenes/objectives/DefenseObjective.gd` — `Node2D` with Area2D contact detection (collision_mask = 2, enemies layer). Damage is rate-limited per frame. Visual: colored square with HP label.
- `scenes/objectives/PortalObjective.gd` — `StaticBody2D` added to `enemies` group (collision_layer = 2). Damaged by `take_damage()`. Visual: pulsing octagonal shape with HP label.

### Rules

- Boss Encounter 2.0 is **not** implemented in this patch.
- No arena hazards are added by any objective type.
- Enemy default target remains the player.
- Objective failure (defense destroyed) triggers game over through the existing run lifecycle.
- Objective completion (portals all destroyed) triggers the final boss flow through the existing run lifecycle.

## Boss Encounter 2.0

Extends the existing final boss flow with a full encounter state machine, three boss identities, phase 3 desperation, four new attack patterns, and polished telegraphs. No arena hazards are added.

### Encounter States

| State | Trigger | Description |
|-------|---------|-------------|
| `intro` | Boss spawns | 1.8 s intro delay before attacks begin |
| `phase_1` | Intro ends | Normal attack pool at full cooldowns |
| `phase_2` | HP ≤ 50 % | Enraged pool, 0.65× cooldown multiplier, "Final Boss Enraged!" announcement |
| `phase_3` | HP ≤ 25 % | Desperation pool, 0.5× cooldown multiplier, boss-specific announcement |
| `defeated` | Boss dies / `stop()` called | All attack loops halted, HUD cleared |

### Boss Identities

| Boss ID | Stage | Attack character | Phase 3 announcement |
|---------|-------|-----------------|---------------------|
| `titan_guardian` | City Rooftop | Melee nova + charge specialist | "Titan Guardian: Last Stand!" |
| `prism_overlord` | Neon Lab | Projectile-heavy, barrage-focused | "Prism Overlord: Desperate!" |
| `molten_colossus` | Wasteland Gate | Heavy nova + charge | "Molten Colossus: Molten Fury!" |

#### Attack Pools per Identity

| Boss ID | Phase 1 | Phase 2 | Phase 3 |
|---------|---------|---------|---------|
| titan_guardian | nova, charge, nova | pulse_nova, charge, barrage | pulse_nova, double_charge, pulse_nova |
| prism_overlord | barrage, aimed_barrage, barrage | aimed_barrage, barrage, ring_barrage | aimed_barrage, ring_barrage, aimed_barrage |
| molten_colossus | nova, charge, nova | pulse_nova, charge, nova | pulse_nova, double_charge, nova |
| default | nova, barrage, charge | — | — |

### Attack Patterns

#### Existing (v1)

- **nova** — circle AoE damage; circle telegraph.
- **barrage** — radial projectile spread; circle telegraph.
- **charge** — telegraphed straight-line speed burst; line telegraph.

#### New (2.0)

- **aimed_barrage** — Boss fires 3 waves of 5 (phase 1/2) or 7 (phase 3) projectiles aimed at the player's current position. Line telegraph shown before the first wave. Projectiles are capped at 20 total per attack.
- **ring_barrage** — Boss fires 10 projectiles evenly spaced around itself (radial gaps preserved). Circle telegraph shown first. Enemies approaching from any angle must dodge the ring.
- **double_charge** — Two sequential telegraphed charges: first at the player, then immediately a second at the new player position. Both use line telegraphs. Unavoidable damage is prevented by telegraph duration.
- **pulse_nova** — Two-stage AoE: small inner circle, then a larger outer ring. Both radii are telegraphed separately. Deals two damage checks in sequence; the inner radius uses `nova_radius`, the outer uses `nova_radius × 1.6`.

### Telegraphs

All attacks are telegraphed via `AttackTelegraph.tscn`:

- **Circle telegraph** — `play_circle(world_pos, radius, duration)` — used for nova, pulse_nova inner/outer, ring_barrage.
- **Line telegraph** — `play_line(from, to, width, duration)` — used for charge, double_charge, aimed_barrage first wave.

No attack deals unavoidable damage. Telegraph duration is always ≥ 0.55 s.

### HUD Changes

- **BossHealthBar** — phase label added below the HP bar:
  - Phase 1: "Phase 1" (white)
  - Phase 2: "Phase 2 — Enraged" (amber)
  - Phase 3: "Phase 3 — Desperation" (red)
- **GameHUD final boss label** — updates to `"Boss: <name>  [P1/P2/P3]"` with matching color on phase change.

### Boss Arena Safety

- `EnemySpawner` and `EventDirector` are stopped before the boss spawns (same as v1).
- All normal enemies are cleared on boss spawn (same as v1).
- `Arena` stores a `_boss_controller` reference; duplicate boss spawns are prevented by the existing `_boss_spawned` flag.

### Cleanup Paths

`_cleanup_boss_controller()` is called in `Arena` on:
- Restart run
- Quit to menu
- Confirm dialog (restart_run and quit_to_menu actions)

Cleanup calls `controller.stop()` (sets `_stopped = true`, `_encounter_state = "defeated"`) and nulls the reference.

### Debug

`DebugStatsOverlay` (F12) Boss section shows:

- `ID: <boss_id>  State: <encounter_state>`
- `Phase: <phase>  HP: <ratio %>`
- `Attack: <current_attack>  CD: <cooldown remaining>`
- `Attacking: <bool>  Arena: <bool>`

All fields are crash-safe: if the boss controller is freed mid-run the section shows `(no boss)`.

`EnemySpawner.debug_get_boss_state()` returns a dict with all boss fields enriched with `arena_active` and `boss_spawned` flags.

### Rules

- No arena hazards are added.
- Hero kits, evolutions, upgrades, stage objectives, saves, rewards, and meta progression are unchanged.
- Projectile count is capped per attack (aimed_barrage ≤ 20, ring_barrage = 10).
- Phase 3 is a continuation of the same encounter — it does not restart or re-spawn the boss.

## Equipment Item Template System

Item templates are now global and not hero-specific. Any hero can equip any item as long as the item's `slot_id` matches the target slot.

### EquipmentDataProvider

`scenes/equipment/EquipmentDataProvider.gd` — read-only global template catalog.

- Instantiated as a child of `MetaProgressionManager` at startup.
- Owns all canonical item template definitions.
- Exposes a query API; never reads or writes save data.

**Constants:**

| Constant | Value |
|----------|-------|
| `MAX_ITEM_LEVEL` | `10` (all items, globally) |
| `SLOT_IDS` | `core, suit, emblem, gauntlets, boots, artifact` |
| `RARITIES` | `common, uncommon, rare, epic, legendary, mythic` |

**API:**

- `get_all_item_templates() -> Array[Dictionary]`
- `get_item_template(template_id) -> Dictionary`
- `get_templates_for_slot(slot_id) -> Array[Dictionary]`
- `get_templates_by_rarity(rarity) -> Array[Dictionary]`
- `get_rarity_values() -> Array[String]`
- `get_slot_ids() -> Array[String]`
- `get_max_item_level() -> int`
- `is_valid_slot(slot_id) -> bool`
- `is_valid_rarity(rarity) -> bool`
- `is_valid_template_id(template_id) -> bool`
- `debug_get_item_template_summary() -> Dictionary`

### Canonical Template Schema

Each template has exactly these fields:

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique template identifier |
| `name` | String | Display name |
| `slot_id` | String | One of the six slot ids |
| `rarity` | String | Rarity tier |
| `stat_bonus_type` | String | Stat key applied to gameplay |
| `stat_bonus_per_level` | float | Bonus amount per level |
| `base_cost` | int | Upgrade cost at level 0 |
| `cost_growth` | float | Multiplicative cost growth |
| `tags` | Array | Descriptive category tags |

Fields **not** in the canonical schema: `hero_id`, `description`, `per-item max_level`, `tier`, `equipment_id`, `display_name`.

### Global Template Catalog (this patch)

| id | slot | rarity | stat |
|----|------|--------|------|
| `power_core_common` | core | common | attack_damage +1/lv |
| `cooldown_core_uncommon` | core | uncommon | ability_cooldown +0.008/lv |
| `reinforced_suit_common` | suit | common | max_health +5/lv |
| `vitality_suit_uncommon` | suit | uncommon | max_health +7/lv |
| `awareness_emblem_common` | emblem | common | xp_gain +0.01/lv |
| `battle_emblem_uncommon` | emblem | uncommon | attack_damage +1.5/lv |
| `striker_gauntlets_common` | gauntlets | common | attack_damage +1/lv |
| `force_gauntlets_uncommon` | gauntlets | uncommon | ability_damage +0.015/lv |
| `runner_boots_common` | boots | common | move_speed +3/lv |
| `momentum_boots_uncommon` | boots | uncommon | move_speed +4/lv |
| `shield_artifact_common` | artifact | common | shield_capacity +1/lv |
| `fury_artifact_uncommon` | artifact | uncommon | low_health_damage +0.02/lv |
| `apex_artifact_rare` | artifact | rare | ability_damage +0.025/lv |

### Equip Compatibility Rule

Equip compatibility is slot-only. A hero can equip any item whose `slot_id` matches the target slot. No hero restriction on templates.

### Max Item Level

All equipment items have a uniform max level of **10**, defined in `EquipmentDataProvider.MAX_ITEM_LEVEL`. Per-item max overrides do not exist.

### Supported Rarities

`common`, `uncommon`, `rare`, `epic`, `legendary`, `mythic`

Only `common`, `uncommon`, and `rare` are used in the initial catalog. `epic`, `legendary`, and `mythic` are reserved for future content.

### No Items Granted in This Patch

No items are added to any hero's inventory by this patch. Inventory and equipped slots remain empty unless the player already had valid saved item instances whose `template_id` exists in the new provider. Old hero-specific static items (Solar Core, Radiant Suit, etc.) are cleared by the existing `inventory_static_items_cleared` migration flag and not recreated.

### Not Added in This Patch

- Gacha / random loot
- Item drops from enemies
- Random affixes
- Crafting or fusion
- Auto-equip

These remain future work.

## Starter Equipment Grant Flow

When the player opens the Training screen for the first time (before claiming the starter pack), a popup titled **"Starter Equipment Pack"** appears automatically.

### Behavior

- Popup lists 6 common items — one per equipment slot.
- Player clicks **Accept** → items are added to the global inventory → popup closes.
- Popup never reappears once claimed (tracked via `equipment_grants["starter_pack_v1"]`).
- Items are **not** auto-equipped. The player must manually equip each item.

### Starter Pack Contents

| Template ID | Slot | Rarity |
|-------------|------|--------|
| `power_core_common` | core | common |
| `reinforced_suit_common` | suit | common |
| `awareness_emblem_common` | emblem | common |
| `striker_gauntlets_common` | gauntlets | common |
| `runner_boots_common` | boots | common |
| `shield_artifact_common` | artifact | common |

### Global (Shared) Equipment Model

All heroes share a single set of equipped items. Equipping an item in any hero view equips it globally — switching heroes does not change the equipped slots. Stat bonuses from globally equipped items apply to every hero equally.

### Not in the Grant Flow

- No gacha or random selection — all 6 items are always the same.
- No hero-restricted items — any hero can equip any item of the matching slot type.
- No auto-equip on grant.
- No inventory cap — all items received are always stored.

## Item Rewards After Run

At the end of every run the player receives item rewards that go directly into the global equipment inventory.

### Post-Run Flow

`Run → Result screen → Currency/Mastery/Goals → Item Rewards → Inventory`

Items appear in **Training → Equipment** after the run. They are not auto-equipped.

### Reward Count

| Outcome | Items |
|---------|-------|
| Defeat, run shorter than 5 min | 0 |
| Defeat, run 5 min or longer | 1 (common only) |
| Victory | 1 |
| Victory + final boss defeated | 2 |

### Rarity Rules

- **Defeat (long)**: common only.
- **Victory**: mostly common, some uncommon, small rare chance.
- **Victory + objective completed**: improved uncommon chance.
- **Victory + final boss defeated** (second item): notable rare chance.
- **Grade A or S**: small additional rare weight on top.
- Current drops use only `common`, `uncommon`, and `rare`. `epic`, `legendary`, `mythic` are reserved for future content.

### Display

- Victory screen: "Item Rewards" section above the buttons.
- Game Over screen: same section (shows "No items found." on short defeats).
- Run Rewards popup: "Item Rewards" section at the bottom of the scroll area.

### Rules

- Items go to global `inventory_items` with `source = "run_reward"`.
- Items are never auto-equipped.
- Duplicate template rewards are allowed (two of the same item possible).
- No gacha, no enemy item drops, no random affixes, no crafting, no fusion, no selling, no inventory cap.

## Equipment Set Data Foundation

Every item template now belongs to an optional named equipment set. Sets are data and display only — no bonus gameplay effects are applied in this patch.

### Equipment Sets

| Set ID | Display Name | Theme | Color |
|--------|-------------|-------|-------|
| `storm_set` | Storm Set | Speed / cooldown / ability flow | Blue |
| `titan_set` | Titan Set | Health / resist / heavy impact | Green |
| `solar_set` | Solar Set | Ability damage / shield / radiance | Gold |
| `tactical_set` | Tactical Set | Mark damage / support / precision | Purple |
| `fury_set` | Fury Set | Rage / low-health damage / impact | Orange |

### Template Set Assignments

| Template ID | Set |
|-------------|-----|
| `power_core_common` | fury_set |
| `cooldown_core_uncommon` | storm_set |
| `reinforced_suit_common` | titan_set |
| `vitality_suit_uncommon` | titan_set |
| `awareness_emblem_common` | storm_set |
| `battle_emblem_uncommon` | tactical_set |
| `striker_gauntlets_common` | fury_set |
| `force_gauntlets_uncommon` | solar_set |
| `runner_boots_common` | storm_set |
| `momentum_boots_uncommon` | storm_set |
| `shield_artifact_common` | solar_set |
| `fury_artifact_uncommon` | fury_set |
| `apex_artifact_rare` | solar_set |

### Template Schema Addition

`set_id: String` — added to every item template. Empty string means the item belongs to no set. All existing templates now carry a non-empty `set_id`.

`EquipmentDataProvider._adapt_template_to_definition()` uses `tmpl.duplicate(true)`, so `set_id` propagates automatically to all definition dicts. No item instances store `set_id` directly; they resolve it at runtime via `template_id → template → set_id`.

### EquipmentDataProvider Set API

New constant: `SET_IDS: Array[String]`

New methods:
- `get_all_equipment_sets() -> Array[Dictionary]`
- `get_equipment_set(set_id) -> Dictionary`
- `get_equipment_set_display_name(set_id) -> String`
- `get_equipment_set_color(set_id) -> Color`
- `is_valid_set_id(set_id) -> bool`
- `get_templates_for_set(set_id) -> Array[Dictionary]`

`debug_get_item_template_summary()` now includes a `by_set` breakdown.

### EquipmentFormat Set Helpers

Two new static methods added to `EquipmentFormat`:
- `set_display_name(set_id) -> String` — "Storm Set" … "No Set"
- `set_color(set_id) -> Color` — per-set theme Color

### MetaProgressionManager Set Helpers

New methods (delegate to `_equipment_provider` where needed):
- `get_equipment_sets() -> Array[Dictionary]`
- `get_equipment_set(set_id) -> Dictionary`
- `get_item_set_id(instance_id) -> String`
- `get_equipped_set_counts() -> Dictionary` — `{set_id: int}` for currently equipped items only
- `get_equipped_set_summary() -> Array[Dictionary]` — UI rows: `set_id, name, count, max_count (6), color, theme`

### UI: Set Name in Popups

- **Item action popup** (`_update_inventory_detail`) — shows "Set: <name>" after Rarity, plus "Set Progress: N / 6 equipped" when the item belongs to a set and `get_equipped_set_counts` is available.
- **Equipped slot popup** (`_update_slot_popup_content`) — shows "Set: <name>" after Rarity.

### UI: Set Summary Bar

A compact set summary `Label` (`_set_summary_label`) is shown in the Equipped Gear panel below the slot buttons. It is refreshed by `_refresh_set_summary()` whenever equipped items change. Format: `Sets:  Storm Set 2/6  |  Fury Set 1/6`. Shows "Sets: none" when nothing is equipped.

### UI: Cell Data

Inventory cell dicts now include `set_id` and `set_name` for downstream use (tooltips, future set filters).

### Rules

- No set bonus gameplay effects are applied in this patch.
- No reward or economy changes.
- No new items are added.
- No save format changes — `set_id` lives on templates only (no instance migration needed).
- Future work: set bonus activation at 2/4/6 equipped pieces.

## Yandex Games Notes

- Yandex SDK integration will be added later through a wrapper.
- Ads, payments, monetization, leaderboards, saves, and meta-progression are not implemented yet.
- Localhost SDK unavailability during development is acceptable.

## Equipment Rarity / Stat Presentation (EquipmentFormat)

`scenes/equipment/EquipmentFormat.gd` (`extends RefCounted`) is the single source of truth for all equipment display formatting. All methods are static.

- `rarity_display_name(rarity)` → "Common" … "Mythic"
- `rarity_short(rarity)` → "Cmn" / "Unc" / "Rar" / "Epc" / "Lgd" / "Mth"
- `rarity_color(rarity)` → Color per rarity tier (common=gray, uncommon=green, rare=blue, epic=purple, legendary=gold, mythic=pink)
- `rarity_order(rarity)` → int (mythic=5 … common=0)
- `slot_display_name(slot_id)` → "Core" / "Suit" / "Emblem" / "Gauntlets" / "Boots" / "Artifact"
- `stat_display_name(stat_bonus_type)` → human-readable stat name
- `stat_value_text(stat_bonus_type, value)` → "+5 Attack Damage" or "+10% Ability Damage" or "-15% Cooldown"
- `stat_total_text(stat_bonus_type, per_level, level)` and `stat_next_text(...)` → total / next-level previews
- `item_display_line(item_or_template)` → "Name  —  Slot  —  Rarity"

MetaUpgradeShop uses EquipmentFormat for: inventory cell rarity short names and rarity-colored tints, equipped slot button rarity tags, sort modes Rar High / Rar Low, Starter Pack popup item list. VictoryScreen and GameOverScreen item reward lines use `item_display_line`. `_format_stat_type_name` and `_format_slot_name` in MetaUpgradeShop delegate to EquipmentFormat.

## Inventory Management QoL (Lock / Favorite / Sell)

MetaProgressionManager constants:
- `INVENTORY_CAPACITY = 60` — soft display limit; never blocks grants.
- `_RARITY_SELL_BASE` — sell base by rarity: common=5, uncommon=10, rare=20, epic=40, legendary=80, mythic=160.

Item instance schema additions: `favorite: bool`, `created_index: int` (equals `instance_id_counter` at creation).

New MetaProgressionManager API:
- `get_inventory_item_count() -> int`, `get_inventory_capacity() -> int`
- `is_inventory_item_locked/toggle_inventory_item_locked/set_inventory_item_locked`
- `is_inventory_item_favorite/toggle_inventory_item_favorite/set_inventory_item_favorite`
- `get_inventory_item_sell_value(instance_id) -> int` — base + level × 2
- `get_inventory_item_sell_block_reason(instance_id) -> String` — "" if sellable; "locked" / "equipped" otherwise
- `can_sell_inventory_item(instance_id) -> bool`
- `sell_inventory_item(instance_id) -> Dictionary` — removes item, adds currency, emits `inventory_changed` + `currency_changed`, saves

New inventory sort modes: **Fav First** (favorites sorted to top) and **Newest** (higher `created_index` first).

Cell markers: `[E]` equipped, `[L]` locked, `[*]` favorite — shown in cell text. Cells tinted by rarity for unselected unequipped items.

## Inventory Actions Popup UI Rework

Main Inventory panel (right side of Equipment tab) is now clean: header row shows title + capacity label + hint text; body has filter row (Slot / State / Sort) and the inventory grid only. No action buttons or detail text in the main panel.

**Item action popup** (`PopupPanel`, assigned to `_item_action_popup`):
- Opens when clicking an occupied inventory cell; does not re-center if already visible.
- Closes when clicking an empty cell or pressing Close.
- Contains: item title label, scrollable detail text (slot, rarity, level, status, locked, favorite, gameplay note, stat, next-level stat, sell value, compare), action rows (Equip + Upgrade / Lock + Favorite + Sell + Close).
- Sell flow: Sell button → `ConfirmationDialog` → sell confirmed → popup hidden → signals refresh grid.
- Lock/Favorite buttons show toggle state: "Unlock"/"Lock", "[*]Off"/"[*]On".
- Sell button disabled with muted color when item is locked or equipped.

Capacity label shows `(X / 60)` and turns warning color when over capacity. The equipped slot popup (for clicking filled equipment slots on the left panel) remains a separate `PopupPanel` and is not mixed with the item action popup.
