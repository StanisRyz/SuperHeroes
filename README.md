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
