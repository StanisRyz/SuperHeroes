# Agent guide: SuperHeroes

## Scope and baseline

SuperHeroes is a Godot 4.5/GDScript survivors-like. The entry scene is `scenes/main/Main.tscn`; it targets desktop and mobile landscape Web builds. This document describes the checked-in architecture, not a feature wish list. Read the affected scene/script and [README.md](README.md) before changing code.

Run this after code, scene, or configuration edits:

```sh
godot --headless --editor --quit
```

Use [docs/validation/gameplay_validation.md](docs/validation/gameplay_validation.md) for the applicable manual flow. Update this file, the README, and that checklist when a public behavior or contract changes.

## Runtime topology

```text
Main.tscn / Main.gd
├─ scene children: settings, audio, user preferences, hero/stage providers, selection UI
├─ dynamically created: meta manager, rewards, briefing, Training shop, collection
└─ one Arena instance per run
   ├─ Player + autoattack + abilities
   ├─ spawner/director/run/upgrade/evolution/powerup managers
   ├─ objectives, events, miniboss/final-boss flow, feedback and debug state
   └─ HUD, pause/modals, mobile controls and result UI
```

- `Main` is the only front-end/run-flow coordinator. It owns selected hero/stage/level and applies the finished run through `MetaProgressionManager`.
- `Arena` coordinates a live run only. It accepts selected data through `setup()`, emits a run summary, and does not write persistent progress.
- Providers own definitions. Managers own mutable runtime state or save state. UI displays state and emits intent; it must not own combat, rewards, saves, or scene replacement.

There are no autoloads in `project.godot`.

## Parallel 3D migration foundation

`scenes3d/` is a parallel source tree for the staged 2D-to-3D migration. `scenes3d/game/Arena3D.tscn` does not replace `scenes/game/Arena.tscn` or `run/main_scene`: `Main` selects it only for legacy hero ID `vanguard`, while `guardian` and `blaster` stay on the 2D Arena. Keep those 2D paths playable throughout early migration stages. Arena3D accepts the standard `setup(settings, audio, hero, meta, stage)` contract and emits `run_result_ready(summary)`, `restart_run_requested`, and `quit_to_menu_requested`; Main remains the sole owner of rewards, restart cleanup, and menu transitions.

The 3D horizontal-plane convention is XZ: `Vector3.x` and `Vector3.z` map to the game-facing `Vector2.x` and `Vector2.y`. Use `scenes3d/utilities/WorldPlane.gd` for typed conversions rather than duplicating coordinate mapping. `Player3D` is a `CharacterBody3D` with the existing player-facing health, XP, dash, input, and external-movement contracts; use 3D world units (currently 6 units/second in the 40×40 prototype), not 2D pixel tuning. It owns its movement, facing, gravity, and bounds enforcement, not combat managers.

`Arena3D` owns the 3D player spawn, assigns bounds, and connects the target to `CameraRig3D`. `CameraRig3D` has a fixed angled world view and smoothly follows position only; never parent or rotate it with Player3D. Player3D owns only physics and gameplay-facing contracts. `KnightVisual` owns the imported KayKit Knight, its ModelOffset/forward correction, animation player/skeleton discovery, locomotion/one-shots, and `handslot.r` sword plus `handslot.l` shield attachments. Do not place health, XP, input, damage, hit detection, or arena logic in visual scripts.

KnightVisual maps Idle_A and Running_A as looping locomotion clips and Hit_A/Death_A as one-shots. It loads `Rig_Medium_CombatMelee` through `KayKitAnimatedVisual.additional_animation_sources` and maps `Melee_1H_Attack_Slice_Diagonal` for the Knight attack. `KnightMeleeAutoAttack3D` owns nearest-target selection, attack cooldown, XZ radius/arc dot-product hits, single impact damage, and knockback. It locks Player3D's visual-facing direction for the attack and releases it after the animation while movement continues. Do not put attack targeting or damage in the visual script.

`KayKitAnimatedVisual` owns shared imported-animation discovery, skeleton discovery, loop setup, and cached animation libraries. Concrete visual scenes own only their model, ModelOffset, animation mapping, and equipment. `SkeletonWarriorVisual` uses `Skeleton_Warrior.glb` on `Rig_Medium`, maps Idle_A/Running_A/Use_Item/Hit_A/Death_A, corrects its +Z-facing visual in ModelOffset, and attaches `Skeleton_Blade.gltf` to `handslot.r`. Animation tracks remain under visual descendants and must never move the owning CharacterBody3D.

`Enemy3D` owns health, chase-only XZ motion, gravity, visual facing, contact attack cooldown, knockback, and death lifecycle. It is on Enemies, collides physically with Environment/Obstacles only, exposes a future Enemies Hurtbox, and stops contact/movement at death. Its contact attack starts the visual one-shot and damages Player3D only at that visual's single `attack_impact` while the target remains in range. Do not add navigation, special behavior IDs, elite/miniboss/boss systems, or attack hit detection in this migration stage.

`Arena3D` configures the existing RunManager before `SpawnDirector.setup(run_manager)` and passes that same manager to EnemySpawner3D before `start_spawning()`. EnemySpawner3D owns safe instancing, ring-position selection, alive counting, target assignment, death wiring, XP pickup creation, and explicit start/stop spawning timers. It registers one RunManager kill per Enemy3D death; terminal death/victory stops spawning. It must query the existing SpawnDirector for interval, caps, variants, and wave packages; never copy its policy. ExperiencePickup3D preserves its configured global hover height. `EnemyVariant3DAdapter` converts director speeds with `40 pixels = 1 world unit` and deliberately forces unsupported behavior IDs to chase while preserving their source id.

The 3D run is a 300-second no-boss survival slice. Arena3D owns its wired `GameHUD`, `LevelUpScreen`, `EvolutionRewardScreen`, `GameOverScreen`, `VictoryScreen`, `PauseMenu`, and `MobileControls`; these remain display/input intent surfaces. `RunUpgradeManager3D` is run-local and covers sword, movement/health, Rage, and all Knight ability lines. Normal three-option selection prefers one `attack`, one `active`, and one `passive` option, then fills from remaining categories without duplicates or max-level entries. Do not port the 2D upgrade grid, bosses, or other hero paths until explicitly scoped.

Arena3D startup order is world, gameplay, critical run/input signal wiring, input reset, optional UI configuration, then spawning. Optional UI setup must be guarded with node/method/signal checks and must never prevent player movement, dash, pause, or run lifecycle signals. Player3D reads keyboard movement each physics frame; keyboard has priority, and the external MobileControls vector is only the fallback. Reset external/mobile movement when the arena starts, pauses, resumes, and ends.

Arena3D uses always-processing only for global Pause input. Its PlayerContainer, CameraRig3D, Managers, EnemyContainer, PickupContainer, and EffectContainer must be explicitly `PROCESS_MODE_PAUSABLE`, because inherited processing from the always-processing arena would otherwise keep the 3D run live during a modal. Escape and the mobile Pause button use the same toggle, reset the joystick/mobile vector, and open PauseMenu above normal run UI. Canvas layer order is HUD, mobile controls, pause, level-up, then terminal screens. Decorative full-screen controls must use `MOUSE_FILTER_IGNORE`; hidden overlays must not intercept input. Main must unpause and close hidden menu overlays before showing MainMenu, and connect a newly instantiated arena's result/restart/menu signals before adding it to the tree.

Stage 1.6 uses `KnightAbilityManager3D`, not the 2D AbilityManager, for Rage and active ability cooldowns. It owns Rage signals, ActionController-based readiness/blocked reasons, Rage Wave area slow, Shield Bash cone/knockback, and Crushing Leap landing logic. Rage Wave and Leap use expanding XZ ground rings; Bash uses an XZ sector built from its full cone angle and exact gameplay range. Each effect has an independent unshaded alpha `StandardMaterial3D` and Web-compatible fade. Player3D scripted motion must move through CharacterBody3D physics, honor bounds/collision, and cancel at terminal state. Enemy3D temporary modifiers refresh by ID and recalculate effective speed/contact damage without mutating base variant values. Arena3D republishes Knight ability state immediately after Level Up/Pause pause-state transitions, while the generic HUD and MobileControls preserve legacy 2D support for ability states that do not include a slot field; MobileControls only emits ready intents. ActionController, ability, autoattack, and visual debug snapshots are read-only; the action tracer is disabled in release/Web before opening files or processing input. Ability lines are active upgrades, Rage lines are passive.

Stage 1.7.1 adds a separate, run-local `EvolutionManager3D`, never the legacy 2D EvolutionManager. Worldbreaker uses Sword Arc (attack), Burning Rage (passive), and Wide Wave (active); Rampage Impact uses Sword Knockback, Furious Edge, and Heavy Bash; Meteor Crash uses Sword Damage, Smoldering Rage, and Leap Force. Each evolution is locked/partial/ready/selected from exactly those three line levels, using each line's maximum as the default required level. Arena3D checks after every accepted Level Up, keeps the world paused for `EvolutionRewardScreen`, and then continues the next Level Up or resumes. The HUD and run summary expose only selected run-local evolution IDs/titles.

Stage 1.7.2 marks Worldbreaker as implemented and reward-offerable. `KnightAbilityManager3D.apply_evolution()` activates supported evolutions run-locally and rejects placeholder IDs. Worldbreaker replaces Rage Wave's standard impact with three independent pulses at the original cast origin: 0.0s (1.0× radius, 1.5× base damage, 7.0 knockback), 0.22s (1.45×, 1.25×, 8.5), and 0.44s (1.9×, 1.0×, 10.0). Pulses reuse Rage scaling and upgrades, refresh a 0.40 speed slow for 2.5 seconds, and render `WorldbreakerPulseEffect3D`.

Stage 1.7.3 marks Rampage Impact as implemented and reward-offerable with Sword Knockback, Furious Edge, and Heavy Bash prerequisites unchanged. It replaces standard Shield Bash with a primary cone of 1.75× Bash damage, 1.35× range, 1.35× full angle capped at 120°, 1.80× knockback, and a 0.35 speed stagger for 1.2s. Its stored-origin/direction second cone follows at 0.28s with 1.00× Bash damage, 0.85× primary range, the same full angle, and 1.25× Bash knockback. `RampageImpactEffect3D` is presentation-only and uses exact gameplay range/angle. Worldbreaker values remain unchanged.

Stage 1.7.4 marks Meteor Crash as implemented and reward-offerable with Sword Damage, Smoldering Rage, and Leap Force prerequisites unchanged. It branches only at the actual end of Player3D scripted Leap movement: primary impact is 2.00× Leap damage, 1.50× radius, 12.0 radial knockback for 0.30s, and a stable 1.25s stun. Its landing-position aftershock queues for 0.35s at 1.00× Leap damage, 0.80× primary radius, 8.0 knockback for 0.24s, and a 0.30 speed slow for 1.8s. `KnightAbilityManager3D` uses one deterministic, pausable evolution-impact queue for Worldbreaker, Rampage, and Meteor events; it resolves by sequence, clears on stop/scene cleanup, and never retains action tokens. `MeteorCrashImpactEffect3D` is presentation-only. All three Knight evolutions now preserve normal Rage scaling, cooldowns, and ability lifecycle; balance and polish remain scoped to Stage 1.7.5.

Stage 1.7 is complete. Preserve the exact three-line prerequisite combinations and existing readiness levels: Worldbreaker is Sword Arc/Burning Rage/Wide Wave, Rampage Impact is Sword Knockback/Furious Edge/Heavy Bash, and Meteor Crash is Sword Damage/Smoldering Rage/Leap Force. Worldbreaker is the widest area evolution at 1.25x/0.85x/0.50x pulse damage, existing 1.00x/1.45x/1.90x radii and 7.0/8.5/10.0 knockback, plus a 0.50 speed slow for 2.0s. Rampage remains unchanged and is the strongest directional knockback/stagger evolution. Meteor is the strongest landing burst/stun evolution at 1.75x primary damage, 1.10s stun, and 0.85x aftershock damage with a 0.35 speed slow for 1.6s; its existing radius, knockback, delay, scripted movement, and cooldown remain intact. Evolved ability-state publishing immediately updates GameHUD and MobileControls to Worldbreaker, Rampage Impact/Rampage, and Meteor Crash/Meteor. Multiple HUD choices are compact (`Evolved: First +N`) with a full-title tooltip. Arena3D summaries include total plus active/attack/passive evolution counts, and terminal screens show only present categories with the full title list. The paused Evolution Reward panel has readable multiline target, effect summary, and all prerequisites. Effects are presentation-only and retain their mechanical extent. Stage 1.8 is future work for Knight passives and further synergies only.

Stage 1.8.1 adds `PassiveAbilityManager3D`, a separate run-local manager under Arena3D's pausable Managers node. It ports only legacy Static Field, Battle Focus, and Magnet Core with unchanged IDs, names, levels, timings, damage, multipliers, and roles; convert their spatial legacy values with `40 pixels = 1 world unit` only. Static Field resolves fixed-damage radius pulses through CombatQuery3D. Battle Focus preserves its nearest-target strike then timed attack-speed buff through AutoAttack's composable temporary modifier API. Magnet Core scans pickups at a bounded interval and uses ExperiencePickup3D's own XZ attraction contract without taking over collection. Passive options preserve attack/active/passive composition and prefer unfinished started passive lines. HUD and summaries read passive state through the manager. Register Rage Field (`mighty_clap_rampage_impact`), Berserker Focus (`rage_leap_blood_crater`), and Gravity Rage (`rage_leap_final_impact`) only as legacy-prerequisite placeholders; never offer, select, or implement their effects until a later scoped patch. Do not invent passive/evolution IDs or alter Stage 1.7 systems.

Stage 1.8.1.1 restores passive parity details. Magnet Core's effective attraction radius is `(140px base + 45/85/125px bonus) / 40`, exactly `4.625 / 5.625 / 6.625` world units, and its converted legacy attraction speed is exactly `10.5` world units/second. Its state exposes the base, bonus, effective radius, and speed. A first Static Field or Battle Focus selection remains immediately ready; later upgrades keep the already remaining timer and apply new tuning only at the next trigger. Battle Focus adds a presentation-only orange-red player-to-target arc before applying its existing timed speed modifier. ExperiencePickup3D rejects duplicate attraction assignments and clears invalid/dead/queued targets without collecting itself. Future design work may standardize skills to five levels and evolution prerequisites to level five, but no current maximum level or readiness rule changes until an explicit future patch.

Stage 1.8.2 implements Rage Field through `PassiveAbilityManager3D`. Its exact legacy prerequisites are Fury Combo (`splash_melee_combo`, attack), Battle Focus (passive), and Impact Wave (`mighty_clap_shockwave`, active), all at their existing maximum level three. Fury Combo adds `0.06` per upgrade to each of five stacks, applies the pre-hit multiplier after Rage scaling, adds one stack per successful attack, and clears after three seconds without a hit. Impact Wave applies `+1.5` Shield Bash knockback and `-0.7s` cooldown per level, clamped at 3.0s; Rampage inherits the updated base knockback. EvolutionManager3D routes active targets to KnightAbilityManager3D and passive targets to PassiveAbilityManager3D. Rage Field uses `base radius * (1.35 + rage_ratio * 0.55)`, `base damage * (2.5 + rage_ratio * 4.0)`, and `max(base interval * (0.62 - rage_ratio * 0.22), 0.85)`, applies a 0.55 speed modifier for 0.75s, does not generate Rage, and renames the static-field HUD entry to Rage Field. Arena3D derives category counts from selected evolution targets. No current maximum level or readiness rule changes.

Stage 1.8.3 implements Berserker Focus only. Blood Frenzy (`splash_melee_lifesteal`) has three levels and adds 2 HP per damaged enemy at each level, applying one clamped heal after a complete successful swing without modifying damage or Rage. Recovery Field is a three-level passive: 4/6/8 requested healing, 12.0/10.5/9.0 intervals, and 2.0/2.375/2.75 world visual radii; it pulses even at full health and reports requested versus actual healing. Wide Landing (`rage_leap_radius`) has three levels and adds 0.55 world Leap radius per level, stacking with the existing leap-radius line and thereby affecting Meteor Crash. Berserker Focus (`rage_leap_blood_crater`) requires Blood Frenzy, Recovery Field, and Wide Landing at their existing maximum level three. It uses range `base*(1.3+rage*.35)`, truncated damage `int(base*(2.8+rage*2))`, 1–4 deterministic targets, speed `base+.55+rage*.45`, duration `base*(1.7+rage)`, interval `max(base*.62,.85)`, and a 0.28s no-target retry; it does not generate Rage. The passive HUD renames Battle Focus after selection. Evolution Reward displays passive targets and focuses its first visible option. Rage Field now preserves legacy integer truncation.

Stage 1.8.4 implements Gravity Rage, preserving its exact legacy triple: Finishing Blow (`splash_melee_execute`, attack), Guardian Drone (`guardian_drone`, passive), and Leap Ready (`rage_leap_cooldown`, active), each at the current authoritative maximum level three. Finishing Blow raises the low-health threshold by `0.20` to `0.20 / 0.40 / 0.60`; each melee target checks pre-hit health and receives `1.45x` of its normal Rage-and-Fury-scaled damage when eligible, without changing hit count, Blood Frenzy, or Rage. Guardian Drone uses fixed `5 / 8 / 11` damage, `3.4 / 3.0 / 2.6s` intervals, and `11.5` world-unit nearest-target range. PassiveAbilityManager3D owns one gold low-poly orbit visual at `1.45` units and owns its timer, target query, arc, cleanup, and retry. Leap Ready reduces Crushing Leap cooldown by `1.2s` and increases travel by `0.5` world units per level, clamping cooldown at `3.5s`; all standard and evolved Leap paths use those shared values. Gravity Rage changes the Magnet Core HUD title but not its ID or level. It multiplies only its level bonus by `2.6`, keeping the `140px` base unchanged, for pickup radii `6.425 / 9.025 / 11.625`; its `3.2s` purple-gold pulse uses radii `8.425 / 11.025 / 13.625`, force `3.0` for `0.22s`, and a `0.55` speed multiplier for `0.8s`, with no damage or Rage. Evolution Reward clears all old focus, then defers focus to a visible option or Continue. Preserve current maximum levels and readiness rules; the five-level migration remains future work.

Stage 1.8.5 ports Orbit Shields (`orbit_shields`) only; Solar Aegis and all other shield evolutions remain unimplemented. Orbit Shields remains three levels with maximum charges `1 / 1 / 2` and sequential pausable regeneration intervals `18 / 14 / 12s`. Player3D owns the run-local shield API (`configure_shield_charges`, add/consume/get/clear) and `shield_changed(current, maximum)` / `shield_blocked(blocked_damage, remaining, maximum)` signals. An eligible incoming hit consumes exactly one charge and ends before health loss, `damage_taken`, Rage, Knight hit animation, or death logic. Initial selection immediately fills `1 / 1`; the level-three capacity upgrade fills missing capacity to `2 / 2`; upgrades never reduce charges. PassiveAbilityManager3D owns the timer, shield visual, block feedback, cleanup, and read-only state. OrbitShieldVisual3D uses cyan low-poly markers at the converted `42px / 40 = 1.05` orbit radius and `8px / 40 = 0.20` marker scale, follows Player3D, and mirrors the charge signal without owning gameplay. GameHUD keeps its 2D buff-manager support and additionally displays `Shield: None` or `Shield: current / maximum` for Player3D, with regeneration detail; Arena3D records shield charges, maximum charges, and blocks before teardown. Guardian Drone calculates its first orbit position during setup. Current maximum levels remain authoritative; the five-level plan remains future work.

Stage 1.8.6 ports Storm Relay (`storm_relay`) and Chain Lightning (`chain_lightning`) only. Storm Relay has fixed `8 / 12 / 16` damage, `5.5 / 4.8 / 4.2s` intervals, and a converted `520px / 40 = 13.0` world-unit nearest-target range; it retries in `0.35s` with no target. Chain Lightning has fixed `6 / 9 / 12` damage per target, `6.6 / 5.8 / 5.0s` intervals, `500px / 40 = 12.5` initial range, `210 / 240 / 270px = 5.25 / 6.0 / 6.75` bounce ranges, and total target limits `2 / 3 / 4` that include the first target. Every bounce begins from the saved prior-target position and excludes already hit instance IDs, even if a hit target dies. Both lines reuse PassiveAbilityManager3D's pause-safe timers and PassiveArcEffect3D, never use Rage scaling or Rage generation, and have no modifiers or projectiles. Orbit Shields adds a manager-owned 0.25s passive-state refresh only while a timed charge is missing, so its existing HUD tooltip decreases without changing regeneration. Solar Storm, Shock Net, and Time Dilator remain outside the 3D port; preserve the current maximum levels, future five-level migration note, and 300-second run duration.

Stage 1.8.7 completes the nine base legacy passive ports with Time Dilator (`time_dilator`); Stasis Field and Crushing Storm remain unimplemented. Its level values are intervals `8.5 / 7.5 / 6.5s`, radii `190 / 220 / 250px = 4.75 / 5.5 / 6.25` world units, movement-speed multipliers `0.72 / 0.64 / 0.56`, and durations `2.5 / 3.0 / 3.5s`. On each shared pause-safe timer expiry, it finds living enemies in the current radius and applies or refreshes the stable `time_dilator` Enemy3D modifier using `movement_speed_multiplier`; it emits its pale blue-violet pulse, interval, and trigger state even when zero targets exist. Base Time Dilator has no damage, Rage scaling/generation, knockback, stun, player movement, cooldown, or attack-speed effects. HUD and terminal summaries remain generic through passive state and selected-passive contracts. Preserve current maximum levels, the future five-level migration note, and the 300-second run duration.

Stage 1.8.8 adds generic EvolutionManager3D routing by target type: active routes to KnightAbilityManager3D, passive to PassiveAbilityManager3D, and attack to KnightMeleeAutoAttack3D. Earthsplitter is the implemented attack target: `rage_wave_earthsplitter` / `vanguard_earthsplitter`, targeting `splash_melee`, requires Wide Fury (`splash_melee_radius`), Static Field, and Wave Reach (`rage_wave_radius`) at their current maximum levels. Wide Fury is four levels of `+14px = +0.35` world melee radius. Wave Reach is three levels of `+30px = +0.75` Rage Wave radius plus `+0.04` Rage-radius scaling; the effective radius is `base * (1 + (0.18 + bonus) * RageRatio)` for normal Rage Wave and Worldbreaker. A successful normal melee impact triggers one presentation-only Web-compatible ground crack along its stored direction at `260px = 6.5` range and `82 * 0.65px = 1.3325` width, dealing `0.75x` base swing damage independently of target Finishing Blow. It has no knockback, slow, stun, Blood Frenzy, Fury Combo, extra Rage, or recursive impact. Attack-evolution state resets with the run, renaming Fury Strike to Earthsplitter only while selected; Arena3D summary records its IDs, name, and attack evolution count. Crushing Storm remains the next planned attack-target evolution.

Stage 1.8.9 implements Crushing Storm through the existing attack-target route: `rage_wave_crushing_storm` / `vanguard_crushing_storm`, targeting `splash_melee`, requires Berserker Frenzy (`splash_melee_frenzy`), Time Dilator, and Crushing Current (`rage_wave_deep_slow`) at current maximum levels. Berserker Frenzy has three `+0.10` maximum Rage multiplier levels capped at `1.95` without lowering a stronger existing value. Crushing Current has three levels of `+0.8s` Rage Wave slow duration, `-0.06` slow multiplier with a `0.20` minimum, `-0.5s` cooldown with a `2.5s` minimum, and `+0.04` Rage radius scaling; normal Rage Wave uses these slow values while Worldbreaker keeps its own slow tuning and the shared effective radius/cooldown. Crushing Storm adds `RageRatio * 1.35` to normal Fury Strike Rage multiplier. Its one post-impact pressure storm uses `meleeRadius * lerp(1.55, 2.45, RageRatio)`, `baseSwing * lerp(0.55, 1.15, RageRatio)` rounded to at least one, `lerp(0.62, 0.28, RageRatio)` movement speed for `1.25 + RageRatio`, and stable `crushing_storm_pressure`; it stacks separately with Time Dilator. The red-orange 0.24s ground ring is presentation-only. Earthsplitter and Crushing Storm coexist, each fires once per successful normal impact, and the newest selected attack evolution names the primary attack in summary. Seismic Fan is next.

Stage 1.8.10 completes Fury Vanguard's 3D attack-target evolution set. Seismic Fan (`mighty_clap_seismic_fan` / `vanguard_seismic_fan`) requires Ground Shockwave (`splash_melee_shockwave`, max 1), Chain Lightning, and Wide Clap (`mighty_clap_range`, max 3), then fires alongside Earthsplitter and Crushing Storm after every successful normal Fury Strike. Ground Shockwave queues a pause-safe 0.18s impact at the original position with radius `current melee radius * 1.5` and damage `round(base attack_damage * 0.5)`, minimum 1; it has no Rage or melee side effects. Wide Clap adds `+25px / 40 = +0.625` world Bash range and `+6°` Bash angle each level, affecting both Shield Bash and Rampage Impact. Seismic Fan uses the stored swing direction, range `current melee radius + 175px / 40 = +4.375` world units, a 68° full cone, and `round(base swing damage * 0.85)`, minimum 1; its three Web-compatible orange ground strips match the gameplay range. All three attack evolutions can remain selected simultaneously, while the newest still supplies the primary attack name. The next patch is the evolution-grid and progression parity audit.

Stage 1.9.1 replaces the mixed Knight run-upgrade catalog with the canonical 27-line progression grid: 9 attack, 9 passive, and 9 active. Every definition declares its category, unique per-category grid index, evolution ID, evolution role, owner, and handler; all non-canonical run-upgrades are absent from offers, application, history, summaries, and evolution prerequisites. The nine exact triples are Worldbreaker (Fury Strike Power / Orbit Shields / Wave Surge), Earthsplitter (Wide Fury / Static Field / Wave Reach), Crushing Storm (Berserker Frenzy / Time Dilator / Crushing Current), Rampage Impact (Knockback Force / Storm Relay / Clap Force), Seismic Fan (Ground Shockwave / Chain Lightning / Wide Clap), Rage Field (Fury Combo / Battle Focus / Impact Wave), Meteor Crash (Fury Tempo / Magnet Core / Leap Impact), Berserker Focus (Blood Frenzy / Recovery Field / Wide Landing), and Gravity Rage (Finishing Blow / Guardian Drone / Leap Ready). All nine passives participate exactly once. `EvolutionManager3D.get_progression_matrix_validation_errors()` is read-only and reports all catalog/matrix violations rather than stopping at the first. Stage 1.9.2 is reserved for five-level standardization.

Stage 1.9.2 standardizes all 27 canonical Knight upgrades to five levels with explicit `required_level = 5` UI data. Upgrade application derives each attack/active application from the next cumulative tuning target and applies only its delta; all passive definitions now have five values per level-scaled parameter. Ground Shockwave upgrades from 0.30x damage / 1.25x radius / 0.26s delay to 0.50x / 1.50x / 0.18s, capturing resolved values in its pause-safe queue. Orbit Shields refills when capacity rises, rather than at a hardcoded level. Arena3D consumes pending level-ups only after a successful application. The validator checks five-level tuning, passive tables, initialized owner handlers, and unchanged unique evolution usage. Stage 1.9.3 is the full evolution-path UI patch.

Stage 1.9.3 adds read-only evolution-path state and a run-local deterministic focus: highest path progress, then completed lines, started lines, and first selection order. Selected paths leave the focus pool; ready paths remain focused until chosen. Arena3D enriches offers with focused/secondary/new-path context and synergy metadata, refreshes the existing HUD evolution area, validates after manager initialization, and records path progression metrics in the terminal summary. Stage 1.9.4 is next.

Stage 1.9.3.1 makes EvolutionManager3D own explicit upgrade offer planning. RunUpgradeManager3D emits only after a successful level update and validates planned IDs before turning them into option dictionaries. Focused prerequisites are guaranteed first, then incomplete secondary paths and new paths fill open slots; options include projected progression and the other two line levels. Stage 1.9.4 is next.

Stage 1.9.3.2 adds the public eligibility contract used by both planning and option creation. Evolution offer plans now use structured category entries, and projected states expose current/projected progress, line levels, completed-line counts, and completion markers without mutating the run. Stage 1.9.4 is next.

Stage 1.9.3.3 makes RunUpgradeManager3D the sole owner of normal offers: it shuffles the complete eligible catalog and returns up to three unique IDs with equal probability. Arena3D attaches neutral evolution context only after the random draw; it must never ask EvolutionManager3D to shape, replace, or order normal offers. HUD wording is closest-evolution informational only. Stage 1.9.3.4 is next.

The named 3D physics layers are Player, Enemies, PlayerProjectiles, Pickups, EnemyProjectiles, Environment, and Obstacles. They coexist with the unchanged 2D layer names. Player3D is on Player and collides with Environment/Obstacles; its PickupArea detects Pickups. Arena3D's ground is Environment and detects Player. Always use `Main.tscn` for normal-game validation.

## Ownership map

| Area | Owner | Do not move into |
| --- | --- | --- |
| Menu, hero/stage choice, run replacement | `Main.gd` | selection/result UI |
| Active run and modal safety | `Arena.gd` | `Main`, HUD, individual controls |
| Hero definitions / base kit metadata | `HeroDataProvider.gd` | UI or meta save |
| Stage definitions and previews | `StageDataProvider.gd` | `StageSelect` or `Arena` |
| Hero application | `HeroApplier.gd` | `Player` or UI |
| Persistent rewards/progression | `MetaProgressionManager.gd` | Arena or result UI |
| Training and equipment definitions | their data providers | meta save/UI |
| Spawn scaling and variant selection | `SpawnDirector.gd` | `EnemySpawner` |
| Enemy creation, XP and powerup drops | `EnemySpawner.gd` | `SpawnDirector` |
| Run timer, kills and victory eligibility | `RunManager.gd` | HUD/result screens |
| Run upgrades and slot state | `UpgradeManager.gd` | `LevelUpScreen` |
| Triple evolution state/application | `EvolutionManager.gd` | Level-up UI |
| Shared temporary passives | `PassiveAbilityManager.gd` | meta save |
| Active abilities/cooldowns | `AbilityManager.gd` | Player, HUD, mobile controls |
| Objective entities and objective state | `StageObjectiveManager.gd` | HUD |
| Non-gameplay feedback | `FeedbackManager.gd` | combat scripts |

## Key scenes and files

| File | Purpose |
| --- | --- |
| `scenes/main/Main.tscn`, `Main.gd` | Entry point and all front-end/run transitions |
| `scenes/game/Arena.tscn`, `Arena.gd` | Active-run composition and coordination |
| `scenes/game/RunManager.gd` | Run timing, kills, boss/victory state |
| `scenes/player/Player.gd`, `PlayerAutoAttack.gd` | Movement/health/XP and primary weapon behavior |
| `scenes/abilities/AbilityManager.gd` | Three active slots, hero-kit routing, cooldowns |
| `scenes/enemies/EnemySpawner.gd`, `SpawnDirector.gd`, `Enemy.gd` | Spawn/inventory of enemies, pressure, role behavior |
| `scenes/upgrades/UpgradeManager.gd`, `scenes/evolution/EvolutionManager.gd` | Run upgrades, slot grid, triple evolutions |
| `scenes/meta/MetaProgressionManager.gd`, `MetaApplier.gd` | Persistent progression and run-start modifiers |
| `scenes/ui/StageSelect.gd`, `RunBriefingScreen.gd` | Stage/level choice and display-only briefing |
| `scenes/objectives/StageObjectiveManager.gd` | Survival, defense, and portal objective integration |
| `scenes/enemies/FinalBossController.gd` | Final boss encounter state and attacks |

## Persistence and compatibility

Keep these stores separate:

| Path | Owner | Contents |
| --- | --- | --- |
| `user://settings.cfg` | `SettingsManager` | Settings only |
| `user://superheroes_user_preferences.json` | `UserPreferencesManager` | Last hero/stage choices only |
| `user://superheroes_meta_progress.json` | `MetaProgressionManager` | Gameplay progression, inventory, Training, mastery, goals, stage progress |

`MetaProgressionManager.SAVE_VERSION` is 7. Preserve migration and compatibility behavior unless a task explicitly changes the save format. Call `MetaProgressionManager.apply_run_result(summary)` only from the run-completion flow; neither Arena nor display screens should award or save results directly. Run-only upgrades, passives, buffs, evolutions, debug state, and temporary currencies must not be persisted.

Training is hero-specific; equipment is shared/global. Apply progression in the existing order: hero data first, then `MetaApplier`. Do not let another hero's Training affect the selected hero.

## Gameplay contracts

- The live front-end chain is Main Menu → Character Select → Stage Select → Run Briefing → Arena.
- `StageSelect` is the only stage/zone selection screen. Do not create `ZoneSelect` or a duplicate zone provider.
- Stage level data is UI preview data only until a scoped scaling implementation changes that contract.
- Player damage follows `Player.take_damage()`; miniboss/final-boss damage must use it or existing enemy-projectile collision.
- `RunManager` controls victory eligibility. Stage objectives may trigger the final boss and call `mark_boss_phase_triggered()` to suppress duplicate timer triggers.
- `SpawnDirector` contains difficulty and wave formulas; `EnemySpawner` contains safe position selection and instancing.
- Enemy variants are dictionaries, not Resource assets.
- `EvolutionManager` owns 27 current triples (9 per hero); UI only offers/visualizes choices.
- `DebugManager` owns debug state. Debug actions remain gated by debug mode; overlays are read-only.
- `FeedbackManager` routes feedback and respects settings. It never applies damage, buffs, state transitions, or saves.

## UI rules

- `GameHUD`, `DebugStatsOverlay`, result screens, `BuildSlotsWindow`, `HeroCollectionScreen`, and `RunBriefingScreen` are display-only.
- `MobileControls` emits movement/ability/pause/build intents. Arena wires the intents; the control must not mutate gameplay directly.
- `Main` owns transitions outside a run; `Arena` owns transitions during a run. `VictoryScreen`/`GameOverScreen` request actions through signals only.
- Use `UIFormat`, `UIStateColors`, and `EquipmentFormat` for their existing display domains rather than duplicating display strings or colors.
- Equipment interactions remain in `MetaUpgradeShop`: item actions require the existing confirmation flow for Dismantle. Do not bypass locked/equipped protections.

## Input, platform, and export

- Movement: WASD/arrows; abilities: J/K/L; dash: Space; pause: Escape; help: H/F11.
- Debug mode and its actions are project input actions and must not affect normal play while disabled.
- Preserve 1280×720 canvas-item stretch/expand behavior and landscape Web usability.
- The checked-in `Web` export preset writes to `export/index.html`. No Yandex SDK, cloud storage, paid services, or custom Web template is present.

## Known debt and limitations

- `scenes/game/EventDirector.tscn` is the active Arena child. `scenes/events/EventDirector.gd` is a dynamically loaded fallback only if that child is absent. Their schedules differ; do not assume they are interchangeable. Consolidation is a separate code task.
- The stage-level preview exposes enemy/loot multipliers without applying them to runtime combat or reward formulas.
- Legacy inventory/meta APIs coexist with the current inventory/Dismantle UI. Preserve callers during scoped changes.

## Change discipline

Stage 1.9.3 is complete: all Knight offers are uniformly random among eligible upgrades and evolution progress is presentation-only. Do not reintroduce focus/recommendation state or use closest-path metrics to steer offers. Keep five-level metadata physical in raw definitions, preserve readable upgrade comparisons, and treat Stage 1.9.4 as the next progression task.

Neutral presentation enriches random options after selection. Passive definitions expose summary/comparison validation, level-up cards show neutral prerequisite progress and completion markers, and multiple ready evolutions must be offered sequentially before returning to pending level-ups or combat.

Stage 1.9.4 presentation effects must be Web-safe and presentation-only: low-vertex meshes created once per instance, short lifetimes, no collision/query logic, no global hit-stop, and guaranteed cleanup. Preserve all Knight formulas, evolution combinations, and unbiased upgrade selection; Stage 1.9.5 follows.

Ground Shockwave must use `GroundShockwaveEffect3D`; Crushing Storm must use `CrushingStormEffect3D`. Earthsplitter and Seismic Fan crack geometry is generated once through `GroundCrackMeshBuilder3D`; it is visual-only and must never alter their existing line/cone queries.

Stage 1 closes at 1.9.5 with the 27-line/five-level, nine-evolution/5-5-5, uniformly-random and neutrally-presented Knight contract. Do not alter balance without recorded controlled-run evidence. The final manual and Web checklist is `docs/validation/knight_stage_1_release_validation.md`; Stage 2 starts with Crossbowman.

Stage 2.1 adds Crossbowman as the cosmetic 3D port of legacy `guardian` / `solar_guardian` with the preserved `solar_ray` ID. Main chooses `Arena3D` from hero runtime data, and Arena3D instantiates the selected 3D player scene; Guardian uses CrossbowmanPlayer3D while Vanguard keeps Player3D, and Blaster remains 2D. Keep shared Arena code generic: resolve player, autoattack, optional kit/ability controller, visual, and action controller through stable nodes; Knight typing stays in Knight scripts. Solar Ray is a crossbow bolt presentation over the legacy direct corridor hit query; Solar Energy is a run-local 2/sec-to-100 resource with a 15-second 2.0x empowered state. Guardian Stage 2.1 has only the nine shared passive upgrade lines, no active abilities, hero-specific lines, or evolutions. Stage 2.2 is Solar Beam, Frost Breath, and Death Dash.

Stage 2.1.1 requires CrossbowmanPlayer3D to use Player collision layer 1/mask 96 and the matching hurtbox/pickup setup. Arena3D must abort cleanly if a configured hero player scene, AutoAttack, ActionController, or HeroVisual is invalid; never spawn enemies or wire run signals after that failure. `HeroVisual` is the stable player visual node. Guardian upgrade scope is enforced by every public manager path, including direct `apply_upgrade`. Keep unavailable Guardian ability UI fully hidden and Solar Energy named exactly `Solar Energy`; its empowered flag/time is separate state. Crossbow Shot retains the original corridor mechanics and emits a structured per-shot result. Cleanup must be idempotent across finish, restart, quit, and scene removal.

Stage 2.1.2 Crossbowman presentation uses `Ranger.glb`, `Rig_Medium_CombatRanged.glb`, and `crossbow_2handed.gltf`, not Knight assets. Use actual clips `Ranged_2H_Shoot` for Crossbow Shot, `Ranged_2H_Aiming` for a future charged shot, and `Ranged_2H_Shooting` for a future volley. Ranger's `handslot.r` owns the crossbow attachment and its muzzle marker; the marker follows ranged animation and is the only Crossbow Shot bolt origin. Crossbowman extends neutral `KayKitAnimatedVisual`, never `KnightVisual`. Keep gameplay queries/values out of visual code; Stage 2.2 remains the active-ability port.

- Keep changes small, local, and source-backed. Do not add unrelated systems, duplicate managers, or broad refactors.
- Do not add persistence, monetization, cloud/Yandex services, online features, arena hazards, input remapping, audio assets, or new enemy types unless explicitly requested.
- Avoid copyrighted superhero IP.
- Preserve pause cleanup, signal disconnection/validity checks, and UI display-only boundaries.
- After changes, inspect `git diff` and confirm changed files match the task. Do not commit unless explicitly asked.
