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
| 1 | Press **J** / ability slot 1 near enemies | Enemies in radius take damage; ring visual plays; hero-specific cooldown label shows in HUD |
| 2 | Press **K** / ability slot 2 with enemies ahead | Enemies in the forward line take damage; line visual plays; hero-specific cooldown label shows in HUD |
| 3 | Press **L** / ability slot 3 near enemies | Enemies in radius take damage; ring visual plays; hero-specific cooldown label shows in HUD |
| 4 | Press ability key during cooldown | Nothing happens |
| 5 | Press ability key while tree is paused | Nothing happens |

---

## Hero Signature Kits

| # | Test | Expected |
|---|------|----------|
| 1 | Start Solar Guardian and cast slot 1 near enemies | Solar Burst damages a radius, builds Solar Charge on hits, and updates cooldown |
| 2 | Build high Solar Charge, then cast Solar Beam or Aerial Impact | Charge is spent; damage/radius is stronger and DebugStatsOverlay charge decreases |
| 3 | Cast Aerial Impact near enemies | Impact occurs near/forward of the player and grants brief invulnerability |
| 4 | Start Night Tactician and cast any ability near enemies | Tactical Mark selects a priority/nearby enemy and appears in DebugStatsOverlay |
| 5 | Cast Grapnel Shot through the marked enemy | Narrow line strike hits; marked target takes bonus damage |
| 6 | Cast Shock Trap near enemies | Trap feedback appears, then delayed radius damage triggers |
| 7 | Cast Smoke Charge near enemies | Tactical burst damages enemies and applies temporary slow/control when supported |
| 8 | Start Fury Vanguard and take real HP damage | Rage increases in DebugStatsOverlay |
| 9 | Cast Rage Burst / Crushing Leap with Rage available | Damage scales with Rage and cooldowns update normally |
| 10 | Cast Titan Slam with Rage available | Heavy close impact fires, then Rage is partially spent |
| 11 | Check all three heroes on HUD and mobile controls | Labels use hero-specific names; inputs still emit slots 1/2/3 |
| 12 | Pick Nova/Laser/Slam upgrades after selecting any hero | Existing upgrade effects still tune slot 1/2/3 behavior through legacy properties |
| 13 | Restart after each hero/stage pair | Same hero, same stage, same kit, and same per-hero Training apply |
| 14 | Inspect diff and run flow | No enemies, stages, rewards, meta economy, save format, arena hazards, primary autoattack identity, or Build Evolution changes |

---

## Ability Button & Level-Up Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Start a run and press J/K/L immediately before enemies are in range | Each ready ability casts once, shows available feedback/status, enters cooldown, and updates HUD labels |
| 2 | Enable forced mobile controls and press each ability button once at run start | Each mobile button emits the same slot cast path and does not require repeated presses |
| 3 | Cast any ready ability with no enemies hit | Ability does not silently return; cooldown and `ability_cast` still happen |
| 4 | Cast Solar Guardian abilities with and without nearby enemies | Solar Charge feedback appears on hits; miss casts still show feedback/cooldown |
| 5 | Cast Night Tactician Shock Trap with no enemies present | Trap places, enters cooldown, and delayed trigger runs safely |
| 6 | Cast Fury Vanguard abilities with no enemies present | Rage/status feedback appears where applicable and cooldowns update |
| 7 | Trigger LevelUpScreen, then choose any upgrade | LevelUpScreen hides and the game unpauses automatically if no other blocking modal is open |
| 8 | Open PauseMenu after the level-up resume | PauseMenu opens/closes normally and does not need to be used to unstick the run |
| 9 | Trigger EvolutionRewardScreen and choose an evolution | Evolution reward still hides and resumes normally |
| 10 | Inspect diff | No enemy, stage, reward, save, meta economy, arena hazard, primary autoattack, or Build Evolution changes |

---

## Hero Signature Kits Real Mechanics

| # | Test | Expected |
|---|------|----------|
| 1 | Solar Guardian: hit enemies with Solar Burst | Solar Charge increases and "SOLAR CHARGED" appears when threshold is reached |
| 2 | Solar Guardian: cast empowered Solar Burst | Charge is consumed; burst radius/damage increase; small heal/defensive window triggers |
| 3 | Solar Guardian: cast Solar Beam with and without charge | Normal beam is narrow/focused; empowered beam is stronger and visibly wider/longer |
| 4 | Solar Guardian: cast Aerial Impact | Player shifts in aim direction, gains brief invulnerability, and impact damage lands at the new position |
| 5 | Night Tactician: cast Smoke Charge near enemies | Smoke/control zone damages and slows supported enemies; player gets brief safety feedback |
| 6 | Night Tactician: cast Grapnel Shot after a mark appears | Narrow line fires; marked target receives bonus damage when hit |
| 7 | Night Tactician: place Shock Trap | Trap persists, triggers on enemies entering radius, or discharges safely after duration |
| 8 | Fury Vanguard: take damage and deal ability damage | Rage rises from both sources and decays over time |
| 9 | Fury Vanguard: cast Rage Burst at low/high Rage | Damage/radius noticeably scale with current Rage |
| 10 | Fury Vanguard: cast Crushing Leap | Player moves forward with brief invulnerability; path/landing impact damage fires |
| 11 | Fury Vanguard: cast Titan Slam with Rage | Slam scales, spends Rage, and creates a delayed shockwave when Rage or second-wave support is present |
| 12 | Check DebugStatsOverlay for all heroes | Overlay shows kit id plus Solar Charge, Tactical Mark, or Rage |
| 13 | Pick Nova/Laser/Slam upgrades | Slot 1/2/3 upgrade hooks still affect the corresponding hero abilities |
| 14 | Inspect scope | No Enemy Roles, Boss Rework, Build Evolution, Stage Objectives, arena hazards, enemy/stage/reward/save/meta changes |

---

## Primary Weapon / Autoattack Rework

| # | Test | Expected |
|---|------|----------|
| 1 | Start **Solar Guardian** and let autoattack fire | Slower, heavier bolt fires toward nearest enemy; projectile is visibly larger (1.35× size) |
| 2 | Start **Night Tactician** and let autoattack fire | Faster darts fire; default bounce means darts hop to a second enemy when hit connects |
| 3 | Start **Fury Vanguard** and stand near enemies | Close-range shockwave deals damage directly with no visible projectile; floating damage numbers appear |
| 4 | Fury Vanguard: step out of range of all enemies | Shockwave does not fire; cooldown does not tick down from a no-target state |
| 5 | Night Tactician: mark a target with Grapnel Shot, then wait for autoattack | Darts should prioritize the marked target if it is within range |
| 6 | Pick `attack_damage_up` upgrade on any hero | Autoattack damage increases for all three weapon modes |
| 7 | Pick `attack_speed_up` upgrade on any hero | Cooldown between attacks decreases for all three weapon modes |
| 8 | Pick `attack_range_up` upgrade on any hero | Range area grows; Solar and Tactician target enemies further away; Vanguard shockwave reaches further |
| 9 | Pick `projectile_count` (multishot) upgrade on Solar Guardian / Night Tactician | Multiple projectiles fire per attack; Fury Vanguard is unaffected (no crash) |
| 10 | Pick `projectile_pierce` upgrade on Solar Guardian | Bolt passes through an enemy and hits the next one |
| 11 | Pick `projectile_bounce` upgrade on any hero | Solar/Tactician darts bounce; Fury Vanguard direct damage is unaffected (no crash) |
| 12 | Pick `projectile_explosion_radius` upgrade on any hero | Solar/Tactician projectiles explode on hit; Fury Vanguard direct damage is unaffected (no crash) |
| 13 | Enable Debug Mode (F12) | DebugStatsOverlay Weapon section shows `Primary: solar_bolt`, `gadget_darts`, or `shockwave_strike`; range, interval, count, pierce, bounce all display correctly |
| 14 | Check GameHUD BuildPanel | `Weapon: Solar Bolt`, `Weapon: Gadget Darts`, or `Weapon: Shockwave Strike` label is visible |
| 15 | Restart run keeping same hero | Weapon identity, range, and stat bonuses reset and re-apply correctly to the fresh run |
| 16 | Restart run changing hero | New hero's weapon mode, range, speed, and bounce defaults apply; no stale values from previous hero |
| 17 | Inspect diff | No saves, rewards, stages, arena hazards, enemy roles/wave director, boss flow, meta economy, or Build Evolution changes |

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
| 8 | Complete StageSelect | RunBriefingScreen opens, then Start Run starts Arena normally |
| 9 | Click Training from MainMenu | MetaUpgradeShop opens from the bottom Training button |
| 10 | Click Back from Training | Returns to MainMenu |
| 11 | Click Settings from top-left | SettingsMenu opens |
| 12 | Close Settings | Returns to MainMenu |
| 13 | Click Help / Controls from top-right | ControlsHelpOverlay opens |
| 14 | Close Help / Controls | MainMenu remains usable |
| 15 | Return to MainMenu after remembered choices exist | `Last: Hero / Stage` hint remains readable in the center panel |
| 16 | Start/run flow after menu rework | MainMenu -> CharacterSelect -> StageSelect -> RunBriefingScreen -> Arena still works |
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

## Upgrade Slot Limits

| # | Test | Expected |
|---|------|----------|
| 1 | Pick 4 different Attack upgrade lines | A 5th new Attack line no longer appears, but already selected non-maxed Attack lines can still appear |
| 2 | Pick 4 different Passive upgrade lines | A 5th new Passive line no longer appears, but already selected non-maxed Passive lines can still appear |
| 3 | Pick 4 different Active upgrade lines | A 5th new Active line no longer appears, but already selected non-maxed Active lines can still appear |
| 4 | Fill all 12 slots | LevelUpScreen offers only already selected, non-maxed upgrade lines |
| 5 | Open LevelUpScreen before and after slot limits are reached | Options show compact Attack / Passive / Active slot markers with category usage |
| 6 | Enable Debug Mode after selecting lines | DebugStatsOverlay shows attack/passive/active selected counts, limits, and selected ids |
| 7 | Pick repeated levels of an already selected line | Slot count for that category does not increase |
| 8 | Restart the run | Upgrade slot state resets to 0/4 for Attack, Passive, and Active |
| 9 | Pick passive, autoattack, and active ability upgrades after slot filtering | Passive visuals/effects, autoattack upgrades, active ability upgrades, and hero-flavored text still work |
| 10 | Inspect diff/save behavior | No hero-specific upgrade rewrites, Build Evolution, saves, meta economy, rewards, stages, enemies, boss flow, or objective flow changes |

---

## Build Slots Overview Window

| # | Test | Expected |
|---|------|----------|
| 1 | Start a run on desktop | Pause and Build buttons are visible at top-right; Build sits under Pause and does not overlap HUD/objective text |
| 2 | Start a run with touch or forced mobile controls | Build remains under Pause and does not overlap joystick, dash, or ability buttons |
| 3 | Press Build at run start | Build Slots window opens, gameplay pauses, and Attack / Passive / Active each show 0 / 4 with 4 Empty rows |
| 4 | Close the Build Slots window | Window hides and gameplay resumes when no other modal is open |
| 5 | Take an Attack upgrade, then open Build | Attack shows 1 / 4 and the selected upgrade title with current/max level |
| 6 | Take a Passive upgrade, then open Build | Passive shows 1 / 4 and the selected passive title with current/max level |
| 7 | Take an Active upgrade, then open Build | Active shows 1 / 4 and the selected active title with current/max level |
| 8 | Level an already selected upgrade line | The same row level updates; no extra row is added |
| 9 | Fill a category | That category shows 4 / 4 with four filled rows |
| 10 | Try Build while PauseMenu, Settings, Help, ConfirmDialog, LevelUpScreen, EvolutionRewardScreen, VictoryScreen, or GameOverScreen is open | Build window does not open over the blocking modal |
| 11 | Restart after selecting upgrades | Fresh run Build Slots window resets to 0 / 4 for Attack, Passive, and Active |
| 12 | Inspect diff/save behavior | No slot rule, upgrade balance, passive behavior, hero kit, primary weapon, stage, enemy, reward, save, meta economy, boss flow, objective flow, or Build Evolution changes |

---

## Passive Ability System

| # | Test | Expected |
|---|------|----------|
| 1 | Trigger several level-ups with F1/F2 while Debug Mode is ON | Passive options can appear in the normal LevelUpScreen pool with a `PASSIVE` marker |
| 2 | Pick `Orbit Shields` | Shield charges appear through PlayerBuffManager/HUD and visible orbiting shield indicators appear around the player |
| 3 | Take enemy contact damage with a shield active | HP does not drop, `SHIELD BLOCK` appears, and the orbiting shield indicator count decreases |
| 4 | Wait after a shield is consumed | Orbit Shields regenerates charges over time up to its current passive cap and the visual indicator returns |
| 5 | Pick `Storm Relay`, then stand near enemies | Nearby valid enemies take automatic periodic lightning damage with a visible arc, `STORM` status, and damage text |
| 6 | Pick `Guardian Drone`, then stand near enemies | A drone indicator orbits the player and periodically hits enemies with a visible arc, `DRONE` status, and damage text |
| 7 | Pick `Magnet Core` | XP gems and powerup pickups start magneting from farther away via runtime pickup radius bonus; a magnet pulse/status appears on upgrade |
| 8 | Pick the same passive again | Passive level increases and DebugStatsOverlay shows the higher level |
| 9 | Pick old weapon and active ability upgrades | Existing autoattack, active ability, synergy, and hero-flavored upgrade effects still apply |
| 10 | Open LevelUpScreen and choose any passive | The tree pauses for selection and resumes after the choice as before |
| 11 | Restart or quit after selecting passives | Fresh run has no selected passive ids/levels/timers, shield/drone visuals, or stale pickup radius bonus |
| 12 | Inspect diff/save behavior | No meta save, settings, rewards, stage objectives, boss flow, enemy roles, hero kits, primary weapon identity, slot limits, or Build Evolution changes |

## Passive Ability Runtime Verification

| # | Test | Expected |
|---|------|----------|
| 1 | Enable Debug Mode after selecting passives | DebugStatsOverlay shows selected passive ids/levels, Storm Relay timer, Guardian Drone timer, Orbit Shield charges/max, Magnet Core bonus, and last passive event |
| 2 | Select/upgrade any passive | Passive state appears in `get_passive_state()` via DebugStatsOverlay without enabling verbose console logs |
| 3 | Let Storm Relay tick with no enemies nearby | It retries soon; no crash, no stuck timer, and the next nearby enemy is struck |
| 4 | Let Guardian Drone tick with no enemies nearby | It retries soon; no crash, no stuck timer, and the next nearby enemy is struck |
| 5 | End the run by victory, defeat, restart, or quit | Passive visuals and runtime state are cleaned with the Arena transition |

---

## Ability & Build Synergy v4

| # | Test | Expected |
|---|------|----------|
| 1 | Pick **Aftershock Zone**, then cast slot 1 | Initial slot 1 damage happens immediately; a delayed aftershock damages enemies at the original cast position; aftershock feedback ring appears |
| 2 | Pick **Double Pulse**, then cast slot 2 | Initial line hit fires immediately; a delayed weaker second hit fires from the original origin/direction |
| 3 | Pick **Seismic Echo**, then cast slot 3 | Initial close burst fires immediately; delayed second wave damages enemies at the original cast position |
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

## Character Select Hero Detail Cards

| # | Test | Expected |
|---|------|----------|
| 1 | Open CharacterSelect from MainMenu | Three hero cards appear in the left panel with display name, playstyle, and compact state markers |
| 2 | Select Solar Guardian | Detail card shows Solar Guardian, skyborne subtitle, description, Solar Burst / Solar Beam / Aerial Impact, strengths, and Training summary |
| 3 | Select Night Tactician | Detail card shows Night Tactician, gadget subtitle, description, Smoke Charge / Grapnel Shot / Shock Trap, strengths, and Training summary |
| 4 | Select Fury Vanguard | Detail card shows Fury Vanguard, rage bruiser subtitle, description, Rage Burst / Crushing Leap / Titan Slam, strengths, and Training summary |
| 5 | Return to CharacterSelect after a remembered hero exists | Remembered hero preselects and the matching card shows a compact Last marker |
| 6 | Test a locked hero configuration | Locked card shows compact locked state, selected detail is readable, and Start Run is disabled |
| 7 | Inspect Training summary | Summary is read-only, shows total levels and strongest upgraded stat when available, and does not purchase or mutate Training |
| 8 | Press Start Run | Existing MainMenu -> CharacterSelect -> StageSelect -> RunBriefingScreen/Arena flow remains stable |
| 9 | Press Back | Returns to MainMenu without changing hero stats, Training, saves, rewards, stage values, enemy values, or persistence |
| 10 | Inspect at 16:9 landscape | Hero cards and detail sections fit without text overlap |
| 11 | Select each hero with the window at 16:9 landscape | Detail content remains bounded inside the right panel and Back / Start Run stay visible |
| 12 | Add enough detail text or Training levels to exceed the right panel height | Detail panel scrolls vertically; mouse wheel/touchpad scrolling works; no horizontal scrolling is needed |

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

## Hero Rework Integration Polish

| # | Test | Expected |
|---|------|----------|
| 1 | Open CharacterSelect | Solar Guardian, Night Tactician, and Fury Vanguard names, subtitles, role text, and starting modifiers fit without overlap |
| 2 | Select Solar Guardian | Ability details show Solar Burst, Solar Beam, and Aerial Impact |
| 3 | Select Night Tactician | Ability details show Smoke Charge, Grapnel Shot, and Shock Trap |
| 4 | Select Fury Vanguard | Ability details show Rage Burst, Crushing Leap, and Titan Slam |
| 5 | Start each hero and inspect GameHUD | Cooldown labels use the selected hero's short ability names and update Ready/cooldown states |
| 6 | Enable mobile controls for each hero | Mobile ability buttons use the selected hero's short ability names and still emit slots 1/2/3 |
| 7 | Cast all 3 abilities for each hero | Existing ability ids cast correctly, damage enemies, and update cooldowns |
| 8 | Enable DebugStatsOverlay for each hero | Ability stat rows use hero-specific display names while still showing damage/radius/cooldown values |
| 9 | Press F7 with Debug Mode enabled | Debug ability logs include hero-specific display names and stable internal ids |
| 10 | Buy Training for Guardian, then run Solar Guardian | Only Guardian Training affects the run |
| 11 | Buy Training for Blaster, then run Night Tactician | Only Blaster Training affects the run |
| 12 | Buy Training for Vanguard, then run Fury Vanguard | Only Vanguard Training affects the run |
| 13 | Restart a run after choosing each hero/stage pair | Same hero, same stage, and same hero-specific Training remain active |
| 14 | Return to MainMenu, CharacterSelect, StageSelect, RunBriefingScreen, Settings, Help, Pause, Victory/GameOver, and PostRunRewards | Existing flow remains unchanged |
| 15 | Inspect diff | No balance values, enemy values, stage values, rewards, meta economy, save format, persistence, or arena hazards were changed |
| 16 | Inspect changed text | No licensed superhero names or protected character identities are used |

---

## Hero-Specific Upgrade Flavor

| # | Test | Expected |
|---|------|----------|
| 1 | Start a Solar Guardian run and trigger LevelUpScreen | Upgrade titles/descriptions use solar/radiant/aerial wording where flavored |
| 2 | Start a Night Tactician run and trigger LevelUpScreen | Upgrade titles/descriptions use gadget/precision/trap/tactical wording where flavored |
| 3 | Start a Fury Vanguard run and trigger LevelUpScreen | Upgrade titles/descriptions use rage/bruiser/impact/slam wording where flavored |
| 4 | Inspect ability upgrades for each hero | Slot 1/2/3 upgrade text uses Solar Burst/Smoke Charge/Rage Burst, Solar Beam/Grapnel Shot/Crushing Leap, and Aerial Impact/Shock Trap/Titan Slam as appropriate |
| 5 | Select any flavored upgrade | LevelUpScreen emits the original upgrade id and the original effect applies |
| 6 | Pick synergy and build-defining upgrades | Rarity, archetype, synergy/build-defining markers, prerequisites, and build tracking still work |
| 7 | Inspect diff | No upgrade effects, weights, rarity, max levels, prerequisites, archetype points, synergies, hero stats, enemies, stages, rewards, saves, or persistence changed |

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
| 6 | Confirm a stage | RunBriefingScreen opens with selected hero/stage summary |
| 6a | Press Start Run from RunBriefingScreen | Arena starts with the correct background colors and stage name in HUD |
| 7 | HUD during run | "Stage: City Rooftop" label visible in RunPanel |
| 8 | Victory/GameOver screen | "Stage: City Rooftop" row visible below hero name |
| 9 | Restart from VictoryScreen | Same hero AND same stage; StageSelect does not re-open |
| 10 | Quit to MainMenu | Both hero and stage selection are cleared |
| 11 | Start again from MainMenu | Goes through CharacterSelect → StageSelect → RunBriefingScreen before starting run |
| 12 | Select Neon Lab | Background is visually different from City Rooftop |
| 13 | Select Wasteland Gate | Background is visually different from Neon Lab |

---

## Stage Select Polish

| # | Test | Expected |
|---|------|----------|
| 1 | Open StageSelect after confirming a hero | Three stage cards appear with display name, difficulty, and threat identity line |
| 2 | Return to StageSelect after a remembered stage exists | The remembered stage preselects and the matching card shows a compact Last marker |
| 3 | Select City Rooftop | Detail panel shows name, subtitle, Normal difficulty, balanced threat summary, Titan Guardian, and 10:00 objective |
| 4 | Select Neon Lab | Detail panel shows ranged support pressure, Prism Overlord, recommended mobility/line-control text, and 10:00 objective |
| 5 | Select Wasteland Gate | Detail panel shows swarm / exploder pressure, Molten Colossus, durable/area-control recommendation, and 10:00 objective |
| 6 | Resize to 16:9 landscape or add long detail text | Detail content stays inside the right ScrollContainer; Back and Start Run remain visible |
| 7 | Scroll the selected stage details | Vertical scrolling works when content exceeds the panel; horizontal scrolling is not needed |
| 8 | Press Back | Returns to CharacterSelect exactly as before |
| 9 | Press Start Run | Emits the original selected stage id and opens RunBriefingScreen normally |
| 10 | Restart from Victory/GameOver | Same hero and same stage restart without reopening StageSelect |
| 11 | Inspect stage data diff | `run_settings`, `event_profile`, `final_boss_id`, enemy values, rewards, persistence, and arena hazards are unchanged |

---

## Run Briefing Screen

| # | Test | Expected |
|---|------|----------|
| 1 | MainMenu -> CharacterSelect -> StageSelect -> confirm a stage | RunBriefingScreen opens before Arena |
| 2 | Inspect hero block | Shows selected hero display name, subtitle/playstyle, and correct hero ability names |
| 3 | Inspect Training block | Shows selected hero total Training levels and strongest upgraded Training stat when available |
| 4 | Inspect stage block | Shows selected stage display name and difficulty |
| 5 | Inspect objective block | Shows `stage_goal` or default 10:00 objective without changing run settings |
| 6 | Inspect final boss block | Shows formatted final boss name and boss preview text |
| 7 | Press Back | Returns to StageSelect with the same selected/remembered stage flow intact |
| 8 | Press Start Run | Starts Arena with the selected hero and selected stage |
| 9 | Restart from Victory/GameOver | Restarts current hero/stage directly without showing RunBriefingScreen |
| 10 | Quit to MainMenu after a run | Existing reward/menu flow remains unchanged |
| 11 | Inspect Training/meta data after opening briefing | Briefing did not purchase, mutate, save, or reset Training/meta data |
| 12 | Inspect git diff | No gameplay balance, stage settings, enemy values, rewards, upgrade values, persistence, or arena hazards changed |

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
| 5 | Abilities are on cooldown | J/K/L labels show hero-specific cooldown time in gray; e.g. `K  Grapnel: 3.4s` |
| 6 | Ability cooldown expires | Label turns green and shows `Ready`; e.g. `J  Burst: Ready` |
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
| 14 | Slot 1 ability fires | Brief screen shake; ring feedback visible |
| 15 | Slot 3 ability fires | Stronger brief screen shake; ring feedback visible |
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

---

## Miniboss + Final Boss Encounter Rework

### Miniboss (must remain normal-wave pressure, no arena)

| # | Test | Expected |
|---|------|----------|
| 1 | Press **F5** with Debug Mode ON | Miniboss spawns; normal enemies continue spawning around it; no wave stop |
| 2 | Observe enemy container while miniboss is alive | Regular spawn timer and wave director continue; no enemies are cleared |
| 3 | MinibossHealthBar during miniboss fight | Shows miniboss name and HP; hides on death |
| 4 | Miniboss dies | "Miniboss Defeated!" announcement; evolution reward screen opens if evolutions available; guaranteed powerup drops |
| 5 | Inspect player bounds during miniboss | Player is **not** restricted to a smaller arena; full arena bounds remain |
| 6 | Inspect diff | No enemy clearing, no arena creation, no spawn stopping for miniboss |

### Final Boss Encounter (separate arena duel)

| # | Test | Expected |
|---|------|----------|
| 1 | Set `use_debug_run_duration=true, debug_target_run_time=60` | Target time fires at 60 s |
| 2 | Reach target time | Screen shake; "Final Boss Arena!" announcement (not a direct boss spawn in the open field) |
| 3 | Observe enemy container immediately after trigger | All non-final-boss enemies disappear (queue_freed) without XP or powerup drops |
| 4 | Observe spawn timer and wave timer | Both stop; no new regular enemies or wave packages spawn |
| 5 | Observe EventDirector | No new elite, miniboss, or timed-modifier events fire |
| 6 | Observe player bounds | Player is clamped to a ~1200×900 area centered where they were standing |
| 7 | Observe camera | Camera limits match the smaller boss arena |
| 8 | Observe world space | Orange Line2D rectangle outlines the boss arena boundary |
| 9 | Boundary collision check | Player and boss walk through the boundary Line2D freely; it deals **no damage** |
| 10 | Boss spawn position | Final boss appears near the center of the boss arena, not off-screen |
| 11 | BossHealthBar | Shows "FINAL BOSS", boss display name, HP bar, and HP text |
| 12 | HUD final boss label | `Final Boss: <Name>` shown in RunPanel |
| 13 | Boss at 50% HP | "Final Boss Enraged!" announcement; phase 2 patterns activate |
| 14 | Hero abilities inside arena | J / K / L still cast and deal damage; mobile controls work |
| 15 | Level-up during boss fight | Level-up pauses tree; upgrades apply; game resumes and boss fight continues |
| 16 | XP gems and powerup pickups on the ground | Still collectible during boss fight |
| 17 | Enemy projectiles already in flight when encounter starts | Expire naturally; no crash |
| 18 | Final boss defeated | "Final Boss Defeated!" announcement; BossHealthBar hides; boundary Line2D removed; VictoryScreen appears |
| 19 | Player dies during boss fight | Game over screen shows; boundary visible under game over overlay (harmless) |
| 20 | Restart from game over during boss fight | Boundary is cleared before restart; fresh Arena starts with full bounds and normal spawning |
| 21 | Quit to menu from game over during boss fight | Boundary cleared; returns to MainMenu safely |
| 22 | Restart from VictoryScreen after boss kill | Boundary already cleared on boss death; fresh Arena starts correctly |
| 23 | Open PauseMenu during boss fight | Pause works; confirm Restart or Main Menu also clears boundary |
| 24 | Debug `Arena.debug_spawn_final_boss()` from remote console | Boss spawns using ring-based position (no arena setup, debug only); no crash |
| 25 | Inspect diff | No arena hazards, no damaging boundaries, no hero kit changes, no reward changes |

---

## Enemy Roles & Wave Director 2.0

| # | Test | Expected |
|---|------|----------|
| 1 | Start City Rooftop and play for 3–4 minutes | Waves appear as occasional bursts (every ~10–14 s) of 2–4 same-role enemies alongside the steady individual spawn stream |
| 2 | Start Neon Lab and watch enemy mix | More shooter and support packages than City Rooftop; `WAVE_PACKAGE: id=shooter_screen` and `support_pair` appear in console when `spawn_debug_logging` is on |
| 3 | Start Wasteland Gate and watch enemy mix | More swarm and exploder packages; `WAVE_PACKAGE: id=swarm_rush` and `exploder_pressure` appear in console |
| 4 | Enable Debug Mode (F12) and check DebugStatsOverlay Spawner section | Shows `Profile: <stage_profile>`, `MaxAlive: N`, `Interval: X.XX`, `WaveEvery: Xs`, and `Last pkg: <id>` |
| 5 | At run start (0–30 s) | Only `early_grunts` package fires; no runners/tanks/shooters in packages yet |
| 6 | At ~75 s | `runner_pack`, `bruiser_wall`, `shooter_screen` packages begin to appear |
| 7 | At ~150 s | `swarm_rush` and `exploder_pressure` packages appear (both stage-profile dependent) |
| 8 | At ~210 s | `support_pair` package appears |
| 9 | At ~240 s | `mixed_late_wave` (runner/tank/shooter mix) can appear |
| 10 | Watch enemy count while packages spawn | Enemy count does not exceed `max_alive_enemies` cap during or after a package spawn |
| 11 | Play to late game (300 s+) | Packages sometimes spawn 1 extra enemy (late-game size bonus) but still within cap |
| 12 | Enable `spawn_debug_logging` in Inspector | Console shows `WAVE_PACKAGE: id=... role=... alive=N/M` each time a package fires; `SPAWN: variant=...` lines still appear for individual spawns |
| 13 | Press F5 to spawn miniboss during active run | Miniboss spawns normally alongside regular enemy pressure; wave packages continue in background |
| 14 | Press F4 to spawn elite | Elite spawns normally; wave packages unaffected |
| 15 | Let final boss spawn (debug or natural) | Final boss spawns normally; wave packages continue (run is still active); VictoryScreen shows after boss death |
| 16 | Use J/K/L abilities during a wave package | Hero abilities still work and hit package enemies normally |
| 17 | Open level-up screen during run | Tree pauses; wave timer pauses automatically; packages resume after level-up |
| 18 | Inspect diff | Enemy stats, XP values, behavior_ids, hero kits, upgrade effects, reward formulas, save format, and arena hazards are unchanged |

---

## Stage Objectives & Win Conditions

### StageSelect & RunBriefingScreen objective display

| # | Test | Expected |
|---|------|----------|
| 1 | Open StageSelect and select City Rooftop | Run Objective shows `[Survival]` with the 10:00 survive + boss goal |
| 2 | Select Neon Lab in StageSelect | Run Objective shows `[Defense]` with "Defend the Lab Reactor for 10:00" text |
| 3 | Select Wasteland Gate in StageSelect | Run Objective shows `[Destroy Structures]` with "Destroy all 3 Dark Portals" text |
| 4 | Confirm Neon Lab and open RunBriefingScreen | Objective block shows `[Defense]` tag and the Reactor defense goal |
| 5 | Confirm Wasteland Gate and open RunBriefingScreen | Objective block shows `[Destroy Structures]` tag and the portal destruction goal |
| 6 | Inspect diff | No stage_id, event_profile, final_boss_id, run_settings, enemy values, rewards, or persistence changed |

---

### City Rooftop (Survival — behavior unchanged)

| # | Test | Expected |
|---|------|----------|
| 1 | Start City Rooftop | No objective entity spawns; HUD still shows "Survive: 00:00 / 10:00" |
| 2 | Survive to 10:00 | Final boss triggers normally as before |
| 3 | Player dies | GameOverScreen shows; no objective cleanup errors in console |
| 4 | Restart from game over or victory | Fresh run starts correctly with no leftover objective nodes |

---

### Neon Lab (Defense — Lab Reactor)

| # | Test | Expected |
|---|------|----------|
| 1 | Start Neon Lab | "Defend the Lab Reactor!" announcement appears a few seconds in; a cyan-blue structure is visible near the center-top of the arena |
| 2 | Inspect HUD | Objective area shows "Lab Reactor: 300 / 300 HP" in a healthy color |
| 3 | Let enemies reach the Reactor | Reactor HP decreases at ~15 damage/enemy/second; HUD HP number updates live |
| 4 | Reactor HP drops to ~30% | HUD HP label turns warning/danger color |
| 5 | Reactor HP reaches 0 | "Reactor Destroyed!" announcement appears; GameOverScreen shows with defeat summary |
| 6 | Survive with Reactor alive to 10:00 | Final boss triggers normally; Reactor remains on screen |
| 7 | Defeat final boss after 10:00 with Reactor alive | VictoryScreen shows; run ends in victory |
| 8 | Player dies with Reactor still alive | GameOverScreen shows (player death, not reactor failure) |
| 9 | Reactor hits 0 after boss phase has already started | Boss phase guard prevents double-trigger; game over fires once |
| 10 | Restart after reactor defeat | Fresh Neon Lab run starts with a new Reactor at full HP; no leftover nodes |
| 11 | Quit to menu from reactor defeat GameOverScreen | Returns to MainMenu safely; no leftover objective nodes |
| 12 | Quit via PauseMenu ConfirmDialog during active Neon Lab run | Reactor is cleaned up before scene transition; no console errors |
| 13 | Confirm the Reactor has no collision with the player | Player walks through the Reactor structure freely; it deals no damage |

---

### Wasteland Gate (Destroy Structures — Dark Portals)

| # | Test | Expected |
|---|------|----------|
| 1 | Start Wasteland Gate | "Destroy the Dark Portals!" announcement appears; 3 dark purple octagonal structures visible at spread positions around the arena |
| 2 | Inspect HUD | Objective area shows "Portals: 0 / 3" |
| 3 | Attack a portal with any hero | Portal HP bar decreases; floating damage numbers appear |
| 4 | Solar Guardian / Night Tactician projectiles hit portal | Projectiles connect and deal damage; portal HP decreases |
| 5 | Fury Vanguard shockwave fires near portal | Shockwave deals direct damage to the portal |
| 6 | Destroy one portal | Portal disappears; HUD updates to "Portals: 1 / 3"; "Dark Portal Destroyed! (1/3)" announcement shows |
| 7 | Destroy second portal | HUD updates to "Portals: 2 / 3"; announcement shows |
| 8 | Destroy third portal | HUD updates to "Portals: ALL DESTROYED"; "All Portals Destroyed! Final Boss incoming…" announcement; final boss triggers immediately |
| 9 | Confirm final boss triggers before 10:00 | Boss spawns without waiting for the timer; BossHealthBar appears; boss arena activates |
| 10 | Reach 10:00 naturally with portals all destroyed | Timer does NOT trigger a second boss spawn; `mark_boss_phase_triggered()` prevented double-trigger |
| 11 | Reach 10:00 with some portals remaining | Timer does NOT trigger the boss phase; only portal destruction triggers it |
| 12 | Defeat final boss after portal destruction | VictoryScreen shows; run ends in victory |
| 13 | Player dies with portals remaining | GameOverScreen shows with defeat summary |
| 14 | Player dies after all portals destroyed but during boss fight | GameOverScreen shows normally |
| 15 | Restart after a portal-destroy run | Fresh Wasteland Gate run starts with 3 new portals; no leftover nodes |
| 16 | Quit to menu from GameOverScreen mid-run | Returns to MainMenu safely; no leftover portal nodes |
| 17 | Quit via PauseMenu ConfirmDialog | All portals are cleaned up before scene transition |
| 18 | Attack a portal when enemies are nearby | Enemies are not affected by portal attack; only portal takes damage |
| 19 | Portals do not chase or shoot | Portals are static structures; they deal no damage to the player |

---

### Objective Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Complete all 3 stages back-to-back (City / Neon / Wasteland) | Each stage resets cleanly with no leftover objective nodes from the previous stage |
| 2 | Check DebugStatsOverlay during any objective run | No new objective state is shown in the debug overlay (objectives are not wired to DebugStatsOverlay) |
| 3 | Inspect diff | No hero kits, upgrade effects, reward formulas, enemy stats, XP values, save format, meta economy, or Build Evolution added
