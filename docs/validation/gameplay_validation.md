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

## Controls Help Overlay

| # | Test | Expected |
|---|------|----------|
| 1 | Click **Help / Controls** on MainMenu | ControlsHelpOverlay opens over the menu and blocks clicks behind it |
| 2 | Press **Close** or **Escape** while help is open | Help closes and MainMenu remains usable |
| 3 | Press **H** or **F11** on MainMenu | Help toggles when Settings and Training shop are not open |
| 4 | Start a run, then press **H** or **F11** during active gameplay | Help opens, gameplay pauses, movement/mobile input stops |
| 5 | Close help opened during active gameplay | Gameplay resumes only if Help created the pause |
| 6 | Open PauseMenu, then click **Help / Controls** | Help opens above PauseMenu while the run stays paused |
| 7 | Close help opened from PauseMenu | Returns to PauseMenu state; gameplay does not resume |
| 8 | Open Settings from PauseMenu, then press **H** | Help does not open over SettingsMenu |
| 9 | Open LevelUpScreen, EvolutionRewardScreen, VictoryScreen, or GameOverScreen | Help does not open over those modal screens |
| 10 | Scroll the Help / Controls content with wheel/touch drag | ScrollContainer moves normally; Close button still receives clicks |
| 11 | Click/touch behind the help overlay | Underlying menu/gameplay controls do not receive the click |

---

## Main Menu Rework

| # | Test | Expected |
|---|------|----------|
| 1 | Open the game | MainMenu appears with title/subtitle centered |
| 2 | Inspect top-left corner | Settings button is located top-left and does not overlap the title |
| 3 | Inspect top-right corner | Help / Controls button is located top-right and does not overlap the title |
| 4 | Inspect bottom interface | Select Hero and Training are horizontal neighbors with consistent spacing |
| 5 | Click Select Hero | CharacterSelect opens |
| 6 | Click Back from CharacterSelect | Returns to MainMenu |
| 7 | Select a hero | StageSelect opens normally |
| 8 | Complete StageSelect | Arena starts normally |
| 9 | Click Training from MainMenu | MetaUpgradeShop opens from the bottom Training button |
| 10 | Click Back from Training | Returns to MainMenu |
| 11 | Click Settings from top-left | SettingsMenu opens |
| 12 | Close Settings | Returns to MainMenu |
| 13 | Click Help / Controls from top-right | ControlsHelpOverlay opens |
| 14 | Close Help / Controls | MainMenu remains usable |
| 15 | Return to MainMenu after remembered choices exist | `Last: Hero / Stage` hint remains readable in the center panel |
| 16 | Start/run flow after menu rework | MainMenu -> CharacterSelect -> StageSelect -> Arena still works |
| 17 | Pause during Arena | Pause menu still works |
| 18 | Restart from run/result flow | Current hero/stage restart behavior is unchanged |
| 19 | Exit to MainMenu from run/result flow | Returns safely to the reworked MainMenu |
| 20 | Victory/GameOver/Post-run rewards flow | Existing reward transition remains unchanged |
| 21 | Enable Debug Mode during a run | Debug tools still work |
| 22 | Inspect git diff | No gameplay balance values, new content, or persistence changes are present |

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
| 3 | Select **Solar Guardian**, then Start Run | Run starts with Guardian id, solar color, and 130 max HP |
| 4 | Select **Night Tactician**, then Start Run | Run starts with Blaster id, 90 max HP, +1 projectile, and tactical tool tuning |
| 5 | Select **Fury Vanguard**, then Start Run | Run starts with Vanguard id, 125 max HP, slower bruiser speed, and heavy close-range tuning |
| 6 | Start any hero | HUD shows `Hero: <name>` |
| 7 | Reach Victory/GameOver | Summary screen shows `Hero: <name>` |
| 8 | Restart from Victory/GameOver | Fresh run starts with the same selected hero |
| 9 | Quit to MainMenu, then start another run | CharacterSelect opens and allows choosing a different hero |
| 10 | Enable Debug Mode for each hero | F1-F8 debug tools still work |
| 11 | Pick weapon/ability/synergy upgrades | Upgrades stack on top of hero starting stats |

---

## Guardian Ability Rework

| # | Test | Expected |
|---|------|----------|
| 1 | Open CharacterSelect | Guardian appears as Solar Guardian with solar/sky powerhouse role text |
| 2 | Select Guardian and start a run | Run starts normally with Guardian selected |
| 3 | Check GameHUD ability panel | Slot labels show Solar Burst, Solar Beam, and Aerial Impact presentation |
| 4 | Press ability_1 / J as Guardian near enemies | Radiant close-area pulse casts, damages enemies, and cooldown updates |
| 5 | Press ability_2 / K as Guardian with enemies ahead | Focused forward beam casts, damages enemies, and cooldown updates |
| 6 | Press ability_3 / L as Guardian near enemies | Impact burst casts, damages enemies, and cooldown updates |
| 7 | Enable mobile controls while Guardian is selected | Ability buttons use Guardian-specific labels and still cast slots 1/2/3 |
| 8 | Open DebugStatsOverlay during Guardian run | Ability stats still display without errors |
| 9 | Start a Night Tactician run | Blaster uses Smoke Charge, Grapnel Shot, and Shock Trap presentation without changing ability ids |
| 10 | Start a Fury Vanguard run | Vanguard uses Rage Burst, Crushing Leap, and Titan Slam presentation without changing ability ids |
| 11 | Check Training with Guardian selected | Per-Hero Training still applies only Guardian Training |
| 12 | Inspect changed text | No licensed superhero names or protected character identities are used |

---

## Blaster Ability Rework

| # | Test | Expected |
|---|------|----------|
| 1 | Open CharacterSelect | Blaster appears as Night Tactician with dark gadget tactician role text |
| 2 | Select Blaster and start a run | Run starts normally with hero id `blaster` |
| 3 | Check GameHUD ability panel | Slot labels show Smoke Charge, Grapnel Shot, and Shock Trap presentation |
| 4 | Press ability_1 / J as Blaster near enemies | Tactical burst zone casts, damages enemies, and cooldown updates |
| 5 | Press ability_2 / K as Blaster with enemies ahead | Precision line strike casts, damages enemies, and cooldown updates |
| 6 | Press ability_3 / L as Blaster near enemies | Close control impact casts, damages enemies, and cooldown updates |
| 7 | Enable mobile controls while Blaster is selected | Ability buttons use Blaster-specific labels and still cast slots 1/2/3 |
| 8 | Open DebugStatsOverlay during Blaster run | Ability stats still display without errors |
| 9 | Start a Solar Guardian run | Guardian-specific ability names still work |
| 10 | Start a Fury Vanguard run | Vanguard uses Rage Burst, Crushing Leap, and Titan Slam presentation without changing ability ids |
| 11 | Check Training with Blaster selected | Per-Hero Training still applies only Blaster Training |
| 12 | Inspect changed text | No licensed superhero names or protected character identities are used |

---

## Vanguard Ability Rework

| # | Test | Expected |
|---|------|----------|
| 1 | Open CharacterSelect | Vanguard appears as Fury Vanguard with rage bruiser role text |
| 2 | Select Vanguard and start a run | Run starts normally with hero id `vanguard` |
| 3 | Check GameHUD ability panel | Slot labels show Rage Burst, Crushing Leap, and Titan Slam presentation |
| 4 | Press ability_1 / J as Vanguard near enemies | Close-area fury pulse casts, damages enemies, and cooldown updates |
| 5 | Press ability_2 / K as Vanguard with enemies ahead | Forward impact line casts, damages enemies, and cooldown updates |
| 6 | Press ability_3 / L as Vanguard near enemies | Heavy ground smash casts, damages enemies, and cooldown updates |
| 7 | Enable mobile controls while Vanguard is selected | Ability buttons use Vanguard-specific labels and still cast slots 1/2/3 |
| 8 | Open DebugStatsOverlay during Vanguard run | Ability stats still display without errors |
| 9 | Start a Solar Guardian run | Guardian-specific ability names still work |
| 10 | Start a Night Tactician run | Blaster-specific ability names still work |
| 11 | Check Training with Vanguard selected | Per-Hero Training still applies only Vanguard Training |
| 12 | Inspect changed text | No licensed superhero names or protected character identities are used |

---

## Remember Last Choice QoL

| # | Test | Expected |
|---|------|----------|
| 1 | Select **Blaster** and **Neon Lab**, then start a run | Run starts with Blaster on Neon Lab |
| 2 | Quit to MainMenu, then press **Select Hero** again | CharacterSelect preselects Blaster and shows `Last selected` |
| 3 | Confirm Blaster | StageSelect preselects Neon Lab and shows `Last selected` |
| 4 | Restart from a run result | Fresh run keeps the same current hero/stage without reopening selection |
| 5 | Close and reopen the game | Last hero/stage are still remembered from `user://superheroes_user_preferences.json` |
| 6 | Delete `user://superheroes_user_preferences.json`, then start game | Default hero/stage are selected safely |
| 7 | Corrupt `user://superheroes_user_preferences.json`, then start game | Warning is printed; default hero/stage are selected safely |
| 8 | Call `UserPreferencesManager.reset_preferences()` from editor/remote console | Remembered hero/stage reset only; meta progression and settings remain unchanged |
| 9 | Press Training after preferences exist | Training shop still opens and currency/meta upgrades remain intact |
| 10 | MainMenu after remembered choices exist | Compact `Last: Hero / Stage` hint appears |

### How to reset preferences

In the Godot remote inspector or editor console, call:

```gdscript
get_tree().current_scene.get_node("UserPreferencesManager").reset_preferences()
```

This resets only `user://superheroes_user_preferences.json`. It does not reset `user://superheroes_meta_progress.json` or `user://settings.cfg`.

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

## Pause / Restart / Exit Safety QoL

| # | Test | Expected |
|---|------|----------|
| 1 | Press **Escape** during active gameplay | PauseMenu opens and the run pauses |
| 2 | Press **Escape** again while PauseMenu is open | PauseMenu closes and the run resumes |
| 3 | Click Restart Run from PauseMenu | Confirmation dialog opens; PauseMenu buttons are disabled behind it |
| 4 | Confirm Restart | Exactly one restart request is emitted and a fresh run starts |
| 5 | Cancel Restart | Confirmation closes, PauseMenu stays open, and the tree remains paused |
| 6 | Click Quit to Menu from PauseMenu | Confirmation dialog opens with Main Menu action text |
| 7 | Confirm Main Menu | Exactly one quit-to-menu request is emitted and MainMenu opens |
| 8 | Cancel Main Menu | Confirmation closes, PauseMenu stays open, and the tree remains paused |
| 9 | Open Settings from PauseMenu, then close it | Returns to PauseMenu state without unpausing gameplay |
| 10 | Open Help from PauseMenu, then close it | Returns to PauseMenu state without unpausing gameplay |
| 11 | Open Help during active gameplay, then close it | Run pauses while help is open and resumes after close |
| 12 | Press **H** / **F11** while Help is open | Help closes; it does not open over Settings or blocking run screens |
| 13 | Press **Escape** while LevelUpScreen is open | Level-up choice remains open; pause toggle is ignored |
| 14 | Press **Escape** while EvolutionRewardScreen is open | Evolution reward remains open; it is not skipped |
| 15 | Press **Escape** while VictoryScreen or GameOverScreen is open | Result screen remains open; pause toggle is ignored |
| 16 | Click Restart/MainMenu repeatedly on VictoryScreen or GameOverScreen | PostRunRewardsScreen shows once and rewards apply once |
| 17 | Click Continue repeatedly on PostRunRewardsScreen | Continue is accepted once; pending restart/menu action runs once |
| 18 | Double-click CharacterSelect Start Run or StageSelect Start Run | Only one StageSelect/Arena transition happens |
| 19 | Press mobile Pause button | Follows the same behavior as Escape for PauseMenu, Settings, Help, and ConfirmDialog |
| 20 | Try mobile ability/dash buttons while any modal is open | No ability or dash signal is emitted |
| 21 | Repeatedly open/close PauseMenu, Settings, Help, ConfirmDialog | No stuck paused/unpaused state occurs |

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

---

## Per-Hero Training

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training from MainMenu | MetaUpgradeShop opens and shows `Training: <Hero>` |
| 2 | Open Training with no selected hero | Default/remembered hero is resolved and displayed clearly |
| 3 | Buy one Training upgrade for Guardian | Shared currency decreases; Guardian level increases |
| 4 | Switch to Blaster in Training | Blaster does not inherit Guardian's newly purchased level |
| 5 | Buy one Training upgrade for Blaster | Guardian and Blaster show separate levels |
| 6 | Switch to Vanguard | Vanguard shows its own separate Training levels |
| 7 | Start run as Guardian | Only Guardian Training bonuses apply |
| 8 | Start run as Blaster | Only Blaster Training bonuses apply |
| 9 | Start run as Vanguard | Only Vanguard Training bonuses apply |
| 10 | Restart a run | Same hero/stage restarts and the same hero-specific Training applies |
| 11 | Finish or lose a run | Post-run rewards still add shared currency |
| 12 | Close/reopen game | Per-hero Training levels persist |
| 13 | Load an old save with global `meta_upgrades` | Global levels are copied to Guardian, Blaster, and Vanguard |
| 14 | Missing/corrupt save | Fresh defaults load safely |
| 15 | Check Remember Last Choice | Hero/stage preferences are not reset by Training |
| 16 | Check Settings | Settings are not reset by Training |
| 17 | Inspect git diff | No gameplay balance values changed |

### How to reset progress (debug only)
In the Godot remote inspector or editor console, call:
```gdscript
get_tree().current_scene.meta_progression_manager.reset_progress()
```
Or access it from Main node in the scene tree inspector and call reset_progress() from the Remote tab.
Do NOT bind a key to reset_progress in gameplay code; this could cause accidental data loss.

---

## Stage Select

| # | Test | Expected |
|---|------|----------|
| 1 | Start game → click Start | MainMenu → CharacterSelect |
| 2 | Confirm a hero | CharacterSelect → StageSelect opens |
| 3 | StageSelect: 3 stages listed | City Rooftop, Neon Lab, Wasteland Gate visible |
| 4 | Click a stage | Detail panel updates: name, subtitle, difficulty, description, final boss name |
| 5 | Click Back in StageSelect | Returns to CharacterSelect; same hero still shown |
| 6 | Confirm a stage | Arena starts with the correct background colors and stage name in HUD |
| 7 | HUD during run | "Stage: City Rooftop" label visible in RunPanel |
| 8 | Victory/GameOver screen | "Stage: City Rooftop" row visible below hero name |
| 9 | Restart from VictoryScreen | Same hero AND same stage; StageSelect does not re-open |
| 10 | Quit to MainMenu | Both hero and stage selection are cleared |
| 11 | Start again from MainMenu | Goes through CharacterSelect → StageSelect before starting run |
| 12 | Select Neon Lab | Background is visually different from City Rooftop |
| 13 | Select Wasteland Gate | Background is visually different from Neon Lab |

---

## Final Boss

| # | Test | Expected |
|---|------|----------|
| 1 | Set `use_debug_run_duration=true, debug_target_run_time=60` in RunManager | Run ends at 60s; final phase at ~54s |
| 2 | Survive to target time (City Rooftop) | "Final Boss Incoming!" announcement; run does NOT immediately end |
| 3 | Final boss spawns | Large enemy appears; BossHealthBar shows at top (below miniboss bar if one is active) |
| 4 | BossHealthBar label | Shows "FINAL BOSS", boss display name, HP bar, HP text |
| 5 | Boss HP drops below 50% | "Final Boss Enraged!" announcement; attacks become faster |
| 6 | Final boss takes damage | BossHealthBar HP bar updates correctly |
| 7 | Final boss defeated | "Final Boss Defeated!" announcement; BossHealthBar hides; VictoryScreen appears |
| 8 | VictoryScreen after final boss | Shows all stats; stage name present |
| 9 | PostRunRewardsScreen after victory | "Final boss" row shows +35 |
| 10 | Defeat before target time | GameOverScreen shows; no final boss spawned; final_boss_reward = 0 |
| 11 | Neon Lab: Prism Overlord | BossHealthBar shows "Prism Overlord"; higher barrage count than titan_guardian |
| 12 | Wasteland Gate: Molten Colossus | BossHealthBar shows "Molten Colossus"; larger nova radius than titan_guardian |
| 13 | Debug: `get_tree().current_scene.get_node("Arena").debug_spawn_final_boss()` in remote console | Final boss spawns immediately; BossHealthBar appears; run victory gating activates |
| 14 | Miniboss and final boss both active | Both health bars visible; no overlap (boss bar at offset 70, miniboss at offset 10) |

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

---

## UI Readability Polish

| # | Test | Expected |
|---|------|----------|
| 1 | Start a run at 1280×720 | HUD panels visible in top-left; no panel text is clipped; RunPanel, AbilityPanel, BuffPanel, BuildPanel do not overlap |
| 2 | Player HP drops to 31–100% | HP label shows `current / max` in white |
| 3 | Player HP drops to 16–30% | HP label turns amber (warning color) |
| 4 | Player HP drops to 1–15% | HP label shows `LOW  current / max` in red (danger color) |
| 5 | Abilities are on cooldown | J/K/L labels show cooldown time in gray; e.g. `K  Laser: 3.4s` |
| 6 | Ability cooldown expires | Label turns green and shows `Ready`; e.g. `J  Nova: Ready` |
| 7 | Dash is on cooldown | `Space  Dash: 2.1s` shown in gray |
| 8 | Dash cooldown expires | `Space  Dash: Ready` shown in green |
| 9 | Run time advances | `Time  1:30` format; `Goal: Survive 1:30 / 10:00` updates each second |
| 10 | Final phase triggers (9:00) | `★ FINAL PHASE` appears in magenta in RunPanel |
| 11 | Final boss spawns | `Final Boss: Titan Guardian` appears in orange in RunPanel |
| 12 | Final boss defeated | `Boss defeated` shown in green in RunPanel |
| 13 | Pick a build archetype upgrade | `Build: Projectile` (or current dominant) shows in BuildPanel |
| 14 | Apply an evolution | `Evolved: Evolution Name` or `Evolved: 2` shows in BuildPanel |
| 15 | Collect shield powerup | `Shield: N` shown in green in BuffPanel |
| 16 | Collect speed powerup | `Speed: X.Xs` shown in green in BuffPanel; hidden when expired |
| 17 | Open LevelUpScreen | Cards show: title, `[RARITY]  [ARCHETYPE]`, `★ SYNERGY` / `◆ BUILD DEFINING` markers, level line, description; rare/epic/legendary cards have subtle color tint |
| 18 | Open EvolutionRewardScreen | Cards show: `◆ EVOLUTION  [ARCHETYPE]`, title, description in golden tint |
| 19 | No evolution available | EvolutionRewardScreen shows friendly "No evolution available" message and Continue button |
| 20 | VictoryScreen shows | Result has: VICTORY title in green, `Time:`, `Enemies:`, `Elites:`, `Minibosses:`, `Level:`, `Hero:`, `Stage:`, `Final Boss:`, `Build:`, `Upgrades:`, `Evolutions:` rows with consistent labels |
| 21 | GameOverScreen shows | Result has: RUN OVER title in red, same stat rows as Victory but without Final Boss if not reached |
| 22 | PostRunRewardsScreen shows | All reward rows with `+N` right-aligned; non-zero values in green, zero values in gray; total row in green; total currency in green |
| 23 | Training shop opens | Rows show title, description, level, cost; affordable Buy button in green; unaffordable or MAX button in gray |
| 24 | CharacterSelect: select a hero | Selected hero button turns green and is disabled; other hero buttons are white (or gray if locked) |
| 25 | StageSelect: select a stage | Selected stage button turns green and is disabled; other stage buttons are white |
| 26 | Open Help / Controls overlay | Section titles are uppercase amber, separated by horizontal lines; body text is white; scroll works; Close button visible |
| 27 | No gameplay values changed | Ability cooldowns, enemy stats, XP thresholds, reward formula all unchanged from pre-polish values |

---

## Feedback Polish Pack

| # | Test | Expected |
|---|------|----------|
| 1 | Walk into **heal** powerup | `+25 HP` floating text appears in green near pickup position |
| 2 | Walk into **shield** powerup | `SHIELD` floating text appears in blue near pickup position |
| 3 | Walk into **bomb** powerup | `BOMB` floating text appears; BombBurst visual; brief screen shake |
| 4 | Walk into **magnet_burst** powerup | `MAGNET` floating text appears in purple; XP gems attracted |
| 5 | Walk into **speed** powerup | `SPEED` floating text appears in cyan |
| 6 | Walk into **haste** powerup | `HASTE` floating text appears in yellow |
| 7 | Player takes real HP damage | Brief red flash on player; small screen shake; damage number floats up |
| 8 | Player damage is blocked by dash invulnerability | No flash, no shake, no damage text |
| 9 | Player damage is blocked by debug invulnerability | No flash, no shake, no damage text |
| 10 | Player shield absorbs a hit | `BLOCK` status text floats up; no HP damage text |
| 11 | Enemy takes normal damage | Hit flash brightens briefly to white-red and fades over ~0.12s; original color restores |
| 12 | Shielded enemy absorbs a hit fully | Blue-white flash instead of red-white flash |
| 13 | Enemy dies | Death burst visual still plays normally |
| 14 | Nova Pulse fires | Brief screen shake; Nova ring visible |
| 15 | Hero Slam fires | Stronger brief screen shake; slam ring visible |
| 16 | Elite enemy spawns | `Elite Incoming!` announcement; brief screen shake |
| 17 | Miniboss enemy spawns | `Miniboss Incoming!` announcement; medium screen shake |
| 18 | Final boss spawns | `Final Boss Incoming!` announcement; strong screen shake |
| 19 | Miniboss defeated | `Miniboss Defeated!` announcement |
| 20 | Final boss defeated | `Final Boss Defeated!` announcement; screen shake |
| 21 | Evolution applied | `Evolution: [Name]!` announcement; `EVOLVED` floating text near player in gold; small shake |
| 22 | Settings → disable Screen Shake | No shakes from any source (player damage, boss spawn, abilities) |
| 23 | Settings → Shake Intensity slider at 0.5 | Shakes noticeably weaker but still present |
| 24 | Settings → disable Floating Text | No floating text spawns at all during gameplay |
| 25 | Settings → disable Impact Flash | Enemy hit flashes and player hit flash do not appear |
| 26 | Heavy projectile build (multishot+pierce+bounce) | Damage numbers appear but do not saturate screen; throttle limits non-critical texts to ~6 per 0.08s window |
| 27 | Debug F7 with settings configured | DebugStatsOverlay `-- Feedback --` section shows current shake/text/flash toggles and intensity |
| 28 | MetaUpgradeShop: buy an upgrade | Row briefly flashes green; level updates; buy button turns gray if maxed |
| 29 | No gameplay damage/cooldown values changed | All ability cooldowns, enemy stats, powerup values, drop rates identical to pre-patch |
