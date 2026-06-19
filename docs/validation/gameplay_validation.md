# Gameplay Validation Checklist

Manual test cases for the debug & balance validation pass.
Run these before adding new gameplay systems.

---

## Debug Mode

| # | Test | Expected |
|---|------|----------|
| 1 | Press **F12** (or F10) during a run | "DEBUG ON" overlay appears; player becomes invulnerable; DebugStatsOverlay appears top-left |
| 2 | Press **F12** again | Overlay hides; invulnerability removed |
| 3 | Press **F1** (or F2) while Debug Mode ON | Level-up screen opens (+1 level) |
| 4 | Press **F1** while Debug Mode OFF | Nothing happens |
| 5 | Press **F3** while Debug Mode ON | Powerup pickup spawns near player, cycles through types each press; console: `DEBUG_ACTION: spawned powerup <id>` |
| 6 | Press **F4** while Debug Mode ON | Elite enemy spawns; console: `DEBUG_ACTION: spawned elite` |
| 7 | Press **F5** while Debug Mode ON | Miniboss spawns; HP bar appears at top of screen; console: `DEBUG_ACTION: spawned miniboss` |
| 8 | Press **F6** while Debug Mode ON | Player gains 50 XP (may trigger level-up); console: `DEBUG_ACTION: added XP 50` |
| 9 | Press **F7** while Debug Mode ON | Compact stats print to console; DebugStatsOverlay refreshes immediately |
| 10 | Press **F8** while Debug Mode ON | All enemies within ~500px die with drop effects; console: `DEBUG_ACTION: killed nearby enemies count=N` |
| 11 | Any F3-F8 while Debug Mode OFF | Nothing happens |
| 12 | Any F3-F8 while tree is paused | Nothing happens |
| 13 | Any F3-F8 while player is dead | Nothing happens |

---

## DebugStatsOverlay

| # | Test | Expected |
|---|------|----------|
| 1 | Enable Debug Mode (F12) | Overlay visible top-left; shows player HP/level/XP/speed, weapon stats, ability stats, build archetype, spawner wiring |
| 2 | Take damage | HP value updates within 0.25s |
| 3 | Pick up an upgrade | Build / weapon stats update within 0.25s |
| 4 | Disable Debug Mode | Overlay hides |
| 5 | Press F7 | Overlay refreshes immediately |
| 6 | Pick a build-defining upgrade | Overlay shows build-defining picked/available counts |
| 7 | Pick ability/dash/bounce synergy upgrades | Overlay shows Nova/Laser/Slam synergy flags, dash trail flag, and projectile bounce count |

---

## Powerups

| # | Test | Expected |
|---|------|----------|
| 1 | Walk into **heal** pickup | HP restored (capped at max); "+HP" text appears |
| 2 | Walk into **shield** pickup | Shield charges increase in HUD |
| 3 | Take damage with shield active | Shield absorbs hit; no HP loss |
| 4 | Walk into **bomb** pickup | Enemies near player take 50 damage; BombBurst visual appears |
| 5 | Walk into **magnet** pickup | All nearby XP gems rush toward player |
| 6 | Walk into **speed** pickup | Player visibly speeds up for 6s; "Speed: X.Xs" shown in HUD |
| 7 | Walk into **haste** pickup | Attack rate increases for 6s; "Haste: X.Xs" shown in HUD |
| 8 | Press F3 repeatedly | Powerup types cycle: heal → shield → bomb → magnet_burst → move_speed_boost → attack_speed_boost → heal … |
| 9 | Enable powerup logging, then check console on game start | `POWERUP_WIRING: pickup_scene=True manager=True drop_chance=0.06` |

---

## Abilities

| # | Test | Expected |
|---|------|----------|
| 1 | Press **J** (Nova Pulse) near enemies | Enemies in radius take damage; ring visual plays; cooldown shows in HUD |
| 2 | Press **K** (Laser Beam) with enemies ahead | Enemies in beam line take damage; laser visual plays; cooldown shows in HUD |
| 3 | Press **L** (Hero Slam) near enemies | Enemies in radius take damage; ring visual plays; cooldown shows in HUD |
| 4 | Press ability key during cooldown | Nothing happens |
| 5 | Press ability key while tree is paused | Nothing happens |

---

## Weapon Upgrades

| # | Test | Expected |
|---|------|----------|
| 1 | Take **multishot** upgrade | Second projectile fires per attack |
| 2 | Take **pierce** upgrade | Projectile passes through one enemy |
| 3 | Take **explosion** upgrade | Projectile explodes on impact |
| 4 | Take **size** upgrade | Projectile visibly larger |
| 5 | F7 after each upgrade | Weapon stats in console/overlay reflect changed values |

---

## Build Archetypes

| # | Test | Expected |
|---|------|----------|
| 1 | Take 2+ projectile upgrades | "Build: Projectile" shown in GameHUD |
| 2 | Take 2+ nova upgrades | "Build: Nova" shown |
| 3 | Meet synergy prerequisites | Synergy upgrade (e.g. "Split Barrage") appears in upgrade pool |
| 4 | Apply synergy upgrade | Multiple stat effects applied at once |
| 5 | F7 or debug overlay | Shows dominant archetype and archetype point counts |
| 6 | Meet build-defining prerequisites | Upgrade option appears with `BUILD DEFINING` marker |
| 7 | Pick a build-defining upgrade | Debug overlay selected build-defining count increments |

---

## Ability & Build Synergy v4

| # | Test | Expected |
|---|------|----------|
| 1 | Pick **Aftershock Zone**, then cast Nova Pulse | Initial Nova damage happens immediately; a delayed aftershock damages enemies at the original cast position; aftershock feedback ring appears |
| 2 | Pick **Double Pulse**, then cast Laser Beam | Initial beam fires immediately; a delayed weaker second beam fires from the original origin/direction |
| 3 | Pick **Seismic Echo**, then cast Hero Slam | Initial slam fires immediately; delayed second wave damages enemies at the original slam position |
| 4 | Pick **Comet Dash**, then dash into enemies | Nearby enemies take damage when dash ends; dash cooldown/invulnerability behavior remains unchanged |
| 5 | Pick **Bouncing Bolts**, then shoot clustered enemies | Projectile bounces from the hit enemy to another nearby valid enemy without repeatedly damaging the same enemy instance |
| 6 | Use F7 / DebugStatsOverlay after each pick | New flags and counts reflect the picked build-defining effects |

---

## Balance / Readiness Pass

| # | Test | Expected |
|---|------|----------|
| 1 | Start a normal run with default Inspector values | Run starts without excessive console spam; only real missing dependency warnings should appear |
| 2 | Enable `GameplayTuning.enable_debug_input_logs` / Arena debug logging in Inspector | DEBUG_INPUT / DEBUG_WIRING style logs appear for diagnosis |
| 3 | Enable `GameplayTuning.enable_powerup_logs` or `EnemySpawner.powerup_debug_logging` | POWERUP_WIRING / POWERUP_ROLL / POWERUP_SPAWNED logs appear for diagnosis |
| 3a | Enable `GameplayTuning.enable_spawn_logs` or `EnemySpawner.spawn_debug_logging` | Compact SPAWN lines appear when enemies spawn |
| 4 | Toggle Debug Mode with F12/F10 | Debug overlay and DebugStatsOverlay still work |
| 5 | Use F3-F8 while Debug Mode ON | Debug tools still work; F7 still prints compact stats |
| 6 | Reach defeat, then Restart | GameOverScreen works and restart creates a fresh run |
| 7 | Reach victory, then Restart / Main Menu | VictoryScreen works and scene flow remains stable |
| 8 | Play with many enemies/projectiles | FPS remains stable; max alive enemies, projectile count, bounce count, explosion radius, and miniboss barrage stay capped |
| 9 | Cast Nova/Laser/Slam and their synergies | All abilities still work and keep distinct roles |
| 10 | Collect all powerup types | Powerups remain noticeable without flooding normal runs |
| 11 | Fight miniboss | Telegraphs are readable; dash/debug/shield protections still block damage |
| 12 | Observe advanced enemies | Shooter, exploder, swarm, shielded, and support behaviors still function |

---

## Character Select / Heroes

| # | Test | Expected |
|---|------|----------|
| 1 | Press **Select Hero** in MainMenu | CharacterSelect opens instead of starting Arena directly |
| 2 | Press **Back** from CharacterSelect | Returns to MainMenu |
| 3 | Select **Guardian**, then Start Run | Run starts with Guardian color and 120 max HP |
| 4 | Select **Blaster**, then Start Run | Run starts with 90 max HP and +1 projectile in weapon stats |
| 5 | Select **Vanguard**, then Start Run | Run starts with faster ability cooldowns and stronger Nova/Slam damage |
| 6 | Start any hero | HUD shows `Hero: <name>` |
| 7 | Reach Victory/GameOver | Summary screen shows `Hero: <name>` |
| 8 | Restart from Victory/GameOver | Fresh run starts with the same selected hero |
| 9 | Quit to MainMenu, then start another run | CharacterSelect opens and allows choosing a different hero |
| 10 | Enable Debug Mode for each hero | F1-F8 debug tools still work |
| 11 | Pick weapon/ability/synergy upgrades | Upgrades stack on top of hero starting stats |

---

## Evolution System

| # | Test | Expected |
|---|------|----------|
| 1 | Build projectile archetype points and meet a projectile prerequisite | Projectile Storm appears as an available evolution |
| 2 | Kill miniboss with an available evolution | EvolutionRewardScreen opens after the miniboss defeated announcement |
| 3 | Select **Projectile Storm** | HUD updates to show the applied evolution; projectile stats increase moderately |
| 4 | Continue the run after selecting evolution | Game resumes; no extra pause remains |
| 5 | Reach Victory/GameOver after evolution | Summary lists applied evolutions |
| 6 | Kill another miniboss after applying the same evolution | Already applied evolution does not appear again |
| 7 | Press F9 while Debug Mode ON and an evolution is available | EvolutionRewardScreen opens without auto-applying anything |
| 8 | Press F9 while no prerequisites are met | Console prints that no evolution is available; no screen opens |
| 9 | Restart run | Applied evolutions reset naturally |

---

## Miniboss

| # | Test | Expected |
|---|------|----------|
| 1 | Press **F5** with Debug Mode ON | Miniboss spawns; large purple enemy visible; HP bar appears at top |
| 2 | Miniboss at 50% HP | "Miniboss Enraged!" announcement shows; attacks become faster |
| 3 | Miniboss dies | "Miniboss Defeated!" announcement; guaranteed powerup drop; HP bar hides |
| 4 | Natural spawn (2:30 into run) | Same as above without F5 |

---

## Enemy Content v2

| # | Test | Expected |
|---|------|----------|
| 1 | Wait for Shooter enemies or debug spawn a shooter | Shooter approaches into range, shoots, and does not retreat when the player gets close |
| 2 | Observe normal spawns | Enemies appear closer than before, roughly in a ring around the player, but not directly on top of the player |
| 3 | Remote call `debug_spawn_enemy_variant("exploder")` | Exploder chases, winds up near the player, pulses visually, explodes, and damages through `Player.take_damage()` |
| 4 | Remote call `debug_spawn_enemy_variant("swarm")` | Swarm approaches, then moves partly around the player instead of straight-line chasing only |
| 5 | Remote call `debug_spawn_enemy_variant("shielded")` | Shielded enemy absorbs damage with shield before HP decreases |
| 6 | Remote call `debug_spawn_enemy_variant("support")` near other enemies | Support periodically buffs nearby non-support enemies; buff expires naturally |
| 7 | Reach ~3:00, ~4:00, ~5:00, ~6:00 | Exploder Wave, Swarm Incoming, Shielded Front, and Support Units announcements trigger once |
| 8 | Use debug/dash/shield invulnerability against Exploder and Shooter | Damage goes through existing `Player.take_damage()` protections |
| 9 | Reach final phase/victory timing | Final phase and victory still trigger with the expanded enemy mix |

Remote console examples:

```gdscript
debug_spawn_enemy_variant("exploder")
debug_spawn_enemy_variant("swarm")
debug_spawn_enemy_variant("shielded")
debug_spawn_enemy_variant("support")
```

---

## Run Flow

| # | Test | Expected |
|---|------|----------|
| 1 | Press **Escape** during run | Pause menu opens; time stops |
| 2 | Resume from pause | Game resumes; no state corruption |
| 3 | Open Settings from pause | Settings menu overlays pause |
| 4 | Player HP reaches 0 | Game over screen shows time/kills/level |
| 5 | Restart from game over | Fresh arena, all debug keys still work |
| 6 | Quit to menu | Returns to main menu |

---

## Run Victory

| # | Test | Expected |
|---|------|----------|
| 1 | Start a run | HUD shows "Survive: 00:00 / 10:00" (objective label visible) |
| 2 | Run progresses | Objective label ticks up: "Survive: 01:30 / 10:00" |
| 3 | Reach 9:00 (final_phase_start_time = 540s) | "Final Phase!" announcement appears; HUD shows "FINAL PHASE"; spawn pressure increases |
| 4 | Reach 10:00 (target_run_time = 600s) | VictoryScreen appears with: time, kills, elite kills, miniboss kills, level, dominant build, upgrades count |
| 5 | Kill an elite during run | HUD "Elite N \| Boss 0" increments; VictoryScreen shows correct elite count |
| 6 | Kill a miniboss during run | HUD "Elite N \| Boss 1" increments; VictoryScreen shows correct miniboss count |
| 7 | Restart from VictoryScreen | Fresh arena starts; all state reset |
| 8 | Main Menu from VictoryScreen | Returns to MainMenu; no state persisted |
| 9 | Player dies before 10:00 | GameOverScreen shows (not VictoryScreen); shows elite/miniboss kills and build |
| 10 | Main Menu button on GameOverScreen | Returns to MainMenu (same as Restart path via Main) |
| 11 | Debug: set use_debug_run_duration=true, debug_target_run_time=60 in RunManager inspector | Victory triggers at ~60 seconds; final phase starts at ~54 seconds |
| 12 | Debug shortened run victory | VictoryScreen appears with correct shorter duration; all stats shown |
| 13 | VictoryScreen shows after victory | Tree is paused; player cannot take damage or move |
| 14 | GameOver after VictoryScreen | Should not happen; duplicate screen guard prevents it |

### How to test victory faster (editor only)
In the Godot editor, select the RunManager node inside Arena.tscn and set:
- `use_debug_run_duration = true`
- `debug_target_run_time = 60.0` (or any short value)

Final phase start time scales proportionally (e.g. 90% of target = 54s for a 60s run).
Remember to uncheck `use_debug_run_duration` before building for release.

---

## Meta Progression / Rewards

| # | Test | Expected |
|---|------|----------|
| 1 | Finish a run with defeat | PostRunRewardsScreen appears before restart/menu; currency is awarded |
| 2 | Finish a run with victory | Victory bonus (+40) appears in reward screen; currency earned |
| 3 | Kill elites before run ends | Elite reward (+5 per kill) reflected in reward breakdown |
| 4 | Kill miniboss before run ends | Miniboss reward (+15) reflected in reward breakdown |
| 5 | Apply evolutions during run | Evolution bonus (+10 per) shown in reward breakdown |
| 6 | Click Continue on reward screen | Returns to pending action (restart or main menu) |
| 7 | Restart run after rewards | New run starts; reward screen does NOT appear again for same run |
| 8 | Main Menu after rewards | Returns to MainMenu; currency persists |
| 9 | Start game a second time | Currency from previous run is still shown in Training shop |
| 10 | Press Training from MainMenu | MetaUpgradeShop opens with upgrade list and current currency |
| 11 | Buy an upgrade (enough currency) | Currency decreases; upgrade level increases; buy button updates |
| 12 | Buy same upgrade again | Cost increases; next level reflected correctly |
| 13 | Try to buy maxed upgrade | Buy button shows MAX and is disabled |
| 14 | Try to buy with insufficient currency | Buy button is disabled; purchase rejected |
| 15 | Start new run after buying max health | Player starts with +5 HP per level purchased |
| 16 | Start new run after buying attack damage | Auto attack damage starts higher than base |
| 17 | Start new run after buying move speed | Player moves noticeably faster at run start |
| 18 | Start new run after buying reward bonus | Reward bonus row shows +2 per level in next reward screen |
| 19 | Delete save file (user://superheroes_meta_progress.json) and restart | Game starts fresh with 0 currency and default unlocked heroes |
| 20 | Corrupt save file contents and restart | push_warning in console; game starts fresh with defaults |
| 21 | Enable Debug Mode (F12) | DebugStatsOverlay shows -- Meta -- section with currency and run counts |
| 22 | Buy upgrade then check F7 / overlay | Overlay reflects updated meta upgrade levels |
| 23 | Reset progress via MetaProgressionManager.reset_progress() in remote console | Currency resets to 0; save file updated |

### How to reset progress (debug only)
In the Godot remote inspector or editor console, call:
```gdscript
get_tree().current_scene.meta_progression_manager.reset_progress()
```
Or access it from Main node in the scene tree inspector and call reset_progress() from the Remote tab.
Do NOT bind a key to reset_progress in gameplay code; this could cause accidental data loss.

---

## Console Diagnostic Patterns

Expected log lines only when verbose debug/powerup logging is enabled in the Inspector:

```
DEBUG_WIRING: DebugManager exists=true
DEBUG_WIRING: DebugOverlay exists=true
DEBUG_WIRING: Player.set_debug_invulnerable=true
DEBUG_WIRING: Player.debug_gain_one_level=true
DEBUG_WIRING: Player.debug_add_experience=true
DEBUG_WIRING: signals connected=true
DEBUG_WIRING: DebugStatsOverlay instantiated=true
POWERUP_WIRING: pickup_scene=True manager=True drop_chance=0.06
```

Expected on F12 press:
```
DEBUG_INPUT: key=F12 physical=4194347 ...
DEBUG_MODE: enabled=true
DEBUG_PLAYER: invulnerable=true
```
