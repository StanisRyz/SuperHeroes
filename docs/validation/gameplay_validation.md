# Gameplay validation checklist

Use this checklist for manual validation after a relevant gameplay, UI, persistence, or scene-wiring change. It reflects the implemented systems in the current checkout; it is not a roadmap.

## Baseline

- Run `godot --headless --editor --quit` from the repository root after code, scene, or project-setting changes.
- Start from `scenes/main/Main.tscn`; confirm the project reaches Main Menu without parser errors or missing-node warnings.
- Confirm desktop layout at 16:9 and a wide landscape layout. Check that important UI remains reachable.
- For the isolated 3D migration prototype, open `scenes3d/game/Arena3D.tscn` and use Run Current Scene (F6). Confirm Player3D stays on the Environment ground and inside its XZ bounds; test keyboard movement, normalized diagonal speed, facing, dash direction/cooldown/invulnerability, and smooth fixed-angle CameraRig3D following. With `prototype_debug_enabled` enabled, use the existing `debug_add_xp` input action to exercise the public XP contract without a 2D HUD or DebugManager, then return to `Main.tscn`; the prototype must not replace or affect the 2D game.
- For documentation-only work, verify referenced paths/links and the final Git diff instead of running gameplay tests.

## Front-end and selection flow

- Main Menu exposes Start Run, Training, Collection, Settings, Help, and Quit intents.
- Start Run opens Character Select; Back returns to Main Menu.
- All three hero cards can be inspected and the selected hero continues to Stage Select.
- Stage Select shows City Rooftop, Neon Lab, and Wasteland Gate; locked stages display a reason and cannot be started.
- City Rooftop level selection opens in the Stage Select modal. Previous/next level updates recommended power, enemy strength, and loot previews.
- After clearing City Rooftop level 3, Neon Lab unlocks. After clearing Neon Lab level 3, Wasteland Gate unlocks.
- Run Briefing displays the selected hero, stage, level preview, stage objective, and boss preview. Back returns to Stage Select; Start Run opens Arena.
- Restart retains the selected hero, stage, and stage level. Returning to the menu resets the transient level selection.
- Last hero/stage choices are remembered independently of meta progression. Resetting preferences must not reset settings or progression.

## Core arena loop

- Player movement works with WASD and arrows; the player stays inside arena bounds and the camera follows.
- Space triggers dash. J/K/L activate the three current hero abilities and their cooldown feedback updates.
- Enemies spawn away from the player, chase/perform their defined role behavior, and respect the alive cap.
- The primary weapon attacks valid enemies in range. Verify each selected hero keeps its own weapon behavior.
- Enemy, player, projectile, and pickup collisions work: damage reduces health, dead enemies drop XP, and XP raises level.
- Level Up pauses the run, offers valid upgrades, applies the chosen upgrade once, and resumes safely.
- Powerup pickups delegate to `PowerupManager`; heal, shield, bomb, magnet burst, move speed, and attack speed effects show feedback and do not leave the run paused.
- HUD time, HP, XP/level, kill count, ability state, and objective state track live state without owning it.

## Heroes, upgrades, passives, and evolutions

- Solar Guardian uses Solar Ray/Solar Energy and Solar Beam, Frost Breath, Death Dash.
- Night Tactician uses Homing Rockets/Tactical Mark and Smoke Screen, Explosive Trap, Grappling Hook.
- Fury Vanguard uses Fury Strikes/Rage and Rage Wave, Mighty Clap, Rage Leap.
- Hero Training and equipment modifiers apply only after hero base data. Training from another hero must not affect the run.
- Upgrade slots respect Attack/Passive/Active limits; `BuildSlotsWindow` displays but does not change the build.
- Shared passives have visible/runtime effects and clean up with the run.
- A ready evolution requires its matching hero triple. Evolution/Overdrive choice is paused, applies once, and resumes without duplicate selections.
- Verify one evolution from each relevant target type after changes to upgrades/evolutions: attack, active, and passive.

## Spawning, events, and bosses

- Pressure, spawn interval, alive cap, variants, and wave packages progress through the run under `SpawnDirector`.
- Verify role-specific behavior relevant to the change: Charger, Shooter, Exploder, Swarm, Shielded, Support, Splitter, or Disruptor.
- Events announce correctly and their temporary spawn modifiers clear after their duration.
- Elite and miniboss spawns, health bars, attacks, defeat registration, and cleanup work.
- The final boss starts exactly once. During the encounter, normal spawns are suppressed, the boss arena boundary appears, boss health/phase UI updates, and cleanup restores the normal arena state.
- Final boss attacks damage through the standard player damage path; defeat triggers victory only once.

## Stage objectives and outcomes

- City Rooftop uses survival timing and starts the final encounter at the intended run state.
- Neon Lab spawns a Lab Reactor. Its HUD health updates; reactor destruction causes defeat; surviving long enough proceeds to the final encounter.
- Wasteland Gate spawns the configured Dark Portals. Projectiles/autoattacks can damage them; destroying every portal triggers the final encounter once.
- Objective state reaches `GameHUD` and `DebugStatsOverlay` without either UI changing objective gameplay.
- Player death shows Game Over with a coherent summary. Victory shows final stats and does not leave a boss boundary/controller behind.
- Post-run rewards appear before restart/menu. Applying results updates meta progression once, not when a result screen merely refreshes.

## Pause, settings, help, and modal safety

- Escape opens Pause Menu during an active run; Resume returns to the run.
- Restart and Quit from pause require the existing confirmation flow. Cancelling restores the prior paused state.
- Settings and Help can be opened from their supported menu/run contexts and close cleanly.
- A blocking modal (level-up, evolution, result, confirmation, build slots, settings, help) does not allow conflicting pause or gameplay transitions.
- Mobile ability, pause, and build buttons emit their intended actions without directly mutating gameplay.

## Meta progression and inventory

- Training purchases validate hero ownership/unlock and currency; values save and reload for that hero only.
- Equipment inventory remains global/shared. Equipping, unequipping, upgrading, lock/favorite toggles, filters, sorting, and loadout summary update the UI and save safely.
- Dismantle is available only for eligible unequipped/unlocked items, requires confirmation, and grants Gold plus the matching rarity material.
- Result rewards, mastery, goals, and stage progress are persisted through `MetaProgressionManager.apply_run_result` exactly once per run.
- Verify fresh/migrated save behavior when modifying save defaults, migrations, inventory, Training, goals, mastery, or stage progress. Preserve unknown legacy data safely.

## Debug and diagnostics

- Debug mode must be explicitly enabled before debug actions affect the run.
- Debug overlay/stat panel is read-only and displays live player, build, passive, spawn, objective, and boss state when available.
- Optional diagnostic logging remains disabled by default. Do not treat debug output as required normal gameplay output.

## Regression boundaries

- UI-only work must not alter gameplay balance, rewards, persistence, or progression formulas.
- Feedback work must not apply damage or own gameplay state.
- Stage preview work must not claim or imply runtime scaling until scaling is implemented.
- Changes to event scheduling must explicitly verify which implementation is active: `Arena.tscn` currently instantiates `scenes/game/EventDirector.tscn`; `scenes/events/EventDirector.gd` is only Arena's missing-node fallback.
# Knight Stage 1 release note

Follow [knight_stage_1_release_validation.md](knight_stage_1_release_validation.md) for the final Knight 3D progression, effect-lifecycle, pause, and Web checks.
