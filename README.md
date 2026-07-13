# SuperHeroes

SuperHeroes is an original superhero-themed survivors-like made with Godot. A player chooses a hero and stage, survives escalating arena pressure, builds a run through upgrades and evolutions, completes the stage objective, and defeats a final boss. The project is configured for Web export and supports desktop and mobile landscape controls.

## Current status

**Implemented**

- Three playable hero kits: Solar Guardian, Night Tactician, and Fury Vanguard.
- Hero selection, stage selection with level preview/unlock gates, a read-only run briefing, pause/settings/help flow, and a Hero Collection screen.
- Arena combat: movement, dash, autoattacks, three active abilities, enemies, projectiles, XP, level-up choices, powerups, feedback, and mobile controls.
- Upgrade grid with attack/passive/active slots, hero-specific weapons and kits, shared passives, and 27 hero-specific triple evolutions.
- Time-based waves, role-based enemy variants, events, elites, minibosses, final bosses, stage objectives, victory/defeat, and post-run reward presentation.
- Persistent local meta progression: Training, equipment inventory, item upgrades, sets, Gold/materials, mastery, goals, stage progress, hero state, and preference/settings saves.

**Partially implemented**

- Stage levels expose recommended-power, enemy-strength, and loot-value previews, but those preview multipliers are not applied to combat or rewards.
- The Web preset exists; Yandex Games integration remains future work.

**Planned / not present in the checked-in project**

- Cloud/Yandex save, ads, payments, online services, controller remapping UI, localization, and production audio assets.

## Game loop

```text
Main Menu → Hero Select → Stage Select / level modal → Run Briefing → Arena
Arena: fight → collect XP/powerups → choose upgrades/evolutions → complete objective
      → final boss → Victory or Defeat → result screen → post-run rewards → restart or menu
```

Stage objectives are part of the live run:

- **City Rooftop**: survive until the final encounter.
- **Neon Lab**: protect the Lab Reactor; its destruction ends the run.
- **Wasteland Gate**: destroy all Dark Portals to trigger the final encounter.

Neon Lab unlocks after City Rooftop level 3; Wasteland Gate unlocks after Neon Lab level 3. A stage level is stored in the run summary and used by the UI preview only.

## Technology and configuration

| Area | Checked-in configuration |
| --- | --- |
| Engine | Godot 4.5 with GL Compatibility renderer |
| Language | GDScript |
| Entry scene | `res://scenes/main/Main.tscn` |
| Viewport | 1280×720; canvas-items stretch; expand aspect |
| Input | WASD/arrow movement, J/K/L abilities, Space dash, Escape pause, H/F11 help |
| Export | `Web` preset to `export/index.html` |

There are no Godot autoload entries in `project.godot`. Long-lived services are children of `Main` or instantiated by `Main`/`Arena`.

## Architecture

```text
Main
├─ persistent shell: settings, audio, preferences, hero/stage providers, selection UI
├─ runtime-created: MetaProgressionManager, rewards, Training shop, collection, briefing
└─ Arena (one active run)
   ├─ player, combat, spawn/run/upgrade/evolution managers
   ├─ stage objective, events, bosses, powerups, feedback and debug state
   └─ HUD, modal UI, mobile controls, result screens
```

### Main flow and persistent services

- [`scenes/main/Main.gd`](scenes/main/Main.gd) owns selection state and switches between menu/UI and a single `Arena` instance. It applies a completed run to meta progression and shows `PostRunRewardsScreen` before restart/menu.
- `SettingsManager` persists settings in `user://settings.cfg`; `AudioManager` applies them.
- `UserPreferencesManager` persists non-gameplay last hero/stage choices in `user://superheroes_user_preferences.json`.
- `MetaProgressionManager` owns gameplay progression in `user://superheroes_meta_progress.json` (`SAVE_VERSION = 7`). It owns currency, Gold/materials, Training, inventory/equipment, mastery, goals, and stage progress.
- Hero, stage, Training, and equipment providers own definitions only; they do not save player state.

### Arena and combat

- [`Arena.gd`](scenes/game/Arena.gd) composes and coordinates the active run. It applies hero data, then meta modifiers, then stage settings; it owns pause/modal safety and emits a run summary.
- `Player`, `PlayerAutoAttack`, and `AbilityManager` own movement/health, weapon behavior, and three active ability slots. `HeroApplier` and `MetaApplier` apply selected-hero and persisted bonuses at run start.
- `EnemySpawner` owns enemy instancing and drops. `SpawnDirector` owns difficulty phases, enemy variant selection, and wave packages. `Enemy` owns role behavior and damage state.
- `UpgradeManager` owns run-only upgrades and slot limits. `EvolutionManager` tracks hero-specific 3×3×3 triples and applies ready evolutions. `PassiveAbilityManager` owns run-only shared passive state.
- `RunManager` owns time, kills, boss state, and victory eligibility. `StageObjectiveManager` owns non-survival objective entities and state.
- `FeedbackManager`, HUDs, floating text, telegraphs, and result screens are display-only; they never apply damage or rewards.

### Content currently defined

| Type | Implemented content |
| --- | --- |
| Heroes | Solar Guardian (Solar Ray / Solar Energy), Night Tactician (Homing Rockets / Tactical Mark), Fury Vanguard (Fury Strikes / Rage) |
| Active abilities | Three per hero, routed through `AbilityManager` |
| Stages | City Rooftop, Neon Lab, Wasteland Gate |
| Enemy variants | Grunt, Runner, Charger, Tank, Shooter, Exploder, Swarm, Shielded, Support, Splitter, Disruptor |
| Evolutions | 27 triple definitions: 9 per hero |
| Final bosses | Stage-selected final boss identities, controlled by `FinalBossController` |

## Repository layout

| Path | Responsibility |
| --- | --- |
| `scenes/main/` | Entry scene and front-end/run coordinator |
| `scenes/game/` | Arena composition, run manager, tuning, active EventDirector scene |
| `scenes/player/`, `scenes/abilities/`, `scenes/projectiles/` | Player, weapons, active abilities, projectiles |
| `scenes/enemies/`, `scenes/events/`, `scenes/objectives/` | Enemy spawning/AI, alternate event scheduler, objectives and bosses |
| `scenes/upgrades/`, `scenes/evolution/`, `scenes/passives/`, `scenes/powerups/` | Run progression and temporary effects |
| `scenes/heroes/`, `scenes/stages/`, `scenes/training/`, `scenes/equipment/` | Static game data and application helpers |
| `scenes/meta/`, `scenes/preferences/`, `scenes/settings/`, `scenes/audio/` | Separate persistent services |
| `scenes/ui/`, `scenes/feedback/`, `scenes/effects/` | Presentation, menus, overlays, visual feedback |
| `scenes3d/` | Parallel 3D migration source: the migrated Vanguard/Knight run and reusable 3D components |
| `assets/kaykit/` | Reserved import locations for future KayKit adventurer, skeleton, animation, and forest assets |
| `docs/` | Focused project documentation and manual validation |
| `export/` | Web export output location (not a source-of-truth configuration) |

## Important interfaces and invariants

- `Main` supplies the selected hero/stage to `Arena.setup(...)`; `Arena` does not select or persist them itself.
- `Arena` applies hero data before `MetaApplier`. Persisted Training for one hero must not affect another hero.
- `MetaProgressionManager.apply_run_result(summary)` is the single progression entry point after a run. Arena and result UI do not write progression.
- UI emits intent only. `Main` owns menu transitions; `Arena` owns active-run transitions.
- `StageDataProvider` owns static stage data and previews; `StageSelect` is the only stage-selection screen.
- `SpawnDirector` owns long-term pressure and variant formulas; `EnemySpawner` owns positions, instancing, XP, and drops.
- `AbilityManager` owns cooldowns/ability mechanics; HUD and mobile controls must not mutate them directly.
- Final-boss damage must continue through `Player.take_damage()` or existing enemy-projectile collision handling.
- Run-only state (upgrades, evolutions, buffs, passives, debug state) is never written to persistent saves.

## Running and exporting

Open the project in Godot 4.5 and run the configured main scene, or from the repository root:

```sh
godot --editor project.godot
```

For a parse/editor smoke check:

```sh
godot --headless --editor --quit
```

### Isolated 3D migration prototype

`res://scenes3d/game/Arena3D.tscn` is an isolated 3D migration arena, not a replacement for `scenes/game/Arena.tscn` or the project entry scene. `Main` chooses it only when the selected legacy hero ID is `vanguard`; `guardian` and `blaster` continue to run through the existing 2D Arena. Main still owns selection, scene cleanup, rewards, restart, and return-to-menu flow.

The 3D foundation uses `Vector3.x` and `Vector3.z` as the horizontal plane; [`WorldPlane.gd`](scenes3d/utilities/WorldPlane.gd) converts this XZ convention to and from a 2D horizontal `Vector2`. World-unit movement uses 6 units/second in the 40×40 prototype arena, rather than the 2D pixel speed.

`Arena3D` owns its Player3D spawning, bounds/camera wiring, RunManager and SpawnDirector setup, EnemySpawner3D lifecycle, limited upgrades, and UI wiring. It emits `run_result_ready(summary)`, `restart_run_requested`, and `quit_to_menu_requested`; it does not apply rewards or persist progress. [`Player3D.gd`](scenes3d/player/Player3D.gd) remains a reusable `CharacterBody3D` controller for health, XP, input, mobile movement, dash, and facing; it can lock visual facing for an attack while movement continues. [`KnightVisual.tscn`](scenes3d/player/visuals/KnightVisual.tscn) owns the KayKit model, animation import, and sword/shield presentation.

KnightVisual attaches `sword_1handed.gltf` to `handslot.r` and `shield_round.gltf` to `handslot.l`. Its shared KayKit loader additionally imports `Rig_Medium_CombatMelee`; the Knight uses `Melee_1H_Attack_Slice_Diagonal`, with a single configured impact point. `KnightMeleeAutoAttack3D` finds the nearest living Enemy3D, locks the attack direction, applies damage once at that impact to targets in an XZ radius/arc, applies knockback, and releases facing when the animation ends. The model's +Z-facing visor is corrected inside KnightVisual's ModelOffset, so Player3D never contains KayKit paths, animation names, or bone names.

The isolated prototype now includes `Enemy3D` and `SkeletonWarriorVisual`. Enemy3D owns chase-only movement, health, knockback, contact timing, and the public enemy signals; SkeletonWarriorVisual owns the KayKit `Skeleton_Warrior.glb` model, animation, and `Skeleton_Blade.gltf` attachment. Both Knight and Skeleton visuals use the shared cached KayKit animation-library loader, so source clips are loaded once per matching source set rather than copied for every enemy. Skeleton contact damage is applied only from its one-shot `attack_impact` while Player3D remains in range.

`EnemySpawner3D` reuses the current `SpawnDirector` for spawn intervals, alive caps, variants, and wave packages, and receives the shared RunManager before it starts. Its explicit `start_spawning()`, `stop_spawning()`, and `is_spawning()` lifecycle stops all timers at terminal states. Each enemy death registers exactly one RunManager kill and creates an ExperiencePickup3D at its configured world height. `EnemyVariant3DAdapter` preserves the director dictionary values but converts legacy speeds with the explicit rule `40 2D pixels = 1 world unit` (120 pixels/sec becomes 3 world units/sec). Unsupported behavior IDs retain their source value for diagnostics but run as chase only.

The first Knight run is a 75-second survival prototype with no final boss. It reuses `GameHUD`, `LevelUpScreen`, `GameOverScreen`, `VictoryScreen`, `PauseMenu`, and `MobileControls`. `RunUpgradeManager3D` is run-local and includes sword, movement/health, Rage, and all three Knight ability lines. Its normal three-option selection prefers one `attack`, one `active`, and one `passive` option, then fills exhausted categories without duplicate or max-level choices.

Arena3D initializes world and gameplay state first, connects mandatory run/input signals, resets external movement, then configures optional reused UI before spawning begins. Keyboard `move_left/right/up/down` is read every Player3D physics frame and takes priority over the mobile external vector. Arena3D itself always processes the global Pause action so Escape and the MobileControls Pause signal can open or close PauseMenu while gameplay remains paused; its player, camera, manager, enemy, pickup, and effect containers are explicitly pausable, so Level Up and Pause Menu freeze the live 3D world. Opening, resuming, and ending a run reset mobile movement/joystick state.

Canvas layers keep HUD below mobile controls, then pause and level-up modals, with victory/defeat screens highest. Decorative full-screen controls ignore pointer input; hidden overlays must be closed or hidden before another screen becomes interactive. Main connects an arena's result/restart/menu signals before adding it to the tree, and unpauses/closes menu overlays before showing MainMenu.

Stage 1.6 adds the run-local `KnightAbilityManager3D`, independent of the legacy 2D AbilityManager. Rage starts at 0/100, gains from accepted damage plus successful melee/ability hits, decays while active, and continuously scales Knight damage from 1.0 to 1.45. Rage Wave is a 5-unit area slow shown by an expanding ground ring; Crushing Leap ends with a sharper impact ring. Shield Bash uses a ground sector whose full angle and exact visual range match its cone query. These effects use independent unshaded alpha `StandardMaterial3D` instances and tweened fades for GL Compatibility/Web. ActionController state is the authoritative Knight readiness source, so HUD and MobileControls show cooldown/blocked state and do not issue blocked ability intents; Arena3D explicitly republishes that state across Pause and Level Up transitions while the legacy 2D HUD remains compatible with states that omit a `slot` field. Debug snapshots cover the controller, Knight combat, and visual state; action tracing is debug-only and disabled for release/Web. Ability upgrades are active lines; Rage upgrades are passive.

Stage 1.7.1 adds a separate run-local `EvolutionManager3D` for the Knight. Worldbreaker requires Sword Arc + Burning Rage + Wide Wave; Rampage Impact requires Sword Knockback + Furious Edge + Heavy Bash; Meteor Crash requires Sword Damage + Smoldering Rage + Leap Force. Every evolution retains one `attack`, one `passive`, and one `active` prerequisite, and becomes ready only when all three lines reach their required level (the line maximum by default). After an upgrade, Arena3D can show the paused Evolution Reward screen before continuing Level Up or resuming. Selected evolution IDs/titles appear in the HUD and run summary.

Stage 1.7.2 implements Worldbreaker as the first 3D Knight evolution. It replaces the standard Rage Wave hit with three independent pulses from the cast origin: 0.0s / 1.0× radius / 1.5× base damage / 7.0 knockback; 0.22s / 1.45× / 1.25× / 8.5; and 0.44s / 1.9× / 1.0× / 10.0. Every pulse uses the existing Rage damage multiplier, applies or refreshes a 0.40 movement-speed slow for 2.5 seconds, and uses an expanding Web-compatible ground ring.

Stage 1.7.3 implements Rampage Impact with its unchanged prerequisites: Sword Knockback + Furious Edge + Heavy Bash. It replaces standard Shield Bash with a primary 1.75× damage, 1.35× range, 1.35× full angle (capped at 120°), and 1.80× knockback cone, applying a 0.35 movement-speed stagger for 1.2 seconds. A second snapshot cone follows after 0.28 seconds at 1.00× base damage, 0.85× primary range, the same angle, and 1.25× Bash knockback. Both evolved abilities use the shared deterministic, pausable Knight evolution-impact queue, retain Rage scaling and upgrades, and release their original action token before delayed impacts finish. Rampage uses distinct Web-compatible sectors; Worldbreaker values remain unchanged.

Stage 1.7.4 implements Meteor Crash with unchanged Sword Damage + Smoldering Rage + Leap Force prerequisites. At the actual scripted-motion landing position, it replaces standard Leap damage with a 2.00× damage, 1.50× radius, 12.0-force radial knockback for 0.30s, and a 1.25s stun. A crater aftershock remains at that landing point for 0.35s, then deals 1.00× base Leap damage in 0.80× primary radius with 8.0-force knockback for 0.24s and a 0.30 movement-speed slow for 1.8s. Both impacts use Rage scaling and the shared pausable deterministic queue, while the original Leap action/token lifecycle and cooldown finish normally. Meteor uses distinct Web-compatible crater rings. All three Knight evolutions are implemented; balance and polish remain for Stage 1.7.5.

Stage 1.7 is complete. Worldbreaker remains the widest area-coverage evolution: its 0.00s / 0.22s / 0.44s pulses keep 1.00x / 1.45x / 1.90x radii and 7.0 / 8.5 / 10.0 knockback, while using 1.25x / 0.85x / 0.50x damage and a 0.50 movement-speed slow for 2.0s. Rampage Impact remains the strongest directional control evolution with its unchanged primary 1.75x and secondary 1.00x damage, range/angle, knockback, stagger, and 0.28s follow-up. Meteor Crash remains the strongest landing burst and stun: 1.75x primary damage with a 1.10s stun, then a 0.35s aftershock for 0.85x damage and a 0.35 movement-speed slow for 1.6s. Evolved ability states immediately rename the HUD and MobileControls to Worldbreaker, Rampage Impact/Rampage, and Meteor Crash/Meteor. The HUD compacts multiple selections as `Evolved: First +N` with a full-title tooltip; the terminal summary reports the real active/attack/passive evolution categories and full title list. Evolution Reward options show the target, effect summary, and each prerequisite on a readable multiline panel. The Web-compatible presentation keeps Worldbreaker red-to-orange expanding rings, Rampage dense red-orange/short gold sectors, and Meteor thick red-orange primary plus thinner gold-orange aftershock. Stage 1.8 remains limited to Knight passive abilities and further synergies.

Stage 1.8.1 adds the separate run-local `PassiveAbilityManager3D`. Static Field, Battle Focus, and Magnet Core are direct legacy ports: their IDs, names, three levels, timing, damage, multipliers, and roles are unchanged. The sole spatial adaptation uses the established `40 legacy pixels = 1 world unit` rule for pulse, target, and pickup-attraction distances. Passive upgrades keep the existing attack/active/passive offer composition and finish started passive lines before introducing new passive lines. The HUD shows a compact passive summary and level tooltip; Arena3D summaries expose selected passive IDs, titles, count, and levels. Legacy Rage Field (`mighty_clap_rampage_impact`), Berserker Focus (`rage_leap_blood_crater`), and Gravity Rage (`rage_leap_final_impact`) triples are registered as unavailable placeholders with their exact legacy prerequisite IDs; their effects and missing prerequisite lines remain deferred. No new passives or evolutions are invented.

Stage 1.8.1.1 restores remaining legacy parity. Magnet Core adds its `45 / 85 / 125px` bonus to the legacy `140px` base magnet radius, giving effective radii `4.625 / 5.625 / 6.625` world units at levels 1–3, and attracts at the converted legacy speed of `10.5` world units/second. Existing Static Field and Battle Focus timers remain continuous through upgrades; only their first selection stays immediately ready. Battle Focus again shows a brief player-to-target orange-red arc. Pickup attraction avoids repeated assignments and clears invalid, deleted, or dead-player targets safely. A future, unimplemented direction is to standardize all skills at five levels and require level five for evolution prerequisites; current maximum levels and readiness rules remain authoritative.

Stage 1.8.2 ports Rage Field through `PassiveAbilityManager3D`. Fury Combo is the legacy three-level attack line (`splash_melee_combo`): each level adds `0.06` per stack, attacks use prior stacks, successful attacks add one stack up to five, and stacks clear after three seconds without a hit. Impact Wave is the legacy three-level Shield Bash line (`mighty_clap_shockwave`): each level adds `1.5` world knockback and reduces cooldown by `0.7s`, to a `3.0s` minimum. Rage Field keeps its exact prerequisites—Fury Combo, Battle Focus, Impact Wave—and replaces Static Field with radius `base * (1.35 + RageRatio * 0.55)`, damage `base * (2.5 + RageRatio * 4.0)`, and interval `max(base * (0.62 - RageRatio * 0.22), 0.85)`. It refreshes a `0.55` speed modifier for `0.75s`, does not generate Rage, and displays as Rage Field in the passive HUD. Evolution routing now sends passive targets through PassiveAbilityManager3D, and Arena3D reports actual active/attack/passive evolution counts. The future five-level migration remains unimplemented.

Stage 1.8.3 ports Berserker Focus. Blood Frenzy (`splash_melee_lifesteal`) is a three-level attack line adding `2 HP` per hit enemy per level and applies one combined post-swing heal. Recovery Field is a three-level passive at `4/6/8` healing, `12/10.5/9s` intervals, and `2.0/2.375/2.75` world-unit visual radii. Wide Landing (`rage_leap_radius`) is a three-level active line adding `0.55` Leap radius per level; it stacks with the existing line and therefore also expands Meteor Crash. Berserker Focus requires Blood Frenzy, Recovery Field, and Wide Landing; it uses Rage-scaled range, truncated damage, 1–4 deterministic targets, an enhanced refreshed speed buff, and its legacy interval/retry rules without generating Rage. Its HUD title replaces Battle Focus, and Evolution Reward shows passive targets and focuses the first visible option. Rage Field damage now uses legacy integer truncation. Gravity Rage and the planned five-level migration remain future work.

The named 3D physics layers are Player, Enemies, PlayerProjectiles, Pickups, EnemyProjectiles, Environment, and Obstacles. These are separate from and preserve the existing 2D physics layers.

The configured Web export preset writes to `export/index.html`. Use Godot's Export dialog or an equivalent CLI invocation with the checked-in `Web` preset; no custom export template or external build dependency is configured in the repository.

## Validation

The project has a manual validation checklist at [docs/validation/gameplay_validation.md](docs/validation/gameplay_validation.md). For gameplay, scene, or configuration changes, run the editor smoke check and the affected manual flow. For documentation-only changes, validate links, paths, and the final Git diff.

## Known issues, limitations, and technical debt

- **Technical debt — duplicate event schedulers:** `Arena.tscn` instantiates `scenes/game/EventDirector.tscn`, while `Arena._setup_event_director()` dynamically loads `scenes/events/EventDirector.gd` only when that node is missing. They contain different schedules. Keep the active scene contract in mind and consolidate only in an explicitly scoped code task.
- **Limitation — stage-level preview only:** level preview values are displayed and carried through summaries but do not currently scale enemy strength, rewards, or loot.
- **Limitation — local persistence only:** the checked-in saves are local `user://` files. No Yandex/cloud synchronization is implemented.
- **Limitation — Web production readiness:** a Web preset is configured, but repository content does not include a Yandex SDK wrapper, production audio library, localization, or browser-service integration.
- **Compatibility surface:** `MetaProgressionManager` retains legacy meta/equipment/sell wrappers alongside the current inventory and Dismantle flow. Treat those as compatibility APIs unless a scoped migration removes their callers.

## Change history (repository-confirmed)

Recent commits establish the current direction: zone-card stage selection and unlock progression; tabbed/infinite character Training with flat Defense; and equipment economy updates including Dismantle, Gold/materials, item power, set bonuses, and inventory UI improvements. Earlier implementation layers added hero kits, passives, evolutions, boss/objective encounters, run briefing, post-run progression, and selection preferences.

## Documentation maintenance

Keep this README, [Agents.md](Agents.md), and the relevant manual checks synchronized whenever behavior, save data, scene composition, external integration, or public system contracts change. Use the implementation as the source of truth; record discovered issues as issues/debt rather than silently describing them as fixed.
