# Gameplay Validation Checklist

Manual test cases for the debug & balance validation pass.
Run these before adding new gameplay systems.

---

## Character Base Stat Training

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training screen -> Training tab -> Solar Guardian | Guardian list includes `Radiant Vitality`, `Solar Might`, and `Sunforged Guard`; rows show current/next readable effects |
| 2 | Buy `Radiant Vitality`, then start a Solar Guardian run | Solar Guardian max/current HP increases by +5 per level after hero base stats apply |
| 3 | Start or switch to Night Tactician without Blaster HP Training | Night Tactician does not receive Guardian HP Training |
| 4 | Buy `Tactical Precision`, then start Night Tactician | Night Tactician autoattack and active damage values increase by +1 per level |
| 5 | Start Fury Vanguard after Blaster damage Training | Fury Vanguard does not receive Blaster Base Damage Training |
| 6 | Buy `Pain Tolerance`, then start Fury Vanguard and take damage | Incoming player damage is reduced by 1% per level; total Training damage reduction is capped at 50% |
| 7 | Call `MetaProgressionManager.debug_get_training_modifier_summary(hero_id)` | Reports purchased nodes, selected-hero aggregated modifiers, all effect modifiers, and ignored invalid saved ids |
| 8 | Buy any Training stats node | Only existing Training/progression currency changes; Gold and equipment materials do not change |
| 9 | Switch hero dropdown after purchases | Visible levels/effects update for the selected hero only |
| 10 | Regression: Equipment tab, inventory, item upgrades, Dismantle, set bonuses, Item/Loadout Power, starter pack, and post-run rewards | All continue to work unchanged |
| 11 | Inspect scope | No global Training nodes, new currencies, respec/reset, gacha/crafting/fusion/random affixes, stage/zone, hero kit, evolution, boss-flow, reward, or in-run 4/4/4 changes |

---

## Character Ability Training

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training -> Training tab -> Solar Guardian | Ability rows show ability-specific effect text: "Solar Beam Damage", "Ice Breath Slow", "Death Dash Damage" |
| 2 | Buy `Solar Ray Intensity` (e.g. level 2) -> start Solar Guardian run | `solar_beam_damage` in AbilityManager increases by +2; Frost Breath and Death Dash are unchanged |
| 3 | Start Night Tactician run after Solar Guardian ability Training | Night Tactician does not receive Guardian ability Training |
| 4 | Buy `Trap Engineering` (level 1) -> start Night Tactician | `explosive_trap_damage` increases by +1; Smoke Screen and Hook are unchanged |
| 5 | Buy `Hook Impact` (level 1) -> start Night Tactician | `grappling_hook_damage` increases by +1 |
| 6 | Buy `Smoke Density` (level 2) -> start Night Tactician | `smoke_screen_damage_reduction` increases by +0.02; capped at 0.75 |
| 7 | Buy `Rage Wave Force` (level 1) -> start Fury Vanguard | `rage_wave_damage` increases by +1; Mighty Clap and Rage Leap unchanged |
| 8 | Buy `Power Clap Impact` (level 1) -> start Fury Vanguard | `mighty_clap_knockback_force` increases by 1% (multiplied by 1.02); stays positive |
| 9 | Buy `Rage Jump Landing` (level 1) -> start Fury Vanguard | `rage_leap_damage` increases by +1 |
| 10 | Call `debug_get_training_ability_summary("guardian")` | Reports purchased ability nodes, aggregated modifiers by target, and no ignored invalid nodes |
| 11 | Check base stat Training still works after buying ability Training | max_health, base_damage, damage_reduction bonuses still apply; no double-counting |
| 12 | Training rows in UI for ability nodes | Show "Current: +2 Solar Beam Damage. Next: +3 Solar Beam Damage. Applies to selected hero only." |
| 13 | Purchase ability Training node | Only Training currency changes; Gold, materials, equipment do not change |
| 14 | Regression: equipment tab, inventory, set bonuses, item upgrades, dismantle, post-run rewards | All continue to work unchanged |
| 15 | Inspect scope | No passive Training, respec/reset, new currencies, gacha/crafting/fusion, hero kit changes, or full Training UI rework |

---

## Character Training Data Foundation

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training screen -> Training tab | A flat list of Training nodes appears for the selected hero only |
| 2 | Select Solar Guardian | Rows include Guardian nodes such as `guardian_radiant_vitality`, `guardian_beam_focus`, and `guardian_solar_energy_flow`; Blaster/Vanguard nodes do not appear |
| 3 | Buy a Guardian node | Existing Training currency is spent; only that Guardian node level increases |
| 4 | Switch to Night Tactician | Guardian nodes disappear; Blaster nodes such as `blaster_rocket_calibration` and `blaster_mark_exploitation` appear |
| 5 | Buy a Blaster node | Only the Blaster node level increases; Guardian levels remain unchanged |
| 6 | Switch back to Solar Guardian | Guardian progress is still preserved under Guardian |
| 7 | Select Fury Vanguard | Vanguard nodes appear for all six categories: stats, autoattack, ability_1, ability_2, ability_3, passive |
| 8 | Call `MetaProgressionManager.debug_get_character_training_summary()` | Reports 24 total nodes, nodes by hero/category, no duplicate ids, no missing hero ids, and saved levels by hero |
| 9 | Load an old save with unknown Training ids | UI does not crash; unknown ids stay inert and do not appear in new purchase lists |
| 10 | Try to buy a node owned by another hero through console | Purchase returns false and does not spend currency |
| 11 | Equipment tab after Training purchases | Shared equipment, inventory, Gold/material upgrades, and set bonuses still work unchanged |
| 12 | Inspect scope | No inventory, item upgrade economy, set bonus, combat balance, gacha/crafting/fusion/random affix, respec/reset, stage/zone, or deep ability-effect integration changes |

---

## Equipment Set Bonus Effects

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training screen -> Equipment tab with no equipped items | Set Summary shows `Sets: none`; no set bonus modifiers are active |
| 2 | Equip 1 Storm Set item | Set Summary shows Storm Set 1/6 and next 2-piece bonus |
| 3 | Equip 2 Storm Set items | Set Summary shows active 2-piece Move Speed bonus; `get_set_bonus_stat_modifiers()` includes `move_speed: 0.05` |
| 4 | Equip 4 Storm Set items if available/test-created | Set Summary shows active 2-piece and 4-piece bonuses; modifiers include move speed and ability cooldown |
| 5 | Equip 6 Storm Set items if available/test-created | Set Summary shows active 2/4/6 bonuses and `Next: Full set active` |
| 6 | Unequip a Storm Set item | Set Summary count drops and removed threshold modifiers no longer appear |
| 7 | Select an unequipped inventory item from a set | Item popup shows set progress and next bonus, but gameplay note remains equip-to-apply |
| 8 | Start a run with active set bonuses | `get_equipment_stat_modifiers_for_hero(hero_id)` includes item modifiers plus active set bonuses |
| 9 | Switch selected hero and start a run | Same global set bonuses apply to the new hero |
| 10 | Inspect scope | No reward chance/quantity, item upgrade economy, stage/zone, gacha/drop/crafting/affix, hero kit, evolution, boss-flow, Training upgrade, or in-run 4/4/4 rule changes |

---

## Equipment Set UI Cleanup

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training -> Equipment | No item action popup appears automatically |
| 2 | Open Training with unclaimed starter pack | Starter Pack popup may appear; item action popup remains closed |
| 3 | Inspect left Equipment panel | No long set summary block; square equipment slots and centered character holder remain clean |
| 4 | Switch tabs or hero, then return to Equipment | Inventory refreshes without opening item action popup |
| 5 | Click an occupied inventory cell | Item action popup opens and shows only that item's set name, equipped pieces, active bonus, and next bonus |
| 6 | Click an empty inventory cell | No crash; item action popup closes or stays closed |
| 7 | Click an occupied equipped slot | Slot popup shows that item's set name, equipped pieces, active bonus, and next bonus |
| 8 | Click an empty equipped slot | Slot popup shows empty-slot message with no irrelevant set info |
| 9 | Equip/unequip a set item | Popup set counts/bonuses update; set bonus modifiers still aggregate from global equipped slots |
| 10 | Inspect scope | No set bonus value, item stat, reward/economy, stage/zone, gacha/drop/crafting/affix, hero kit, evolution, boss-flow, Training upgrade, or in-run 4/4/4 rule changes |

---

## Equipment Item Template System

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training screen → Equipment tab | No crash; equipped gear panel and inventory grid render without errors |
| 2 | Inventory grid after fresh start | All cells empty (no items granted automatically) |
| 3 | `MetaProgressionManager.debug_get_item_template_summary()` from debug console | Returns `total_templates: 13`, `by_slot` with 2 per slot (artifact has 3), `by_rarity` with 8 common + 4 uncommon + 1 rare, `max_item_level: 10` |
| 4 | Old save with unknown template_ids | On load, pruned items are removed; valid items are preserved; currency is unchanged |
| 5 | Old save with static hero items | After `inventory_static_items_cleared` migration, inventory is empty; currency unchanged |
| 6 | `get_equipment_definitions("guardian")` | Returns 13 items; each has `equipment_id`, `display_name`, `slot_id`, `rarity`, `stat_bonus_type`, `max_level: 10` |
| 7 | `get_equipment_definition("guardian", "apex_artifact_rare")` | Returns template with rarity `rare`, slot `artifact`, stat `ability_damage`, `per_level 0.025` |
| 8 | `get_alt_item_template("power_core_common")` | Returns same result as `get_equipment_definition("", "power_core_common")` (routes to provider) |
| 9 | Equip a core item on any hero | Succeeds regardless of which hero; no hero_id restriction on template |
| 10 | Upgrade an inventory item to level 10 | Upgrade button shows MAX; no further upgrade allowed |
| 11 | No gacha / starter grants / random loot | Nothing in UI or code grants items automatically; no random affixes or item drops |
| 12 | Start run with items equipped | MetaApplier applies supported stats (attack_damage, max_health, move_speed, etc.); DebugStatsOverlay shows non-zero equipment modifier values |
| 13 | `low_health_damage` stat from Fury Artifact | Aggregated in equipment modifiers; does not mutate any gameplay property (no MetaApplier handler for it yet) |

---

## Training Equipment Polish / Inventory Reset

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training screen | Hero dropdown visible in the nav row between Training tab and spacer |
| 2 | Hero dropdown items | Lists all available heroes (Solar Guardian, Night Tactician, Fury Vanguard) |
| 3 | Switch hero via dropdown | Equipment and Training tabs refresh for the new hero; currency label stays |
| 4 | Switch hero while on Training tab | Active tab stays Training; hero label in training updates |
| 5 | Inventory grid after migration | All cells show Empty (no items populated) |
| 6 | Equipped slots after migration | All six slots show "Equipment" / no item name / Level 0/0 |
| 7 | Equipment stat modifiers with no gear | Run starts normally; no crash; all equipment modifiers zero |
| 8 | Click an empty equipped slot | Popup opens; title shows slot name; detail says "No item equipped in this slot."; Unequip button disabled |
| 9 | Manually equip an item, then click its slot | Popup opens; shows item name, level, stat bonus; Unequip enabled |
| 10 | Click Unequip in popup | Popup closes; slot shows empty state; inventory grid shows item as unequipped |
| 11 | After Unequip — item in inventory | Inventory grid still shows the item cell (item not deleted, just unequipped) |
| 12 | Inventory grid column count | Always 5 columns |
| 13 | Equipped Gear panel width | Wider than before (580 px minimum) |
| 14 | Inventory panel width | Narrower than before (410 px minimum); no large empty gap after last column |
| 15 | Start run with no gear equipped | Arena loads; no crash; equipment modifiers are all 0 in DebugStatsOverlay |
| 16 | Training upgrades with no gear | Buy/upgrade buttons work normally; no interference |
| 17 | Currency label updates | Reflects current currency in nav row after any purchase |
| 18 | Main Menu button | Works from both Equipment and Training tabs |
| 19 | No gacha / loot / drops / affixes | Nothing in UI suggests random loot, item drops, gacha pulls, or crafting |

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
| 1 | Start Solar Guardian and cast slot 1 near enemies | Solar Beam damages enemies in a forward beam and updates cooldown |
| 2 | Build Solar Energy to empowered state, then cast Solar Beam or Frost Breath | Empowered damage multiplier applies and DebugStatsOverlay shows Solar Energy / empowered state |
| 3 | Cast Death Dash near enemies | Player dashes forward with brief invulnerability and path damage |
| 4 | Start Night Tactician and cast Smoke Screen near enemies | Smoke zone appears; enemies inside are slowed and marked every 0.5s; DebugStatsOverlay shows Tactical Marks: N |
| 5 | Cast Explosive Trap near enemies, then let them walk over it | Trap triggers, explosion damages and marks all enemies in radius |
| 6 | Cast Grappling Hook near an enemy | Player dashes to the enemy, deals high damage, and marks it |
| 7 | Let autoattack fire at a marked enemy | Homing rocket pre-multiplies damage for the Tactical Mark bonus |
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
| 4 | Cast Solar Guardian abilities with and without nearby enemies | Solar Beam / Frost Breath / Death Dash show feedback; miss casts still show feedback/cooldown |
| 5 | Cast Night Tactician Explosive Trap with no enemies present | Trap places, enters cooldown, and triggers after duration with no crash |
| 6 | Cast Fury Vanguard abilities with no enemies present | Rage/status feedback appears where applicable and cooldowns update |
| 7 | Trigger LevelUpScreen, then choose any upgrade | LevelUpScreen hides and the game unpauses automatically if no other blocking modal is open |
| 8 | Open PauseMenu after the level-up resume | PauseMenu opens/closes normally and does not need to be used to unstick the run |
| 9 | Trigger EvolutionRewardScreen and choose an evolution | Evolution reward still hides and resumes normally |
| 10 | Inspect diff | No enemy, stage, reward, save, meta economy, arena hazard, primary autoattack, or Build Evolution changes |

---

## Hero Signature Kits Real Mechanics

| # | Test | Expected |
|---|------|----------|
| 1 | Solar Guardian: wait during combat | Solar Energy charges over time and empowered state starts at 100 energy |
| 2 | Solar Guardian: attack/cast while empowered | Solar Ray, Solar Beam, Frost Breath, and Death Dash deal empowered damage |
| 3 | Solar Guardian: cast Solar Beam | Forward beam damages enemies in aim direction and enters cooldown |
| 4 | Solar Guardian: cast Death Dash | Player moves in aim direction, gains brief invulnerability, and path damage lands during movement |
| 5 | Night Tactician: cast Smoke Screen near enemies | Smoke zone persists for full duration; enemies inside slowed and marked; player inside takes reduced damage |
| 6 | Night Tactician: cast Explosive Trap then let enemies walk over it | Trap triggers explosion, marks all enemies in blast radius |
| 7 | Night Tactician: cast Grappling Hook with an enemy in range | Player dashes to enemy, deals high damage, applies Tactical Mark |
| 8 | Fury Vanguard: take damage and deal ability damage | Rage rises from both sources and decays over time |
| 9 | Fury Vanguard: cast Rage Burst at low/high Rage | Damage/radius noticeably scale with current Rage |
| 10 | Fury Vanguard: cast Crushing Leap | Player moves forward with brief invulnerability; path/landing impact damage fires |
| 11 | Fury Vanguard: cast Titan Slam with Rage | Slam scales, spends Rage, and creates a delayed shockwave when Rage or second-wave support is present |
| 12 | Check DebugStatsOverlay for all heroes | Overlay shows kit id plus Solar Energy, Tactical Mark, or Rage |
| 13 | Pick Nova/Laser/Slam upgrades | Slot 1/2/3 upgrade hooks still affect the corresponding hero abilities |
| 14 | Inspect scope | No Enemy Roles, Boss Rework, Build Evolution, Stage Objectives, arena hazards, enemy/stage/reward/save/meta changes |

---

## Primary Weapon / Autoattack Rework

| # | Test | Expected |
|---|------|----------|
| 1 | Start **Solar Guardian** and let autoattack fire | Solar Ray fires a short direct beam toward the nearest enemy; no projectile is spawned |
| 2 | Start **Night Tactician** and let autoattack fire | Homing rockets track individual enemies; each rocket goes to a different target (round-robin); no pierce, no bounce |
| 3 | Start **Fury Vanguard** and stand near enemies | Close-range shockwave deals damage directly with no visible projectile; floating damage numbers appear |
| 4 | Fury Vanguard: step out of range of all enemies | Shockwave does not fire; cooldown does not tick down from a no-target state |
| 5 | Night Tactician: apply Tactical Mark, then let autoattack fire at that enemy | Homing rocket to marked target shows higher damage number than unmark equivalent |
| 6 | Pick autoattack damage upgrades | Blaster/Vanguard use generic lines; Guardian uses `solar_ray_damage` |
| 7 | Pick autoattack speed upgrades | Blaster/Vanguard use generic lines; Guardian uses `solar_ray_tick_rate` |
| 8 | Pick autoattack range upgrades | Blaster/Vanguard use generic lines; Guardian uses `solar_ray_range` |
| 9 | Pick projectile-count / multishot upgrades on Night Tactician | Homing rocket count increases; Solar Guardian and Fury Vanguard are not offered projectile-count lines |
| 10 | Pick projectile pierce / bounce / speed upgrades | Solar Guardian is not offered projectile-only pierce, bounce, or speed lines because Solar Ray is a direct beam |
| 11 | Pick `projectile_bounce` upgrade as Night Tactician | Homing rockets can bounce; Solar Guardian and Fury Vanguard direct damage are unaffected |
| 12 | Pick explosion-radius upgrades as Night Tactician | Homing rockets gain explosion radius; Solar Guardian and Fury Vanguard direct damage are unaffected |
| 13 | Enable Debug Mode (F12) | DebugStatsOverlay Weapon section shows `Primary: solar_ray`, `homing_rockets`, or `splash_melee`; range/interval and relevant weapon stats display correctly |
| 14 | Check GameHUD BuildPanel | `Weapon: Solar Ray`, `Weapon: Homing Rockets`, or `Weapon: Fury Strike` label is visible |
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

## Upgrade Grid Schema Validation

| # | Test | Expected |
|---|------|----------|
| 1 | Call `UpgradeManager.validate_upgrade_grid(false)` from a live run or remote console | Returns a Dictionary with `errors`, `warnings`, `error_count`, `warning_count`, `line_counts`, and `target_counts` |
| 2 | Inspect non-strict audit result | Shared Passive count is exactly 9/9; Guardian and Blaster attack/active counts are exactly 9/9; incomplete Fury Attack/Active target counts remain warnings only |
| 3 | Call `UpgradeManager.validate_upgrade_grid_for_hero("guardian", true)` | Returns ok with exactly 9 Guardian Attack lines and 9 Guardian Active lines |
| 4 | Call `UpgradeManager.validate_upgrade_grid_for_hero("blaster", true)` | Returns ok with exactly 9 Blaster Attack lines and 9 Blaster Active lines; no duplicates; no missing schema fields |
| 5 | Call `UpgradeManager.validate_upgrade_grid_for_hero("guardian", false)` | Returns Guardian attack/passive/active line counts without mutating upgrades |
| 6 | Call `UpgradeManager.debug_get_upgrade_grid_state()` | Returns schema warning/error counts plus current hero line counts |
| 7 | Enable Debug Mode during a run | DebugStatsOverlay shows compact grid audit warning/error counts and current hero A/P/Act line counts |
| 8 | Trigger level-up options after schema changes | LevelUpScreen still displays valid options and slot markers |
| 9 | Fill Attack / Passive / Active slots | Existing 4/4/4 slot limits still work; already selected lines can still level up |
| 10 | Open Build Slots Window after selecting upgrades | Window still reads selected line ids and displays filled rows correctly |
| 11 | Pick shared passive skills | PassiveAbilityManager applies all nine shared passive ids; no passive state is saved |
| 12 | Start runs as Solar Guardian, Night Tactician, and Fury Vanguard | Existing hero-specific upgrade filtering and kit behavior still work |
| 13 | Inspect diff/save behavior | No new EvolutionManager behavior, Overdrive UI, Fury attack/active 9-line grids, rewards, saves, stages, enemies, boss flow, or meta economy changes |

---

## Night Tactician Upgrade Grid

| # | Test | Expected |
|---|------|----------|
| 1 | Call `validate_upgrade_grid_for_hero("blaster", true)` | Returns 9 Attack lines, 9 Active lines, 0 errors, 0 duplicates |
| 2 | Start a run as Night Tactician and trigger 9 level-ups | At least `rocket_damage`, `smoke_screen_radius`, and `hook_damage` appear in level-up pool; deprecated lines (`smoke_screen_damage_reduction`, `trap_cooldown_down`, `trap_mark_bonus`, `hook_mark_bonus`) never appear |
| 3 | Pick `rocket_seek_range` | Homing rocket attack range visibly increases; DebugStatsOverlay reflects updated attack_range; `refresh_attack_range()` is called (no error in log) |
| 4 | Pick `rocket_split` | Rocket explosion radius increases and splash damage applies to enemies near impact |
| 5 | Pick `rocket_cluster_payload` | Rocket explosion damage multiplier increases; AoE damage numbers rise correspondingly |
| 6 | Pick `rocket_priority_targeting` | Tactically Marked enemies are targeted before unmarked enemies when multiple are in range; mark multiplier increases |
| 7 | Pick `trap_chain_detonation`, place two Explosive Traps near each other, trigger one | Second trap also detonates from the chain; Tactical Mark duration on hit enemies is extended; trap cooldown is shorter |
| 8 | Pick `smoke_screen_radius`, `smoke_screen_duration`, `smoke_screen_slow` | Each upgrade affects only those Smoke Screen parameters; `smoke_screen_damage_reduction` never appears in pool |
| 9 | Pick `trap_damage` and `trap_radius` | Trap detonation damage and blast radius both increase independently |
| 10 | Pick `hook_damage`, `hook_range`, `hook_cooldown_down` | Each upgrade affects only Grappling Hook damage, range, or cooldown; `hook_mark_bonus` never appears in pool |
| 11 | Inspect all blaster upgrades for schema fields | Every blaster attack and active line has `upgrade_line_id`, `source_type`, `source_skill_id`, `grid_index`, `evolution_role`; active lines also have `evolution_target_active_skill` |
| 12 | Start a Solar Guardian or Fury Vanguard run | Guardian and Vanguard grids unchanged; `rocket_*`, `trap_*`, `hook_*`, `smoke_*` lines not offered to them |
| 13 | Inspect diff/save behavior | No EvolutionManager, Overdrive UI, Fury 9-line grids, Evolution triples, rewards, saves, enemies, stages, boss flow, or meta economy changes |

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
| 1 | Trigger several level-ups with F1/F2 while Debug Mode is ON | All nine shared passive lines can appear in the normal LevelUpScreen pool with a `PASSIVE` marker |
| 2 | Pick `Orbit Shields` | Shield charges appear through PlayerBuffManager/HUD and visible orbiting shield indicators appear around the player |
| 3 | Take enemy contact damage with a shield active | HP does not drop, `SHIELD BLOCK` appears, and the orbiting shield indicator count decreases |
| 4 | Wait after a shield is consumed | Orbit Shields regenerates charges over time up to its current passive cap and the visual indicator returns |
| 5 | Pick `Storm Relay`, then stand near enemies | Nearby valid enemies take automatic periodic lightning damage with a visible arc, `STORM` status, and damage text |
| 6 | Pick `Guardian Drone`, then stand near enemies | A drone indicator orbits the player and periodically hits enemies with a visible arc, `DRONE` status, and damage text |
| 7 | Pick `Magnet Core` | XP gems and powerup pickups start magneting from farther away via runtime pickup radius bonus; a magnet pulse/status appears on upgrade |
| 8 | Pick `Chain Lightning`, then stand near multiple enemies | One target is struck, lightning bounces to nearby enemies, yellow arcs connect targets, and damage/status text appears |
| 9 | Pick `Recovery Field` after taking HP damage | A green recovery pulse appears around the player and HP restores by a small capped amount |
| 10 | Pick `Battle Focus`, then stand near enemies | A focus strike hits periodically, `battle_focus` attack-speed buff appears in DebugStatsOverlay/Buffs, and `FOCUS` status appears |
| 11 | Pick `Static Field`, then stand near enemies | Nearby enemies take periodic electric pulse damage with a visible cyan pulse ring and damage text |
| 12 | Pick `Time Dilator`, then stand near enemies | Nearby enemies receive a temporary slow modifier, a blue pulse ring appears, and `SLOW N` status appears |
| 13 | Pick the same passive again | Passive level increases and DebugStatsOverlay shows the higher level |
| 14 | Pick old weapon and active ability upgrades | Existing autoattack, active ability, synergy, and hero-flavored upgrade effects still apply |
| 15 | Open LevelUpScreen and choose any passive | The tree pauses for selection and resumes after the choice as before |
| 16 | Restart or quit after selecting passives | Fresh run has no selected passive ids/levels/timers, shield/drone visuals, focus buff, or stale pickup radius bonus |
| 17 | Inspect diff/save behavior | No meta save, settings, rewards, stage objectives, boss flow, enemy roles, hero kits, primary weapon identity, slot limits, Evolution/Overdrive, or Build Evolution changes |

## Passive Ability Runtime Verification

| # | Test | Expected |
|---|------|----------|
| 1 | Enable Debug Mode after selecting passives | DebugStatsOverlay shows selected passive ids/levels, timers for selected timed passives, Orbit Shield charges/max, Magnet Core bonus, active Battle Focus buff if present, and last passive event |
| 2 | Select/upgrade any passive | Passive state appears in `get_passive_state()` via DebugStatsOverlay without enabling verbose console logs |
| 3 | Let Storm Relay tick with no enemies nearby | It retries soon; no crash, no stuck timer, and the next nearby enemy is struck |
| 4 | Let Guardian Drone tick with no enemies nearby | It retries soon; no crash, no stuck timer, and the next nearby enemy is struck |
| 5 | Let Chain Lightning, Battle Focus, Static Field, or Time Dilator tick with no enemies nearby | Each retries soon; no crash, no stuck timer, and the next nearby enemy is affected |
| 6 | End the run by victory, defeat, restart, or quit | Passive visuals and runtime state are cleaned with the Arena transition |

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
| 2 | Select Solar Guardian | Detail card shows Solar Guardian, skyborne subtitle, description, Solar Beam / Frost Breath / Death Dash, strengths, and Training summary |
| 3 | Select Night Tactician | Detail card shows Night Tactician, rocket tactician subtitle, description, Smoke Screen / Explosive Trap / Grappling Hook, strengths, and Training summary |
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
| 3 | Check GameHUD ability panel | Slot labels show Solar Beam, Frost Breath, and Death Dash presentation |
| 4 | Press ability_1 / J as Guardian near enemies | Solar Beam casts forward, damages enemies, and cooldown updates |
| 5 | Press ability_2 / K as Guardian with enemies ahead | Frost Breath cone casts, damages/slows enemies, and cooldown updates |
| 6 | Press ability_3 / L as Guardian near enemies | Death Dash moves forward, damages enemies along the path, and cooldown updates |
| 7 | Enable mobile controls while Guardian is selected | Ability buttons use Guardian-specific labels and still cast slots 1/2/3 |
| 8 | Open DebugStatsOverlay during Guardian run | Ability stats still display without errors |
| 9 | Start a Night Tactician run | Blaster uses Smoke Screen, Explosive Trap, and Grappling Hook presentation without changing ability ids |
| 10 | Start a Fury Vanguard run | Vanguard uses Rage Burst, Crushing Leap, and Titan Slam presentation without changing ability ids |
| 11 | Check Training with Guardian selected | Per-Hero Training still applies only Guardian Training |
| 12 | Inspect changed text | No licensed superhero names or protected character identities are used |

---

## Blaster Ability Rework

| # | Test | Expected |
|---|------|----------|
| 1 | Open CharacterSelect | Blaster appears as Night Tactician with dark gadget tactician role text |
| 2 | Select Blaster and start a run | Run starts normally with hero id `blaster` |
| 3 | Check GameHUD ability panel | Slot labels show Smoke Screen, Explosive Trap, and Grappling Hook presentation |
| 4 | Press ability_1 / J as Blaster near enemies | Smoke Screen zone appears, slows enemies, enters cooldown |
| 5 | Press ability_2 / K as Blaster | Explosive Trap placed at player position; enters cooldown |
| 6 | Press ability_3 / L as Blaster with enemy in range | Player dashes toward enemy; impact damage and Tactical Mark applied; hook Line2D appears briefly |
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
| 2 | Select Solar Guardian | Ability details show Solar Beam, Frost Breath, and Death Dash |
| 3 | Select Night Tactician | Ability details show Smoke Screen, Explosive Trap, and Grappling Hook |
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
| 4 | Inspect ability upgrades for each hero | Slot 1/2/3 upgrade text uses hero-appropriate wording; Night Tactician sees smoke/trap/hook flavor; no nova/laser/slam flavored upgrades appear for Blaster |
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
| 1 | Complete and max an implemented active evolution triple | OverdriveScreen can offer that implemented active evolution |
| 2 | Complete and max a placeholder attack/passive evolution triple | No no-op placeholder evolution is offered |
| 3 | Select an implemented active evolution | HUD/debug state updates and the active skill behavior changes immediately |
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
| 24 | Finish a defeated run | Existing defeat currency still applies; hero mastery runs/kills increase only for selected hero; stage attempts increase only for selected stage |
| 25 | Finish a victory run after final boss defeat | Victory, final boss reward, boss result, run grade, hero victory, stage victory, and final boss mastery counters update |
| 26 | Complete Neon Lab with Reactor alive | Stage objective completion increments for Neon Lab and `defend_lab_reactor` goal completes once |
| 27 | Destroy all Wasteland Gate portals | Portals destroyed/total appear in summary and `close_wasteland_portals` goal completes once |
| 28 | Select evolutions during a run | PostRunRewardsScreen lists selected evolution titles and Attack/Active/Passive evolution counts |
| 29 | Complete any unlock goal | Goal reward is auto-claimed, added to total reward once, and listed under completed goals this run |
| 30 | Finish another run after the same goal is complete | Completed goal does not pay currency a second time |
| 31 | Open Training from MainMenu | Compact Goals line shows completed count and next incomplete progress; buying Training still works |
| 32 | Restart game after mastery/goals update | Hero mastery, stage mastery, completed/claimed goals, currency, Training, and unlocked heroes persist |
| 33 | Load an older save without mastery/goals | Save migrates with default `hero_mastery`, `stage_mastery`, and `goals` while preserving currency/Training/unlocked heroes |
| 34 | Inspect diff | No hero kit, evolution requirement, upgrade balance, stage objective, enemy, boss-flow, save-destructive, or 4/4/4 slot-rule changes |

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

---

## Evolution 3/3/3 Schema Rework

### Triple grid uniqueness and target counts (offline / code inspection)

| # | Check | Expected |
|---|-------|----------|
| 1 | Count Guardian triples in EvolutionManager | Exactly 9 (grid_index 1-9, no gaps or duplicates) |
| 2 | Count Blaster triples in EvolutionManager | Exactly 9 (grid_index 1-9, no gaps or duplicates) |
| 3 | Count Vanguard triples in EvolutionManager | Exactly 9 (grid_index 1-9, no gaps or duplicates) |
| 4 | Guardian target distribution | Exactly 3 attack / 3 active / 3 passive targets |
| 5 | Blaster target distribution | Exactly 3 attack / 3 active / 3 passive targets |
| 6 | Vanguard target distribution | Exactly 3 attack / 3 active / 3 passive targets |
| 7 | Every triple has schema target fields | `target_type` is attack/active/passive and `target_id` is non-empty |
| 8 | Active backward compatibility | Active triples may still include `target_active_skill_id`; old active target data maps to `target_type: "active"` |
| 9 | Each hero attack line used once | All 9 hero attack upgrade lines appear exactly once per hero triple grid |
| 10 | Each hero active line used once | All 9 hero active upgrade lines appear exactly once per hero triple grid |
| 11 | Each shared passive used once per hero | All 9 shared passives appear exactly once per hero triple grid |
| 12 | No duplicate evolution_id across all triples | All 27 evolution_id values are unique |

### EvolutionManager.validate_evolution_grid() (manual console check)

| # | Check | Expected |
|---|-------|----------|
| 1 | Call `validate_evolution_grid("guardian", true)` | `ok: true`, `error_count: 0`, `triple_count: 9`, `target_counts.attack: 3`, `target_counts.active: 3`, `target_counts.passive: 3` |
| 2 | Call `validate_evolution_grid("blaster", true)` | `ok: true`, `error_count: 0`, `triple_count: 9`, `target_counts.attack: 3`, `target_counts.active: 3`, `target_counts.passive: 3` |
| 3 | Call `validate_evolution_grid("vanguard", true)` | `ok: true`, `error_count: 0`, `triple_count: 9`, `target_counts.attack: 3`, `target_counts.active: 3`, `target_counts.passive: 3` |
| 4 | Temporarily blank a target_id in a local test | Validation reports `missing_target_id` |
| 5 | Temporarily duplicate a target type count in a local test | Validation reports `wrong_target_type_count` |

### Runtime triple state progression (in-game)

| # | Test | Expected |
|---|------|----------|
| 1 | Start a Guardian run; enable Debug Mode (F12) | DebugStatsOverlay shows `-- Evolutions --`, `Ready: 0  Selected: 0`, `Targets: A 3/3  Act 3/3  P 3/3`, and selected type counts at 0 |
| 2 | Take solar_ray_damage upgrade | Triple 1 (guardian_solar_cataclysm) moves from locked to partial |
| 3 | Also take orbit_shields upgrade | Triple 1 moves to partial (2/3 lines) |
| 4 | Also take solar_beam_damage_up upgrade | Triple 1 moves to collected (3/3 lines, not all maxed) |
| 5 | Max all 3 lines | Triple 1 state becomes ready; implemented active Overdrive option can appear |
| 6 | Add a future placeholder triple in a debug branch | It may become ready internally, but it is not offered in Overdrive because `effect_status` is placeholder |

### Overdrive Screen Flow

| # | Test | Expected |
|---|------|----------|
| 1 | Complete an implemented active triple, then pick any upgrade | OverdriveScreen appears and card header shows `ACTIVE EVOLUTION -> <TARGET>` |
| 2 | Complete any implemented attack, active, or passive target triple | OverdriveScreen card header uses `ATTACK`, `ACTIVE`, or `PASSIVE EVOLUTION -> <TARGET>` correctly |
| 3 | Click an implemented evolution card button | OverdriveScreen hides; game resumes; ability immediately has evolved behavior |
| 4 | Press Escape or pause while OverdriveScreen is open | No effect; game stays paused and OverdriveScreen stays visible |
| 5 | Win or die while OverdriveScreen is open | OverdriveScreen hides cleanly; VictoryScreen/GameOverScreen shows normally |
| 6 | Restart from GameOverScreen after selecting evolution | New run starts fresh with no evolutions applied |

### Implemented active evolution regression

| # | Test | Expected |
|---|------|----------|
| 1 | Select `solar_beam_cataclysm`, then cast Solar Beam | Cataclysm behavior still applies |
| 2 | Select `frost_breath_absolute_zero`, then cast Frost Breath | Absolute Zero behavior still applies |
| 3 | Select `trap_chain_detonation_evolution`, then trigger Explosive Trap | Chain Detonation behavior still applies |
| 4 | Select `hook_execution_pull`, then cast Grappling Hook | Execution Pull behavior still applies |
| 5 | Select `rage_wave_worldbreaker`, then cast Rage Wave | Worldbreaker behavior still applies |
| 6 | Select `rage_leap_meteor_crash`, then cast Rage Leap | Meteor Crash behavior still applies |

### Active Evolutions Pack

| # | Test | Expected |
|---|------|----------|
| 1 | Complete a ready active triple | OverdriveScreen offers an `ACTIVE EVOLUTION -> <TARGET>` card only when `effect_status` is implemented |
| 2 | Select `solar_beam_cataclysm`, then cast Solar Beam | Cataclysm still fires a giant beam with delayed burn pulse and `CATACLYSM` feedback |
| 3 | Select `frost_breath_absolute_zero`, then cast Frost Breath | Absolute Zero still fires a huge freezing cone with heavy slow/freeze and `ABSOLUTE ZERO` feedback |
| 4 | Select `death_dash_solar_execution`, then cast Death Dash | Death Dash becomes Final Flash: longer/wider red-gold dash, high path damage, low-health bonus damage, and `FINAL FLASH` feedback; multi-hit dashes create a `SOLAR FLASH` pulse |
| 5 | Select `smoke_screen_blackout`, then cast Smoke Screen | Smoke Screen becomes Blackout: much larger and longer field, repeated slow/marks, stronger player damage reduction inside, and `BLACKOUT` feedback |
| 6 | Select `trap_chain_detonation_evolution`, then trigger Explosive Trap | Chain Detonation still creates cascading marked explosions and `CHAIN DETONATION` feedback |
| 7 | Select `hook_execution_pull`, then cast Grappling Hook | Execution Pull still deals high single-target damage and detonates marked targets with `EXECUTION` feedback |
| 8 | Select `rage_wave_worldbreaker`, then cast Rage Wave | Worldbreaker still creates multiple expanding shockwaves with heavy slow and `WORLDBREAKER` feedback |
| 9 | Select `mighty_clap_thunderclap`, then cast Mighty Clap | Mighty Clap becomes Rampage Impact: huge Rage-scaled cone, strong knockback, delayed second clap, and `RAMPAGE IMPACT` feedback |
| 10 | Select `rage_leap_meteor_crash`, then cast Rage Leap | Meteor Crash still creates huge landing AoE plus delayed second impact and `METEOR CRASH` feedback |
| 11 | Inspect DebugStatsOverlay and BuildSlotsWindow | DebugStatsOverlay shows selected active evolution ids/titles; BuildSlotsWindow remains read-only and shows applied evolution titles |
| 12 | Inspect scope | Passive Evolutions Pack remains implemented through PassiveAbilityManager only; 4/4/4 slots, shared passives, hero base kits, stages, enemies, boss flow, rewards, saves, and meta economy are unchanged |

### Passive Evolutions Pack

| # | Test | Expected |
|---|------|----------|
| 1 | Complete a ready passive triple | OverdriveScreen offers a `PASSIVE EVOLUTION -> <TARGET>` card only when `effect_status` is implemented |
| 2 | Select `frost_breath_permafrost` with Orbit Shields | Orbit Shields become Solar Aegis: higher/faster shield charges, shield block creates solar AoE slow/knockback/damage, and `SOLAR AEGIS` feedback appears |
| 3 | Select `death_dash_comet_path` with Storm Relay | Storm Relay becomes Solar Storm: frequent multi-target solar strikes, stronger during Solar Empowered, and `SOLAR STORM` feedback appears |
| 4 | Select `death_dash_final_flash` with Recovery Field | Recovery Field becomes Radiant Renewal: stronger heal, damaging radiant pulse, brief damage reduction, and `RADIANT RENEWAL` feedback appears |
| 5 | Select `trap_marked_blast` with Guardian Drone | Guardian Drone becomes Tactical Drone Swarm: multiple shots fire per tick, targets are marked when AbilityManager supports it, and `DRONE SWARM` feedback appears |
| 6 | Select `hook_shadow_line` with Chain Lightning | Chain Lightning becomes Shock Net: marked enemies are preferred, more bounces occur, hit enemies are marked, and `SHOCK NET` feedback appears |
| 7 | Select `hook_rapid_abduction` with Time Dilator | Time Dilator becomes Stasis Field: large near-freeze pulse affects nearby enemies, marked enemies are slowed harder, and `STASIS FIELD` feedback appears |
| 8 | Select `mighty_clap_rampage_impact` with Static Field | Static Field becomes Rage Field: damage/radius/frequency scale with Rage and `RAGE FIELD` feedback appears |
| 9 | Select `rage_leap_blood_crater` with Battle Focus | Battle Focus becomes Berserker Focus: stronger Rage-scaled strikes plus stronger attack-speed burst and `BERSERKER FOCUS` feedback appears |
| 10 | Select `rage_leap_final_impact` with Magnet Core | Magnet Core becomes Gravity Rage: pickup reach increases heavily, gravity pulses pull/slow enemies, and `GRAVITY RAGE` feedback appears |
| 11 | Re-open Overdrive after selecting a passive evolution | The selected passive evolution does not appear again |
| 12 | Inspect DebugStatsOverlay and BuildSlotsWindow | DebugStatsOverlay shows selected passive evolution ids/titles; BuildSlotsWindow remains read-only and shows applied evolution titles |
| 13 | Restart, win, defeat, or quit to menu | Passive evolution ids, timers, temporary mitigation, shield/drone visuals, and magnet bonus clear with fresh run cleanup; no evolution state is saved |
| 14 | Inspect scope | Attack and Active Evolutions Packs still work; 4/4/4 slots, shared passive base grid, hero base kits, stages, enemies, boss flow, rewards, saves, and meta economy are unchanged |

### Attack Evolutions Pack

| # | Test | Expected |
|---|------|----------|
| 1 | Complete a ready attack triple | OverdriveScreen offers an `ATTACK EVOLUTION -> <TARGET>` card only when `effect_status` is implemented |
| 2 | Select `solar_beam_sky_lance` | Solar Ray range/width visibly increase; beam appears as a large red lance and hits enemies through the full wider corridor |
| 3 | Select `solar_beam_burning_judgment` | Solar Ray hits trigger `BURNING JUDGMENT` feedback and extra delayed heat damage; heat is stronger while Solar Empowered |
| 4 | Select `frost_breath_glacier_front` | Solar Ray creates a delayed radiant line pulse; this remains a Solar Ray attack evolution despite the legacy id |
| 5 | Select `smoke_screen_tactical_cover` | Homing Rockets fire extra support rockets, prefer different targets when possible, and show `TACTICAL COVER` feedback |
| 6 | Select `smoke_screen_choking_zone` | Rocket impacts create visible smoke/slow bursts, mark affected enemies when possible, and show `CHOKING ZONE` feedback |
| 7 | Select `trap_cluster_minefield` | Rocket impacts split into clustered AoE explosions and show `CLUSTER MINEFIELD` feedback |
| 8 | Select `rage_wave_earthsplitter` | Fury Strikes emit a forward ground crack with greater reach than normal splash and show `EARTHSPLITTER` feedback |
| 9 | Select `rage_wave_crushing_storm` | Fury Strikes scale harder with Rage, release a slowing pressure pulse, and show `CRUSHING STORM` feedback |
| 10 | Select `mighty_clap_seismic_fan` | Fury Strikes emit a visible forward seismic fan and show `SEISMIC FAN` feedback |
| 11 | Re-open Overdrive after selecting an attack evolution | The selected attack evolution does not appear again |
| 12 | Complete a passive triple | Implemented passive evolutions are offered through PASSIVE EVOLUTION cards and do not affect attack evolution routing |
| 13 | Check DebugStatsOverlay and BuildSlotsWindow | DebugStatsOverlay shows selected attack evolution ids; BuildSlotsWindow remains read-only and shows applied evolution titles |
| 14 | Restart, win, defeat, or quit to menu | Attack evolution state is cleared with the fresh run; no evolution state is saved |
| 15 | Inspect scope | Active and Passive Evolutions Packs remain implemented; 4/4/4 slots, shared passives, stages, enemies, boss flow, rewards, saves, and meta economy are unchanged |

### Regression - unchanged systems

| # | Test | Expected |
|---|------|----------|
| 1 | 4/4/4 upgrade slot limits | Unchanged; Overdrive does not consume or grant upgrade slots |
| 2 | Open Build Slots Window mid-run | Shows 4 attack / 4 passive / 4 active rows correctly |
| 3 | Use LevelUpScreen normally | Upgrade options and selection still work |
| 4 | Restart run | Evolution runtime state clears naturally |
| 5 | Inspect diff/save behavior | No save/meta/reward changes, no stage objective changes, no enemy changes, no boss-flow changes, and no slot-rule changes |

### Evolution UI / Balance / Validation Polish

| # | Test | Expected |
|---|------|----------|
| 1 | Open Overdrive with attack, active, and passive options ready | Each card clearly shows ATTACK / ACTIVE / PASSIVE EVOLUTION, title, target type/name, description, and required attack/passive/active line progress |
| 2 | View Overdrive on mobile landscape | Cards remain readable; content scrolls instead of overlapping pause/build/level-up UI |
| 3 | Select any Overdrive card | Screen hides, game resumes safely, and the selected evolution is not offered again |
| 4 | Open Build Slots Window after selecting evolutions | Window shows selected evolution titles, ready count, selected count, and closest triple progress without mutating slots |
| 5 | Enable DebugStatsOverlay | Overlay shows selected attack/active/passive evolution counts as x/3, ready count, closest progress, and selected evolution titles |
| 6 | Run `validate_evolution_grid(hero, true)` for each hero | Reports wrong triple count, wrong type counts, duplicate ids/lines, missing targets, invalid targets, implemented ids without handlers, hidden implemented ids, and selected ids without matching handlers |
| 7 | Audit evolved passive timing | Shock Net bounces, Drone Swarm targets, Solar Storm targets, Berserker Focus targets, and evolved passive tick intervals are capped |
| 8 | Press Pause/Build while Overdrive is open | Overdrive remains the blocking modal; BuildSlotsWindow does not open over it |
| 9 | Win, die, restart, or quit while Overdrive is visible | Overdrive closes safely and no evolution state is saved |
| 10 | Inspect scope | No new evolution categories, hero kits, slot rules, saves, rewards, stage objectives, enemies, boss flow, or meta progression changes |

### Evolution Progress UI / Synergy Hints

| # | Test | Expected |
|---|------|----------|
| 1 | Trigger LevelUpScreen with upgrades that contribute to an evolution triple | Cards keep the original title/rarity/slot/level/description layout and append a compact Evolution hint with target type and 3/3 progress |
| 2 | Trigger LevelUpScreen with a line that would complete or ready a triple | Hint clearly shows READY or missing line/max requirements without changing the offered upgrade id |
| 3 | Open Build Slots Window with selected attack/passive/active lines | Filled slot rows can show compact evolution path hints, and empty slots remain unchanged |
| 4 | Open Build Slots Window with ready and partial triples | Evolution section shows selected titles, ready count, selected count, closest progress, and compact ready/progress lines |
| 5 | Enable DebugStatsOverlay during a partial evolution build | Overlay continues to show evolution counts and adds a read-only planning line for closest progress |
| 6 | Select upgrades normally after hints appear | UpgradeManager applies the same upgrade effects and slot rules as before; hints do not select evolutions or mutate build state |
| 7 | Inspect scope and save behavior | No new evolutions, requirement changes, balance changes, 4/4/4 slot changes, saves, rewards, stages, enemies, boss flow, or meta progression changes |

---

## Solar Guardian Full Kit Rework

### Solar Energy Passive

| # | Test | Expected |
|---|------|----------|
| 1 | Start a run as Solar Guardian | DebugStatsOverlay shows `Solar Energy: 0 / 100` |
| 2 | Wait in combat without casting abilities | Energy climbs at ~2/sec; reaches 100 in ~50 seconds |
| 3 | Energy reaches 100 | "SOLAR EMPOWERED" status floats above player; energy resets to 0; DebugStatsOverlay shows `EMPOWERED 15.0s` |
| 4 | During empowered state | Timer counts down; energy begins charging again from 0 |
| 5 | Empowered state expires after 15s | `EMPOWERED` line disappears from debug overlay; energy continues building |
| 6 | Energy hits 100 again while already empowered | Does NOT trigger a second activation; stays capped at 100 until empowered expires, then activates |
| 7 | Inspect diff | Night Tactician and Fury Vanguard Solar Energy values are not shown; their overlays are unchanged |

---

### Solar Ray Autoattack (solar_ray weapon)

| # | Test | Expected |
|---|------|----------|
| 1 | Start run as Solar Guardian, wait for an enemy to enter range | A short red beam fires from player toward nearest enemy; no projectile node spawned |
| 2 | Beam fires | All enemies along the beam corridor (not just the nearest) take damage |
| 3 | Enemy outside beam corridor but within attack range | Enemy does NOT take damage from the beam |
| 4 | No enemies in attack range | Beam does not fire; cooldown does not reset |
| 5 | During Solar Empowered state | Beam damage is doubled compared to base attack_damage |
| 6 | Take `solar_ray_damage` upgrade | `attack_damage` increases; beam deals more damage per tick |
| 7 | Take `solar_ray_range` upgrade | `attack_range` increases; beam reaches further; `refresh_attack_range()` called correctly |
| 8 | Take `solar_ray_width` upgrade | `solar_ray_width` increases; beam corridor is wider; more enemies hit in a line |
| 9 | Multishot / spread / projectile upgrades (multishot_up, spread_up etc.) | Not offered to Solar Guardian in upgrade pool |
| 10 | Upgrade pool contains solar_ray_damage, solar_ray_range, solar_ray_width, solar_ray_pierce_burn | All 4 appear as attack slot options for guardian |

---

### Ability 1: Solar Beam

| # | Test | Expected |
|---|------|----------|
| 1 | Press J to cast Solar Beam | Long red beam fires from player in aim direction; hits all enemies in beam line |
| 2 | Cast Solar Beam without enemies in path | "BEAM MISS" status appears; ability still enters cooldown (~7s) |
| 3 | Cast during Solar Empowered state | Beam damage is doubled; "SOLAR BEAM" status still shown |
| 4 | Cast while cooldown is active | No cast; cooldown does not reset |
| 5 | Take `solar_beam_damage_up` upgrade | `solar_beam_damage` increases; ability deals more damage |
| 6 | Take `solar_beam_range_up` upgrade | `solar_beam_range` and `solar_beam_width` increase; ability reaches further and hits wider |
| 7 | nova_damage_up / nova_cooldown_down offered to guardian | NOT offered — hero_exclude blocks these |

---

### Ability 2: Frost Breath

| # | Test | Expected |
|---|------|----------|
| 1 | Press K to cast Frost Breath | A cone of frost fires in aim direction; all enemies in the cone take damage |
| 2 | Enemies in cone take damage | Damage matches `frost_breath_damage` (or x2 when empowered) |
| 3 | Enemies in cone are slowed | Enemies move at reduced speed (`frost_breath_slow_multiplier`) for `frost_breath_slow_duration` seconds |
| 4 | Enemy outside cone angle but within range | Enemy does NOT take damage and is NOT slowed |
| 5 | Cast Frost Breath with no enemies in cone | "FROST MISS" status; ability enters cooldown (~8s) |
| 6 | Slow restores after duration | Enemy returns to normal movement speed after `frost_breath_slow_duration` |
| 7 | Take `frost_breath_power` upgrade | `frost_breath_damage` and `frost_breath_slow_duration` increase |
| 8 | Take `frost_breath_cone_up` upgrade | `frost_breath_cone_degrees` and `frost_breath_range` increase; wider cone hits more enemies |
| 9 | laser_damage_up / laser_width_up offered to guardian | NOT offered — hero_exclude blocks these |

---

### Ability 3: Death Dash

| # | Test | Expected |
|---|------|----------|
| 1 | Press L to cast Death Dash | Player moves forward in aim direction by ~220px; a brief trail visual appears along the path |
| 2 | Enemies along dash path take damage | Path damage matches `death_dash_damage` (or x2 when empowered) |
| 3 | Player is briefly invulnerable during dash | Player cannot take damage for `death_dash_invulnerability` seconds |
| 4 | Cast at arena edge | Player is clamped to playable rect; no out-of-bounds movement |
| 5 | Cast Frost Breath without enemies in path | "DASH" status; ability enters cooldown (~9s) |
| 6 | Dash does NOT feel like old Aerial Impact | No landing radial AOE; damage is path-only during movement |
| 7 | Take `death_dash_power` upgrade | `death_dash_damage` and `death_dash_distance` increase |
| 8 | Take `death_dash_cooldown_down` upgrade | `death_dash_cooldown` decreases |
| 9 | slam_damage_up / slam_cooldown_down offered to guardian | NOT offered — hero_exclude blocks these |

---

### Solar Guardian Build Slot Limits

| # | Test | Expected |
|---|------|----------|
| 1 | Guardian attack slot pool | Contains exactly 9 Guardian-only Solar Ray lines: solar_ray_damage, solar_ray_range, solar_ray_width, solar_ray_pierce_burn, solar_ray_tick_rate, solar_ray_empowered_bonus, solar_ray_lingering_heat, solar_ray_focus, solar_ray_execution |
| 2 | Guardian active slot pool | Contains exactly 9 Guardian-only active lines: solar_beam_damage_up, solar_beam_range_up, solar_beam_overheat, frost_breath_power, frost_breath_cone_up, frost_breath_freeze, death_dash_power, death_dash_distance, death_dash_cooldown_down |
| 3 | Pick Solar Ray lines | Damage/range/width/burn/tick/empowered/lingering/focus/execution effects all change Solar Ray behavior; generic attack_damage_up, attack_speed_up, and attack_range_up are not offered to Guardian |
| 4 | Pick Solar Beam, Frost Breath, and Death Dash lines | Solar Beam damage/range/overheat affect Solar Beam; Frost Breath damage/cone/freeze affect Frost Breath; Death Dash damage/distance/cooldown affect Death Dash |
| 5 | Open Build Slots Window mid-run as guardian | Attack section shows up to 4 selected Solar Ray lines; Active section shows up to 4 selected Guardian active lines with current/max levels |
| 6 | Fill Guardian Attack or Active slots | New lines from the full category stop appearing, but already selected non-maxed Guardian lines can continue leveling |
| 7 | Call `validate_upgrade_grid_for_hero("guardian", true)` | No duplicate grid_index, duplicate upgrade_line_id, missing source_skill_id, missing slot_category, missing evolution_role, or accidental Night/Fury ownership |
| 8 | Inspect diff | Night Tactician and Fury Vanguard grids are unchanged; no Evolution triples, Overdrive UI, Build Evolution, shared passive changes, rewards, saves, stages, enemies, or boss flow were added |

---

### Solar Guardian Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Start a Night Tactician run | No solar_energy shown in debug; homing_rockets fires; DebugStatsOverlay shows Tactical Marks: 0; nova/laser/slam/bouncing_bolts/pierce upgrades NOT offered |
| 2 | Start a Fury Vanguard run | shockwave_strike still fires; slam upgrades appear; rage builds normally |
| 3 | Nova/laser/slam upgrades work for Fury Vanguard | Offered and applied correctly; Night Tactician does NOT see them |
| 4 | RunBriefingScreen for Solar Guardian | Shows Solar Beam / Frost Breath / Death Dash ability names |
| 5 | Character Select for Solar Guardian | Shows Solar Beam / Frost Breath / Death Dash; passive shows "Solar Energy" |
| 6 | HUD ability cooldown bars for guardian | Slot 1 ~7s, Slot 2 ~8s, Slot 3 ~9s base cooldowns |
| 7 | Inspect diff | No enemy values, boss flow, rewards, saves, meta economy, Build Evolution, stage objectives, or shared passive skills changed |

---

## Night Tactician Full Kit Rework

### Autoattack — Homing Rockets

| # | Test | Expected |
|---|------|----------|
| 1 | Start Night Tactician; let autoattack trigger | Homing rockets spawn and track enemies; each rocket goes to a different enemy (round-robin when multiple enemies present) |
| 2 | Pick `projectile_pierce_up` in debug | Upgrade NOT offered to Night Tactician (hero_exclude: blaster) |
| 3 | Pick `bouncing_bolts` in debug | Upgrade NOT offered to Night Tactician (hero_exclude: blaster) |
| 4 | Pick `rocket_count` upgrade | Volley size increases; rockets still distribute round-robin |
| 5 | Pick `rocket_damage` upgrade | Rocket damage increases; marked-target damage scales on top of it |
| 6 | Pick `rocket_explosion_radius` upgrade | Explosion radius visibly larger on impact |
| 7 | Pick `rocket_reload` upgrade | Fire interval decreases |
| 8 | Pick `marked_target_payload` upgrade | Tactical Mark damage multiplier increases; DebugStatsOverlay shows higher mult |

### Passive — Tactical Mark

| # | Test | Expected |
|---|------|----------|
| 1 | Cast any active ability near multiple enemies | DebugStatsOverlay shows Tactical Marks: N (matching enemies hit/inside area) |
| 2 | Wait for mark duration to expire | Mark count decreases; expired marks removed from dictionary |
| 3 | Apply marks with Smoke Screen tick, then immediately with Grappling Hook | Both sources stack on separate enemies; combined count shown |
| 4 | Fire homing rockets at a marked enemy | Floating damage numbers higher than on unmarked enemy with same stats |
| 5 | Switch hero to Solar Guardian mid-session (or restart as Guardian) | No Tactical Marks shown; no rocket multiplier applied; Guardian kit unaffected |

### Smoke Screen (Slot 1)

| # | Test | Expected |
|---|------|----------|
| 1 | Cast Smoke Screen near enemies | Blue-gray semi-transparent ColorRect zone appears at player position; persists for full duration |
| 2 | Enemies walk into the zone | Enemies slow; their speed is visibly reduced while inside |
| 3 | Player stands inside the zone and takes a hit | Damage reduced by smoke_screen_damage_reduction (default 30%) |
| 4 | Player exits the zone and takes a hit | Full damage applies; damage_reduction reset to 0 |
| 5 | Wait for smoke duration to expire | ColorRect disappears; player damage_reduction returns to 0 |
| 6 | Pick `smoke_screen_radius` upgrade | Zone is visibly wider after casting |
| 7 | Pick `smoke_screen_duration` upgrade | Zone persists longer |
| 8 | Pick `smoke_screen_slow` upgrade | Enemy slowdown inside is more severe |
| 9 | Pick `smoke_screen_damage_reduction` upgrade | Damage reduction while inside increases (capped at 70%) |
| 10 | Cast while previous smoke is active | Both zones coexist; both apply their effects independently |

### Explosive Trap (Slot 2)

| # | Test | Expected |
|---|------|----------|
| 1 | Cast Explosive Trap | Orange ColorRect trap appears at player position; cooldown starts |
| 2 | Enemy walks within trigger_radius of trap | Trap triggers: explosion in explosion_radius damages all enemies hit; they receive Tactical Mark |
| 3 | Trap placed with no enemies; wait for duration | Trap disappears after duration expires with no crash |
| 4 | Multiple traps placed in sequence | Each is tracked independently; all can coexist |
| 5 | Pick `trap_radius` upgrade | Explosion radius is visibly larger |
| 6 | Pick `trap_damage` upgrade | Explosion deals more damage (visible in floating numbers) |
| 7 | Pick `trap_cooldown_down` upgrade | Cooldown between casts is shorter |
| 8 | Pick `trap_mark_bonus` upgrade | Tactical Mark duration from trap explosion is longer |

### Grappling Hook (Slot 3)

| # | Test | Expected |
|---|------|----------|
| 1 | Cast Grappling Hook with enemy in range | Player instantly moves to enemy; high damage number; Line2D hook visual appears then fades |
| 2 | Cast Grappling Hook with no enemy in range | No dash; no damage; cooldown does NOT trigger; no crash |
| 3 | Enemy hit by hook has Tactical Mark applied | DebugStatsOverlay shows +1 marked enemy after the hook lands |
| 4 | Cast hook at enemy already marked | Mark duration refreshes |
| 5 | Pick `hook_damage` upgrade | Impact damage increases |
| 6 | Pick `hook_range` upgrade | Hook targets enemies further away |
| 7 | Pick `hook_cooldown_down` upgrade | Cooldown between casts is shorter |
| 8 | Pick `hook_mark_bonus` upgrade | Tactical Mark duration from hook impact is longer |

### Upgrade Pool Integrity

| # | Test | Expected |
|---|------|----------|
| 1 | Level-up as Night Tactician (many levels) | Only rocket_*/smoke_*/trap_*/hook_* and shared upgrades offered; nova_*/laser_*/slam_*/bouncing_bolts/pierce never appear |
| 2 | Level-up as Solar Guardian | Guardian-only upgrades appear; no rocket_*/smoke_*/trap_*/hook_* offered |
| 3 | Level-up as Fury Vanguard | Vanguard nova/laser/slam upgrades appear; no rocket_*/smoke_*/trap_*/hook_* offered |
| 4 | Attack slot upgrades for Night Tactician | rocket_damage/count/explosion_radius/reload/marked_target_payload fill attack slots only |
| 5 | Active slot upgrades for Night Tactician | smoke_/trap_/hook_ upgrades fill active slots only |
| 6 | Inspect Build Slots Window as Night Tactician | Attack section: up to 4 rocket lines; Active section: smoke/trap/hook upgrades |

### Regression — Other Heroes Unaffected

| # | Test | Expected |
|---|------|----------|
| 1 | Play Solar Guardian full run | Solar Ray, Solar Beam, Frost Breath, Death Dash, Solar Energy all function normally |
| 2 | Play Fury Vanguard full run | Shockwave Strike, Rage Burst, Crushing Leap, Titan Slam, Rage passive all function normally |
| 3 | Player.damage_reduction for non-blaster heroes | Always 0; no smoke screen sets it; no damage reduction applied |
| 4 | Shared passive skills (shield, speed, haste) | Unchanged; apply to all heroes including Night Tactician |
| 5 | Inspect diff | 4/4/4 slot rules, Build Slots Window, stage objectives, enemies, boss flow, rewards, saves, meta economy, Build Evolution unchanged |

---

## Run Director / Wave Director 2.0

### Phase Progression

| # | Test | Expected |
|---|------|----------|
| 1 | Start a run with Debug Mode ON | DebugStatsOverlay Spawner section shows `Phase: early  Profile: <stage>` |
| 2 | Let run reach 120 s | Phase changes to `build`; `Budget:` value resets and reflects build budget |
| 3 | Let run reach 240 s, 360 s, 480 s | Phase changes to `pressure`, `danger`, `pre_boss` in sequence |
| 4 | Observe spawn feel in early phase (0–120 s) | Enemies spawn slowly and readably; wave packages are only early_grunts and runner_pack |
| 5 | Observe spawn feel at 360 s+ (danger/pre_boss) | Noticeably more enemies; waves include support_pair and mixed_late_wave; intensity is clearly higher than early |

### Wave Budget

| # | Test | Expected |
|---|------|----------|
| 1 | Enable `spawn_debug_logging = true`, watch wave packages at 0–120 s | Only cheap packages (budget_cost ≤ 2.5) selected; no support_pair or mixed_late_wave |
| 2 | Same logging at 360 s+ (danger phase, budget 6.0) | Expensive packages (support_pair, mixed_late_wave) can now appear |
| 3 | Observe DebugStatsOverlay Budget counter during a run | Value decreases as waves fire; visible reset when phase changes |

### Wave Interval

| # | Test | Expected |
|---|------|----------|
| 1 | Watch WaveEvery in DebugStatsOverlay at run start | Shows ~14 s (early phase) |
| 2 | Watch WaveEvery at 480 s+ (pre_boss) | Shows ~8 s |
| 3 | Verify no wave stacking | Each wave fires after the previous; no overlapping bursts |

### Spawn Pressure

| # | Test | Expected |
|---|------|----------|
| 1 | Watch Interval in DebugStatsOverlay at run start | Shows ~2.0 s (early phase, slow) |
| 2 | Watch Interval at 480 s+ | Interval shorter; approaches hard floor ~0.20 s under extreme pressure |
| 3 | Activate an event modifier that boosts spawn_pressure | Interval decreases further; never drops below 0.20 s |

### Stage Profile Compatibility

| # | Test | Expected |
|---|------|----------|
| 1 | Play City Rooftop (balanced) run | Package mix is spread; bruiser_wall and mixed_late_wave slightly more common |
| 2 | Play Neon Lab (ranged_support) run | shooter_screen and support_pair appear more frequently |
| 3 | Play Wasteland Gate (swarm_exploder) run | swarm_rush and exploder_pressure dominate wave packages |
| 4 | Change stage and restart | Profile resets correctly; no stale bonuses from previous stage |

### Package Cooldown

| # | Test | Expected |
|---|------|----------|
| 1 | Enable spawn_debug_logging and observe same package appearing | Same package id does not repeat back-to-back before its cooldown expires |
| 2 | Watch over 3+ minutes | Package variety evident; no single package spam |

### Max Alive Cap

| # | Test | Expected |
|---|------|----------|
| 1 | Let enemies accumulate near cap, then watch a wave fire | Wave package skips some enemies to stay within cap; no cap overflow visible |
| 2 | MaxAlive value in DebugStatsOverlay scales over run time | Starts at lower value, grows toward cap over the first 5 minutes |

### Wave Warnings

| # | Test | Expected |
|---|------|----------|
| 1 | Let a high-intensity package fire (swarm_rush, exploder_pressure) during pressure/danger phase | EventAnnouncement briefly shows warning text; no crash if text never appears |
| 2 | Trigger rapid wave packages in danger/pre_boss | Warning appears at most once every 12 s; no warning spam |
| 3 | Disconnect or null event_announcement reference (test only) | No crash; waves continue normally without warnings |

### Debug Overlay Completeness

| # | Test | Expected |
|---|------|----------|
| 1 | Enable Debug Mode and check Spawner section | Shows Phase, Profile, MaxAlive, Budget, Interval, WaveEvery, Last pkg; all fields present |
| 2 | Start run before SpawnDirector is wired | No crash; overlay shows Spawner: null or partial state |
| 3 | Change phase mid-run | Phase and Budget update within one DebugStatsOverlay refresh cycle |

### Scope Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Inspect diff for hero kit files | No changes to hero kits, autoattack, or ability logic |
| 2 | Inspect diff for upgrade/evolution/overdrive files | No changes |
| 3 | Inspect diff for save/meta/rewards files | No changes |
| 4 | Check miniboss and final boss flow | Triggered by EventDirector as before; wave packages never spawn a miniboss |
| 5 | Inspect diff | No Stage Objectives Pack, Boss Encounter 2.0, or arena hazards added |

---

## Enemy Roles + Counterplay Pack

### Basic Spawning Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Start a run, let it reach 30 s | Grunt and Runner spawn; no crash |
| 2 | Let run reach 60 s | Charger and Tank appear in the pool |
| 3 | Let run reach 75–120 s | Shooter and Exploder appear |
| 4 | Let run reach 150–210 s | Swarm, Shielded, Support appear |
| 5 | Let run reach 240 s | Splitter appears; yellow-green body visible |
| 6 | Let run reach 300 s | Disruptor appears; bright cyan body visible |
| 7 | Entire run to completion | No crash; all behavior_id values function without unknown-behavior warning |

### Splitter Behavior

| # | Test | Expected |
|---|------|----------|
| 1 | Kill a Splitter | Two Grunt enemies spawn near the death position; XP gems + death burst appear |
| 2 | Kill one of the Grunt children from a Splitter | It drops XP gem normally and does NOT spawn more grunts |
| 3 | Kill Splitter when enemy_container is at max_alive | Split children are skipped or capped; no cap overflow |
| 4 | Enable spawn_debug_logging and kill Splitter | Console shows `SPLIT: spawned N 'grunt' at (x, y)` |
| 5 | Trigger final boss encounter, then kill any Splitter | No split children spawn during final boss phase |

### Disruptor Behavior

| # | Test | Expected |
|---|------|----------|
| 1 | Stand still near a Disruptor | It approaches to ~140 px then stops; does not ram the player like a Grunt |
| 2 | Wait 3 s near a Disruptor | Cyan flash on enemy body; player takes ~10 damage if within 200 px |
| 3 | Stand farther than 200 px from Disruptor | No damage when pulse fires; Disruptor pursues to close the gap |
| 4 | Kill Disruptor mid-pulse | Pulse tween is interrupted cleanly; no leftover color state |
| 5 | Check DebugStatsOverlay | Role column shows "disr:N" when Disruptors are alive |

### Support Buff Pulse Visual

| # | Test | Expected |
|---|------|----------|
| 1 | Let a Support enemy pulse nearby | Yellow-gold burst visible on the Support body when it applies its buff |
| 2 | Check buffed enemies | Body modulate shifts to warm yellow tint; returns to white when buff expires |

### Charger Behavior

| # | Test | Expected |
|---|------|----------|
| 1 | Stand in range of Charger | Orange windup flash; brief pause; then rapid charge in a straight line |
| 2 | Sidestep during charge | Charger continues in its locked direction; misses |
| 3 | Kill Charger during windup | It dies cleanly; no lingering charge state |

### Role Counts Debug

| # | Test | Expected |
|---|------|----------|
| 1 | Enable Debug Mode (F12) with multiple enemy types alive | Roles: line in Spawner section shows role abbreviations and counts |
| 2 | Kill all Swarm enemies | swarm count drops to 0; line updates within one overlay refresh |
| 3 | Let Splitter split | swarmer (or "swarm") count increases; total alive updates |

### Wave Package Pacing

| # | Test | Expected |
|---|------|----------|
| 1 | Enable spawn_debug_logging; observe waves from 0–120 s | Only early_grunts and runner_pack fire |
| 2 | Observe waves at 120–240 s (build phase) | charger_rush, bruiser_wall, shooter_screen appear |
| 3 | Observe waves at 360–480 s (danger phase) | disruptor_squad, splitter_wave appear |
| 4 | Observe waves at 480 s+ (pre_boss) | chaos_wave can fire; mix of charger, disruptor, splitter |
| 5 | Check Max alive cap during chaos_wave | Combined children from Splitters + wave enemies stay within cap |

### Counterplay Readability

| # | Test | Expected |
|---|------|----------|
| 1 | Encounter a Tank | Clearly slower than other enemies; player can circle it |
| 2 | Encounter a Shielded enemy and hit it | Blue-white flash on shield hit; shield bar drains; after shield breaks, normal red hit flash |
| 3 | Encounter a Support and kill it | Nearby enemies lose yellow tint; speed/damage modifier expires |
| 4 | Encounter an Exploder at close range | Scale pulse + orange glow telegraph; explosion deals damage if not avoided |
| 5 | Encounter a Splitter | Yellow-green color distinguishes it; players should recognize it needs priority |

### Scope Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Inspect diff | No hero kit, upgrade, evolution, save, reward, meta, or 4/4/4 slot changes |
| 2 | Check miniboss and final boss | Triggered by EventDirector/EnemySpawner as before; unaffected by role pack |
| 3 | Check EnemyProjectile | No changes; still detects Player only |
| 4 | Inspect diff | No arena hazards, Stage Objectives Pack, or Boss Encounter 2.0 added |

---

## Stage Events & Objective Pressure

### EventDirector Presence

| # | Test | Expected |
|---|------|----------|
| 1 | Start any run; check console | No "EventDirector not found" warning; EventDirector created dynamically |
| 2 | Wait until t=1:15 on City Rooftop | "Emergency wave approaching!" announcement appears |
| 3 | Wait until t=1:30 on City Rooftop | Elite spawns; "Elite Incoming!" announcement |
| 4 | Wait until t=2:30 on City Rooftop | "Wave surge!" announcement; spawn interval noticeably faster for ~30 s |
| 5 | Reach Final Phase | "Pre-boss surge!" or final phase modifier applies; DebugStatsOverlay shows active_timed modifier |
| 6 | Start final boss | No new elites or modifiers fire after boss phase begins |

### City Rooftop — Survival

| # | Test | Expected |
|---|------|----------|
| 1 | Select City Rooftop; start run | HUD shows "Survive: 0:00 / 10:00" timer in ObjectiveLabel |
| 2 | Run to 10:00 | Final boss encounter triggered as before |
| 3 | Upgrade/evolution/level-up while running | All unaffected |
| 4 | Confirm no arena hazards | Arena is open; only Line2D boundary appears during final boss |
| 5 | Pause and restart | Objective timer resets cleanly |

### Neon Lab — Defense

| # | Test | Expected |
|---|------|----------|
| 1 | Select Neon Lab; start run | Lab Reactor structure spawns near center; HUD ObjectiveLabel shows "Lab Reactor: 300 / 300 HP" |
| 2 | Let enemies approach the Reactor | Reactor HP slowly decreases; HUD label updates within 0.25 s |
| 3 | Reactor HP drops below 60% | Label turns yellow |
| 4 | Reactor HP drops below 30% | Label turns orange |
| 5 | Reactor HP reaches 0 | "Reactor Destroyed!" announcement; game over screen appears |
| 6 | Restart after defense defeat | Run resets cleanly; new Reactor spawns at full HP |
| 7 | Reactor is never damaged by the final boss | Final boss's `is_final_boss` flag excludes it from contact list |
| 8 | Wait until t=1:00 | "Ranged support detected!" announcement |
| 9 | Wait until t=2:00 | Elite spawns |
| 10 | Check DebugStatsOverlay (F12) | Shows "Type: defense  Done: false" and current Reactor HP |
| 11 | Confirm no arena hazards | Only the Reactor structure and Boss arena boundary (on final boss) exist |

### Wasteland Gate — Portal Closure

| # | Test | Expected |
|---|------|----------|
| 1 | Select Wasteland Gate; start run | Three Dark Portals appear at spread positions; HUD shows "Portals: 0 / 3" |
| 2 | Attack a portal with the primary weapon | Portal HP decreases; HP label updates |
| 3 | Portal HP reaches 0 | Portal visual darkens; "0 / 3" → "1 / 3" in HUD |
| 4 | Check DebugStatsOverlay after portal destroyed | "Portals: 1 / 3  Alive: 2  Pressure: true"; portal_modifier spawn_pressure decreases |
| 5 | Destroy all 3 portals | "All Portals Destroyed!" announcement; portal pressure cleared; final boss encounter begins |
| 6 | Confirm run timer does NOT trigger boss | Timer runs normally but `target_time_reached` is not connected to boss for this stage |
| 7 | Wait until t=1:00 | "Swarms detected at the portals!" announcement |
| 8 | Wait until t=3:00 | "Swarm rush!" surge with swarm/exploder weight boost; faster spawning for ~25 s |
| 9 | Check DebugStatsOverlay while portals alive | Shows portal_modifier with spawn_pressure > 1.0 |
| 10 | Confirm portals do not create hazards | Portals do not deal damage to player or restrict movement |

### General Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Play all 3 stages to victory | Win conditions unchanged; final boss still required on all stages |
| 2 | Open build window during any objective stage | Build window opens/closes cleanly; objective state unaffected |
| 3 | Pause during objective stage | Pause menu works; Reactor/portal timers frozen while paused |
| 4 | Level-up during defense stage | Level-up screen opens cleanly; Reactor still accepts damage after close |
| 5 | Miniboss spawns on Neon Lab | Miniboss health bar shows; miniboss does NOT damage the Reactor |
| 6 | Final boss spawns on Neon Lab before Reactor is destroyed | Reactor still shows HP; boss fight proceeds normally |
| 7 | Restart from game over on Wasteland Gate | Three fresh portals spawn; portal pressure re-applies |
| 8 | Inspect diff | No hero kits, upgrades, evolutions, saves, meta, rewards, or 4/4/4 slot changes |
| 9 | Inspect diff | No Boss Encounter 2.0 changes |
| 10 | Inspect diff | No arena hazards of any kind |

---

## Boss Encounter 2.0

### Arena Setup (unchanged behavior)

| # | Test | Expected |
|---|------|----------|
| 1 | Reach target time or destroy all portals | "Final Boss Incoming!" / boss-arena sequence begins exactly as before; no duplicate boss spawns |
| 2 | Normal enemies are cleared | All non-final-boss enemies disappear; no XP or powerup drops granted |
| 3 | Spawner and EventDirector stop | No new regular enemies, wave packages, elites, or timed-modifier events fire during boss fight |
| 4 | Player bounds | Player clamped to ~1200×900 boss arena; camera limits match |
| 5 | Boss arena boundary | Orange Line2D rectangle visible; no collision shape, no damage dealt |

---

### Intro Delay

| # | Test | Expected |
|---|------|----------|
| 1 | Boss spawns | 1.8 s intro delay before any attack fires |
| 2 | HUD final boss label during intro | Shows "Boss: \<Name\>  [P1]" in orange immediately on spawn |
| 3 | Announcement during intro | "\<Boss Name\> appears!" announcement fires ~2 s after arena setup |
| 4 | BossHealthBar during intro | Shows boss name, full HP bar, "Phase 1" label |
| 5 | Player can move and cast abilities during intro | No input lock during intro delay |

---

### Phase Transitions

| # | Test | Expected |
|---|------|----------|
| 1 | Boss HP drops to 50% | "Final Boss Enraged!" announcement; HUD label updates to "[P2]" in amber; BossHealthBar PhaseLabel shows "Phase 2 — Enraged" in amber |
| 2 | Boss HP drops to 25% | Boss-specific announcement fires (see identity table below); HUD label updates to "[P3]" in red; BossHealthBar PhaseLabel shows "Phase 3 — Desperation" in red |
| 3 | Camera shake on phase change | Brief screen shake accompanies each phase announcement |
| 4 | Phase does not regress | Healing or editor changes below 25% do not reset phase back; state is one-way |
| 5 | Titan Guardian at 25% HP | "Titan Guardian: Last Stand!" announcement |
| 6 | Prism Overlord at 25% HP | "Prism Overlord: Desperate!" announcement |
| 7 | Molten Colossus at 25% HP | "Molten Colossus: Molten Fury!" announcement |

---

### Attack Patterns — Existing (v1)

| # | Test | Expected |
|---|------|----------|
| 1 | Boss fires **nova** | Circle telegraph appears; after delay, all enemies in radius take damage including player |
| 2 | Boss fires **barrage** | Circle telegraph; 8+ radial projectiles spread around the boss |
| 3 | Boss fires **charge** | Line telegraph from boss to player; boss rushes at high speed after delay |
| 4 | Telegraph timing | All telegraphs last ≥ 0.55 s; player can dodge if moving during telegraph |
| 5 | Damage path | All damage goes through `Player.take_damage()`; dash invulnerability and debug invulnerability still block it |

---

### Attack Patterns — New (2.0)

#### aimed_barrage

| # | Test | Expected |
|---|------|----------|
| 1 | Boss fires **aimed_barrage** | Line telegraph toward current player position; then 3 waves of 5 projectiles (phase 1/2) or 7 (phase 3) fire aimed at player |
| 2 | Total projectile count | No more than 20 projectiles from a single aimed_barrage attack |
| 3 | Wave timing | Short (~0.18 s) delay between waves; staggered impacts |
| 4 | Dodge window | Moving during telegraph changes aim target for subsequent waves |

#### ring_barrage

| # | Test | Expected |
|---|------|----------|
| 1 | Boss fires **ring_barrage** | Circle telegraph; then 10 projectiles fire radially in all directions |
| 2 | Projectile spacing | 36° apart; player can move through any gap |
| 3 | Count cap | Exactly 10 projectiles per ring_barrage |

#### double_charge

| # | Test | Expected |
|---|------|----------|
| 1 | Boss fires **double_charge** | First line telegraph shows; boss charges; brief pause; second line telegraph shows; boss charges again |
| 2 | Second charge aims at current player position | Moving during first charge changes the direction of the second |
| 3 | Damage per charge | Each charge uses the same contact damage as the standard charge |
| 4 | Telegraph present before each charge | Both first and second charge have a visible line telegraph of ≥ 0.55 s |

#### pulse_nova

| # | Test | Expected |
|---|------|----------|
| 1 | Boss fires **pulse_nova** | Small inner circle telegraph; inner AoE fires; then larger outer ring telegraph; outer AoE fires |
| 2 | Inner radius | Matches `nova_radius` |
| 3 | Outer radius | Approximately `nova_radius × 1.6`; larger than inner |
| 4 | Damage check timing | Inner damage fires after inner telegraph; outer damage fires after outer telegraph; two separate damage windows |
| 5 | Dodge window | Player can be outside inner but inside outer gap briefly; move away from both radii |

---

## Inventory Item Details / Compare UI

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training → Equipment tab | Inventory grid shows items with short name, slot, level, and [E] tag for equipped items |
| 2 | Click an occupied inventory cell | Detail panel shows item name, slot, level/max, status, stat bonus per level, and total bonus |
| 3 | Click the currently equipped item cell | Detail shows "Status: EQUIPPED" and compare section says "This item is currently equipped." |
| 4 | Click an unequipped item in the same slot | Compare section shows "--- Compare ---" with equipped item name/level/stat and selected item name/level/stat and delta (better/worse/equal) |
| 5 | Delta when selected item is better | Delta line shows "Delta: +X.X (better)" in compare section |
| 6 | Delta when selected item is worse | Delta line shows "Delta: -X.X (worse)" in compare section |
| 7 | Delta when both items have equal stat total | Delta line shows "Delta: 0 (equal)" in compare section |
| 8 | Click an empty inventory cell | Detail panel shows "[Empty Slot] / No item selected. / Future items will appear here." |
| 9 | Equip button for empty cell | Equip button shows "Equip" and is disabled (muted) |
| 10 | Equip button for an already-equipped item | Equip button shows "Equipped" and is disabled (muted) |
| 11 | Equip button for an unequipped compatible item | Equip button shows "Equip" and is enabled (green) |
| 12 | Press Equip on an unequipped item | Item swaps into its slot; inventory grid updates [E] tags; equipped gear panel updates; equip button changes to "Equipped" |
| 13 | Click an equipped slot panel on the left Equipped Gear panel | The matching item cell in the inventory grid is selected; detail panel updates to that item |
| 14 | Equipped item cell color | Unselected equipped items show green tint; selected equipped item shows bright green highlight |
| 15 | Unequipped item cell color | Unselected unequipped items show white; selected unequipped item shows yellow-white highlight |
| 16 | Empty cell color | Empty cells always show muted gray regardless of selection |
| 17 | Detail panel with long text | Detail scrolls inside its container; inventory grid and equip button remain visible above it |
| 18 | Inspect diff / save behavior | No gacha, random loot, item drops, random affixes, combat stat changes, evolution changes, rewards, stage changes, or enemy changes |

---

### Phase Attack Pools

| # | Test | Expected |
|---|------|----------|
| 1 | Titan Guardian phase 1 | Attack loop cycles: nova → charge → nova |
| 2 | Titan Guardian phase 2 | Attack loop cycles: pulse_nova → charge → barrage |
| 3 | Titan Guardian phase 3 | Attack loop cycles: pulse_nova → double_charge → pulse_nova; attacks fire noticeably faster |
| 4 | Prism Overlord phase 1 | Attack loop cycles: barrage → aimed_barrage → barrage |
| 5 | Prism Overlord phase 3 | Majority aimed_barrage and ring_barrage; attacks fire at half normal cooldown |
| 6 | Molten Colossus phase 1 | nova and charge dominant; larger nova radius than Titan Guardian |
| 7 | Cooldown multipliers | Phase 2 attacks at ≈0.65× base cooldown; phase 3 at ≈0.5× base cooldown (noticeably faster) |

---

### Debug Overlay

| # | Test | Expected |
|---|------|----------|
| 1 | Enable Debug Mode (F12) during a boss fight | DebugStatsOverlay "-- Boss --" section shows: ID, encounter_state, phase, HP%, current_attack, cooldown_remaining, is_attacking, arena_active |
| 2 | Phase transitions | `encounter_state` and `phase` values update in overlay within 0.25 s |
| 3 | During an attack | `current_attack` shows the active pattern name; `is_attacking: true` |
| 4 | Boss defeated | Overlay shows `(no boss)` or `defeated` state |
| 5 | No boss active | Overlay shows `(no boss)` without crashing |

---

### Cleanup Paths

| # | Test | Expected |
|---|------|----------|
| 1 | Player dies during boss fight | GameOverScreen shows; boss controller stops; boundary cleaned on restart/quit confirm |
| 2 | Restart from game over during boss fight | `_cleanup_boss_controller()` called first; fresh Arena starts; no stale boss state |
| 3 | Quit to menu from game over during boss fight | `_cleanup_boss_controller()` called; returns to MainMenu safely |
| 4 | Pause → Confirm Restart during boss fight | Confirm dialog triggers cleanup; fresh run starts cleanly |
| 5 | Pause → Confirm Quit to Menu during boss fight | Confirm dialog triggers cleanup; MainMenu opens |
| 6 | Boss defeated normally | Victory flow runs; BossHealthBar hides; boundary removed; controller freed automatically with boss node |

---

### No Arena Hazards

| # | Test | Expected |
|---|------|----------|
| 1 | Inspect boss arena boundary | Line2D rect only; no collision shape, no Area2D, no damage |
| 2 | Walk into the boundary Line2D | Player passes through freely; no damage, no slow, no pushback |
| 3 | Inspect all FinalBossController attacks | All attacks go through `Player.take_damage()` or `EnemyProjectile`; no floor zones, lava, or environment damage |
| 4 | Inspect git diff | No `CollisionShape2D`, `Area2D`, or damage-dealing nodes added to the arena or boundary |

---

### Regression — Unchanged Systems

| # | Test | Expected |
|---|------|----------|
| 1 | Hero kits | Solar Guardian, Night Tactician, and Fury Vanguard abilities work identically during boss fight |
| 2 | Evolutions | Applied evolutions continue to function during boss fight; no evolution state changed by boss |
| 3 | Upgrade effects | All active upgrade effects still apply |
| 4 | Stage objectives | Neon Lab Reactor remains on screen; portal pressure already cleared before boss; neither interacts with boss logic |
| 5 | Run rewards | `final_boss_defeated` flag and +35 reward still work |
| 6 | Meta progression | No Training, currency, saves, or meta state altered by Boss Encounter 2.0 |
| 7 | Miniboss | Miniboss health bar still works; miniboss encounter is unchanged |

---

## Main Menu Collection Entry & Hero Collection Screen Foundation Validation

### Setup

```sh
godot --headless --editor --quit
git status
git diff --stat
```

### Collection Button Presence

| # | Test | Expected |
|---|------|----------|
| 1 | Open main menu | Bottom bar shows three buttons: Select Hero, Training, Collection |
| 2 | Inspect layout on 16:9 | All three buttons visible and not clipped |
| 3 | Settings top-left | Unchanged |
| 4 | Help / Controls top-right | Unchanged |
| 5 | Last Choice hint | Visible / hidden as before |

### Collection Screen — Hero Cards

| # | Test | Expected |
|---|------|----------|
| 1 | Click Collection | HeroCollectionScreen opens; left panel lists Solar Guardian, Night Tactician, Fury Vanguard cards |
| 2 | Card content | Each owned card shows display name, playstyle line, passive name, and OWNED status |
| 3 | Locked placeholders | Three "??? Locked Hero" / "Future hero  \|  LOCKED" cards appear below the owned cards |
| 4 | Locked placeholder interaction | Placeholder cards are disabled / not clickable |
| 5 | Summary label (top-right) | Shows "Owned: 3 / 3  \|  Currency: N" |

### Collection Screen — Detail Panel

| # | Test | Expected |
|---|------|----------|
| 1 | Default selection | First owned hero (Solar Guardian) is highlighted; right panel shows Solar Guardian details |
| 2 | Select Night Tactician card | Right panel updates: name, subtitle, playstyle, passive Tactical Mark, weapon Homing Rockets, abilities, mastery, description |
| 3 | Select Fury Vanguard card | Right panel updates with Fury Vanguard info |
| 4 | Detail panel — owned status | OWNED label in green |
| 5 | Detail panel — mastery | Mastery Lv.N  \|  Runs: N  \|  Victories: N (reads MetaProgressionManager live) |
| 6 | Detail panel — color swatch | Colored strip matches hero color |
| 7 | Detail panel — equipment summary | Shows compact read-only equipment progress with upgraded count, total levels / max, and highest level |

### Collection Screen — Open / Close / ESC

| # | Test | Expected |
|---|------|----------|
| 1 | Click Back | Collection closes; main menu reappears |
| 2 | Press ESC / ui_cancel | Collection closes; main menu reappears |
| 3 | Open Settings, then click Collection | Collection does not open over Settings |
| 4 | Open Training, then click Collection | Collection does not open over Training |
| 5 | Open Help, then click Collection | Collection does not open over Help |
| 6 | Press ESC while Collection is open | Collection closes, not Settings or Help |

### Existing Flow Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Select Hero | CharacterSelect opens as before |
| 2 | Training | MetaUpgradeShop opens as before |
| 3 | Back from CharacterSelect | Main menu returns as before |
| 4 | Start a run, play, quit | Full run unaffected; Collection not visible during run |
| 5 | Quit to menu after run | Main menu returns; Collection hidden |
| 6 | Gameplay, combat, saves, rewards, meta Training | Entirely unchanged |
| 7 | Gacha pulls | Not present (future work) |
| 8 | Equipment controls | No equipment grid, inventory, swapping, or upgrade controls are present in Collection |
| 9 | hero_selected signal connected to CharacterSelect | Not connected (future work) |
| 8 | Inspect diff | No hero kits, evolutions, 4/4/4 slots, stage objectives, rewards, saves, meta progression, or arena hazards changed |

---

## Training Screen Layout Rework

### Setup

```sh
godot --headless --editor --quit
git status
git diff --stat
```

### Tabbed Layout + Navigation

Current patch validation:

| # | Test | Expected |
|---|------|----------|
| 1 | Main Menu -> Training | MetaUpgradeShop opens on the Equipment tab |
| 2 | Top navigation | Equipment tab, Training tab, compact currency label, and Main Menu button are visible |
| 3 | Header cleanup | Large "Training" title, visible hero selector buttons, and standalone Goals Next block are not present |
| 4 | Main Menu button | Click returns to MainMenu through the existing Training close flow |
| 5 | Escape / ui_cancel | Closes Training and returns to MainMenu safely |
| 6 | Equipment tab | Selected hero preview, 6 fixed equipment slots, and Inventory section are visible |
| 7 | Inventory shell | Shows fixed/equipped item cards or empty placeholders, details update on card click, and Swap coming next is disabled |
| 8 | Training tab | Existing Training upgrade rows appear and purchase behavior is unchanged |
| 9 | Tab switching | Switching Equipment/Training tabs does not reset the selected hero or currency |
| 10 | Scope exclusions | No gacha, item drops, random item generation, full swapping, combat, rewards, stages, enemies, boss flow, or 4/4/4 rules changed |

Equipment / Inventory horizontal layout validation:

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training | Equipment tab is active by default |
| 2 | Inspect Equipment tab layout | Equipped Gear panel is on the left and Inventory panel is on the right on the same horizontal line |
| 3 | Inspect Equipped Gear panel | Hero preview and all 6 equipped slots remain visible with level, stat bonus, and existing upgrade buttons |
| 4 | Inspect Inventory panel | Inventory uses square grid cells, not a vertical list |
| 5 | Count inventory states | Occupied preview cells and empty muted cells are both visible, with at least 20 total cells |
| 6 | Click occupied inventory cell | Details show item name, slot, level/max, current bonus, next bonus, and Swap coming next |
| 7 | Click empty inventory cell | Details show Empty inventory slot and Swap coming next |
| 8 | Regression | Training tab, equipment purchases, Training purchases, currency refresh, Main Menu button, and ESC/ui_cancel still work |


### Equipment Panel — Fixed Equipment Upgrades

| # | Test | Expected |
|---|------|----------|
| 1 | Count equipment slots | Exactly 6 slots visible: Core, Suit, Emblem on left; Gauntlets, Boots, Artifact on right |
| 2 | Open Training for Solar Guardian | Slots show Solar Core, Radiant Suit, Sun Emblem, Power Gauntlets, Flight Boots, and Aegis Artifact |
| 3 | Switch to Night Tactician | Slots update to Tactical Core, Shadow Suit, Signal Emblem, Gadget Gauntlets, Grapnel Boots, and Drone Artifact |
| 4 | Switch to Fury Vanguard | Slots update to Rage Core, Titan Suit, War Emblem, Impact Gauntlets, Heavy Boots, and Fury Artifact |
| 5 | Inspect each slot | Shows slot name, equipment display name, "Level current / 10", bonus per level, current total, next total, and an Upgrade/Need/MAX button |
| 6 | Buy affordable equipment | Shared currency decreases, equipment level increases, currency label updates, and the slot flashes |
| 7 | Try unaffordable equipment | Button shows Need X and is disabled |
| 8 | Upgrade equipment to max | Button shows MAX and no further purchase is possible |

### Equipment Panel — Hero Preview

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training for Solar Guardian | Equipment panel shows "Solar Guardian", subtitle/playstyle, color swatch in gold |
| 2 | Open Training for Night Tactician | Equipment panel shows "Night Tactician", subtitle, color swatch in dark blue |
| 3 | Open Training for Fury Vanguard | Equipment panel shows "Fury Vanguard", subtitle, color swatch in red |
| 4 | Hero status label | Shows "Owned" in green for unlocked heroes |
| 5 | Color accent swatch | Narrow strip at top of hero preview matches hero color |

### Hero Selector Compatibility

| # | Test | Expected |
|---|------|----------|
| 1 | Click Guardian, Blaster, Vanguard buttons | Selected hero button turns green and is disabled; other buttons are white |
| 2 | Switch from Guardian to Blaster | Training upgrade rows update; equipment hero preview name/subtitle/color and all 6 equipment names/levels update |
| 3 | Switch from Blaster to Vanguard | Same as above for Vanguard; per-hero equipment levels remain separate |
| 4 | Goals label after switch | Goals label still shows correct totals |
| 5 | Currency after switch | Currency label unchanged (global shared currency) |

### Training Upgrade List (Right Panel) — Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Right panel upgrade list | All Training upgrades (Vitality, Power, Awareness, Mobility, Rewards) present |
| 2 | Buy a Training upgrade | Currency decreases; upgrade level increases; row flashes green |
| 3 | Upgrade at max level | Buy button shows "MAX" and is disabled |
| 4 | Insufficient currency | Buy button is disabled and grayed |
| 5 | Upgrade levels per hero are separate | Switching hero shows different levels for the same upgrade id |

### Navigation & Safety

| # | Test | Expected |
|---|------|----------|
| 1 | Click Back | Training closes; main menu reappears |
| 2 | Press ESC | Training closes; main menu reappears |
| 3 | Collection still opens from main menu | Collection screen opens normally and selected hero details show a compact equipment summary |
| 4 | Select Hero still opens CharacterSelect | CharacterSelect opens normally |
| 5 | No gameplay, saves, or rewards changed | Opening/closing Training has no gameplay side effects |

### Save Migration / Data Foundation

| # | Test | Expected |
|---|------|----------|
| 1 | Load an old save without `equipment_by_hero` | Save loads without errors and equipment defaults are created for Guardian, Blaster, and Vanguard |
| 2 | Inspect `debug_get_equipment_summary()` | Each hero has 6 equipment entries, upgraded count, total levels, max levels, highest level, and aggregated modifiers |
| 3 | Check existing save fields after migration | Currency, `training_by_hero`, `hero_mastery`, `stage_mastery`, `goals`, and `unlocked_heroes` are preserved |
| 4 | Inspect `debug_get_equipment_modifiers_for_hero(hero_id)` | Returns aggregated equipment stat modifiers for the selected hero |

### Equipment Run-Start Bonuses

| # | Test | Expected |
|---|------|----------|
| 1 | Upgrade Guardian health/damage/move/XP equipment, then start Solar Guardian | Supported bonuses apply at run start only for Guardian |
| 2 | Start Night Tactician after upgrading Guardian only | Guardian equipment bonuses do not apply to Night Tactician |
| 3 | Upgrade Night Tactician cooldown/mark equipment, then start Night Tactician | Ability cooldown and Tactical Mark modifiers apply from the selected hero's equipment |
| 4 | Upgrade Fury Vanguard Rage equipment, then start Fury Vanguard | Rage gain modifiers apply from Vanguard equipment |
| 5 | Restart a run | Equipment bonuses re-apply once from the fresh Arena setup; no permanent in-run stacking |

### Scope Confirmation

| # | Test | Expected |
|---|------|----------|
| 1 | Equipment levels are fixed-gear progression only | `equipment_by_hero` exists, defaults to level 0, and can be upgraded only through fixed hero equipment slots |
| 2 | Inventory shell only | Read-only Inventory section is present, but no item ownership, random generation, full swapping, drops, or equip/unequip behavior is added |
| 3 | No gacha added | No banner, pull button, or shard system present |
| 4 | No item drops or random stats | No item pickup/drop logic or random item generation was added |
| 5 | Existing systems unchanged | Training purchase flow, goals/mastery, rewards, hero selection, collection, combat kits, evolutions, stage objectives, boss flow, and 4/4/4 rules still work |

---

## Inventory Data & Equipment Swapping Foundation

### Save Migration

| # | Test | Expected |
|---|------|----------|
| 1 | Delete save file, open Training → Equipment tab | Starter inventory auto-created: 6 equipped + 2 alternative items per hero |
| 2 | Open Training after upgrading equipment, then delete and re-open | Save migration copies existing equipment levels into equipped item instances |
| 3 | Check save file | `inventory_by_hero` and `equipped_by_hero` keys are present; save version = 5 |

### Inventory Grid

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training → Equipment tab for Solar Guardian | Inventory grid shows 8 items (6 equipped + 2 alternatives) for Guardian, remaining cells are empty |
| 2 | Inspect item cells | Equipped items show `[E]` in label; unequipped alternatives show no `[E]` |
| 3 | Click an equipped item cell | Detail label shows item name, slot, "EQUIPPED" status, level, and bonus info; Equip button shows "Equipped" (disabled) |
| 4 | Click an unequipped alternative item cell | Detail label shows name, slot, "Not equipped" status; Equip button shows "Equip" (green, enabled) |
| 5 | Click an empty cell | Detail label shows "Empty inventory slot."; Equip button shows "Equip" (disabled) |
| 6 | Switch hero in Equipment tab | Grid refreshes to show that hero's inventory items |

### Equipment Swapping

| # | Test | Expected |
|---|------|----------|
| 1 | Select an unequipped Core alternative (e.g. Radiant Reactor Core for Guardian), press Equip | Item becomes equipped; `[E]` moves to the new item; old core item loses `[E]`; Equipped Gear panel updates to show new item name |
| 2 | Swap Gauntlets for Guardian | Power Gauntlets ↔ Sunbreaker Gauntlets swaps correctly; Equipped Gear panel reflects new gauntlet name |
| 3 | Re-open Training after a swap | Swap is persisted; inventory and equipped state are restored correctly |
| 4 | Equip the previously equipped item back | Swap works in both directions; no item is lost |

### Gameplay Modifiers

| # | Test | Expected |
|---|------|----------|
| 1 | Upgrade the equipped Solar Core to level 2, start a Guardian run | Ability damage bonus applies from the equipped core's level |
| 2 | Swap Guardian Core to Radiant Reactor Core (level 0), start a Guardian run | Ability damage bonus is 0 (from the newly equipped level-0 alternative, not the old core) |
| 3 | Upgrade equipment while an alternative is equipped | The equipped alternative's level is what MetaApplier reads; the unequipped item's upgrade does not affect gameplay |
| 4 | Only equipped items contribute modifiers | `debug_get_equipment_modifiers_for_hero("guardian")` reflects only the currently equipped items' levels |

### Equipped Gear Panel

| # | Test | Expected |
|---|------|----------|
| 1 | Open Equipment tab after a swap | Equipped Gear panel slot shows the swapped item's display name, not the old item's name |
| 2 | Upgrade an equipped item through the Upgrade button | Level increments on the equipped slot; detail updates correctly |
| 3 | Upgrade button on a slot where an alternative is equipped | Upgrade targets the primary definition's template_id; cost and level display correctly |

### Scope Confirmation

| # | Test | Expected |
|---|------|----------|
| 1 | No gacha or item drops added | No pull button, banner, or shard system present |
| 2 | No random item stats | All items have fixed stat types from their template definition |
| 3 | Equipping is free | No currency is spent when pressing Equip |
| 4 | Training tab unchanged | Training upgrades, buy flow, and per-hero levels work as before |
| 5 | Combat unchanged | Hero kits, evolutions, upgrade pool, boss flow, and 4/4/4 slot rules are unaffected |
| 6 | Inspect diff | No random item stats, item drops, inventory, gacha, swapping, Training cost changes, reward changes, or slot rule changes |

---

## Item Upgrade Economy Rework

### Upgrade Cost Display

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training -> Equipment and select a Common item below max | Popup shows Upgrade Cost using Gold + Common Dust |
| 2 | Select a Rare item below max | Popup shows Upgrade Cost using Gold + Rare Dust |
| 3 | Select an Epic item if test-created | Popup shows Upgrade Cost using Gold + Epic Core |
| 4 | Inspect owned resources | Popup shows owned Gold/material amounts against required amounts |
| 5 | Insufficient Gold or material | Popup shows missing resource amount; button text is "Need Resources" and disabled |
| 6 | Max-level item | Button shows "MAX" and disabled; no cost is spendable |

### Upgrade Spending

| # | Test | Expected |
|---|------|----------|
| 1 | Dismantle another Common item | Gold and Common Dust increase; selected item's upgrade display refreshes when reselected |
| 2 | Upgrade item with enough Gold and matching material | Item level increases by 1; Gold decreases by required amount; matching material decreases by required amount |
| 3 | Compare old currency before/after item upgrade | Old Training/progression currency does not change |
| 4 | Upgrade with enough Gold but not enough material | Upgrade fails; Gold, materials, and item level are unchanged |
| 5 | Upgrade with enough material but not enough Gold | Upgrade fails; Gold, materials, and item level are unchanged |
| 6 | Upgrade equipped item | Equipped slot level/stat preview refreshes; set bonuses remain based only on equipped pieces |

### Next-Level Stat Preview and Gameplay Note

| # | Test | Expected |
|---|------|----------|
| 1 | Select an item below max level in inventory detail | Detail panel shows "Next Level: +X.XX StatName" preview line |
| 2 | Select an item at max level | No "Next Level" preview line is shown |
| 3 | Select an equipped item | Detail panel shows "Affects gameplay: YES" |
| 4 | Select an unequipped item | Detail panel shows "Affects gameplay: NO (equip to apply)" |

### Atomicity and Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Upgrade same item via equipped slot request vs. inventory Upgrade button | Gold/materials are spent exactly once; no double spend |
| 2 | Training tab purchase | Still spends old Training/progression currency and never spends Gold/materials |
| 3 | Dismantle after upgrade | Still gives Gold + matching-rarity material |
| 4 | Equip/unequip, lock/favorite, starter pack, post-run item rewards | Existing flows still work |
| 5 | Set bonuses | Still apply from equipped pieces only; values unchanged |
| 6 | No crafting/fusion/gacha/random affixes/enemy drops/reward chance changes | Diff shows none of these |
---

## Inventory Filters / Sorting

| # | Test | Expected |
|---|------|----------|
| 1 | Open Equipment tab (default state) | All items visible in grid plus empty cells to reach 20; Slot=All, State=All, Sort=Default |
| 2 | Set Slot filter to "Core" | Only core items shown in grid; empty cells fill the rest |
| 3 | Set Slot filter to "Gauntlets" | Only gauntlet items shown; empty cells fill the rest |
| 4 | Set Slot filter to "Suit", "Emblem", "Boots", "Artifact" | Each filter shows only items of that slot type |
| 5 | Set State filter to "Equipped" | Only items currently equipped in a slot are shown |
| 6 | Set State filter to "Unequipped" | Only items not currently equipped are shown |
| 7 | Set Slot "Core" + State "Equipped" combined | Only the currently equipped core item is shown |
| 8 | Set Sort to "Level High" | Items ordered highest level first; empty cells follow |
| 9 | Set Sort to "Level Low" | Items ordered lowest level first; empty cells follow |
| 10 | Set Sort to "Name" | Items ordered alphabetically by template_id; empty cells follow |
| 11 | Set Sort to "Slot" | Items ordered core→suit→emblem→gauntlets→boots→artifact; empty cells follow |
| 12 | Select an item, then change Slot filter to one that still includes that item | The selected item stays selected and detail panel is unchanged |
| 13 | Select an item, then change Slot filter to one that excludes that item | Selection moves to first occupied cell in filtered view |
| 14 | Set a filter that matches no items | Grid shows only empty cells; detail panel shows "No items match current filters." |
| 15 | Reset Slot and State filters to "All" after empty result | Items reappear; empty slot message is gone |
| 16 | Click Equip on a filtered item | Equip works normally; equipped gear panel updates |
| 17 | Upgrade an item via inventory Upgrade button while filter is active | Upgrade works normally; level updates in grid and detail panel |
| 18 | Click an equipped slot panel on the left | Corresponding inventory item is selected in the filtered grid (if visible); detail panel updates |
| 19 | Switch hero via Training | Equipment tab refreshes with the new hero's inventory; filters remain as-is |
| 20 | Training tab | Entirely unaffected by inventory filter/sort changes |
| 21 | Main Menu button | Visible and returns to MainMenu regardless of filter state |
| 22 | No gacha, random loot, item drops, random affixes, crafting, or fusion added | Diff shows none of these |

---

## Item Rewards After Run

### Short Defeat (< 5 minutes)

| # | Test | Expected |
|---|------|----------|
| 1 | Die before 5 minutes | No item reward granted |
| 2 | Victory/Game Over screen | "Item Rewards: No items found." shown in muted color |
| 3 | Run Rewards popup | Item Rewards section shows "No items found." |
| 4 | Training inventory after run | Item count unchanged |

### Long Defeat (≥ 5 minutes)

| # | Test | Expected |
|---|------|----------|
| 1 | Survive at least 5 minutes then die | 1 item granted |
| 2 | Item rarity | Always common for defeat runs |
| 3 | Victory/Game Over screen | "Item Rewards:" lists 1 item with name, slot, rarity |
| 4 | Training inventory after run | 1 new item appears in grid |

### Victory

| # | Test | Expected |
|---|------|----------|
| 1 | Win any run without final boss | 1 item granted |
| 2 | Item rarity | common/uncommon/rare weighted (mostly common) |
| 3 | Victory screen shows item rewards | "Item Rewards:" section above buttons; lists 1 item |
| 4 | Run Rewards popup | Item Rewards section lists 1 item |

### Victory + Final Boss Defeated

| # | Test | Expected |
|---|------|----------|
| 1 | Win and defeat final boss | 2 items granted |
| 2 | Item rarities | First item standard victory weights; second item has higher rare chance |
| 3 | Victory screen | Lists both items |
| 4 | Training inventory | 2 new items appear |

### Rarity and Weighting

| # | Test | Expected |
|---|------|----------|
| 1 | Victory + objective completed | Uncommon chance noticeably higher than base victory |
| 2 | Grade A or S run | Rare weight increased by 5 points vs Grade C |
| 3 | Rarity fallback | If no template for selected rarity, falls back to common without crash |
| 4 | epic/legendary/mythic items | Never dropped in this patch |

### Save and Persistence

| # | Test | Expected |
|---|------|----------|
| 1 | Close game after run | Reward items persist in inventory on next session |
| 2 | item.source field | Each reward item has source = "run_reward" |
| 3 | instance_id format | IDs are unique, format is "template_id_NNNN" |
| 4 | No auto-equip | Equipped slots unchanged after reward grant |

### Training Inventory After Run

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training → Equipment after run | New reward items visible in inventory grid |
| 2 | Select reward item | Detail panel shows name, slot, rarity, level 0, stat |
| 3 | Equip reward item | Works normally; slot panel updates |
| 4 | Upgrade reward item | Works normally; cost applies |
| 5 | Filters | Slot/State/Sort filters work on reward items same as other items |

### Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Starter pack flow | Unaffected; popup still appears on first Training open |
| 2 | Training upgrades | Unaffected |
| 3 | Currency rewards | Unaffected; currency calculation unchanged |
| 4 | Goals and mastery | Unaffected |
| 5 | In-run combat, abilities, evolutions | Entirely unaffected |
| 6 | Stage flow, boss flow | Unchanged |
| 7 | No gacha/affixes/drops/crafting/fusion/player-facing Sell/auto-equip added | Diff shows none of these |

---

## Equipment Rarity / Stat Presentation (EquipmentFormat)

| # | Test | Expected |
|---|------|----------|
| 1 | Inspect an inventory cell with a common item | Cell shows "Cmn" rarity short tag; unselected cell has a subtle gray-white tint |
| 2 | Inspect an inventory cell with an uncommon item | Cell shows "Unc" and has a green tint |
| 3 | Inspect an inventory cell with a rare item | Cell shows "Rar" and has a blue tint |
| 4 | Click an occupied inventory cell | Item action popup title shows the item display name; detail shows "Rarity: Common/Uncommon/Rare" line |
| 5 | Inspect an equipped slot button | Shows "Lv N Cmn" (or the appropriate rarity short tag) |
| 6 | Inventory detail — stat line | Shows "+5 Attack Damage" for attack_damage; "+10% Ability Damage" for ability_damage; "-8% Ability Cooldown" for cooldown |
| 7 | Inventory detail — Next Level line | Shows "Next Level: +X.XX StatType" for items below max level; hidden at max level |
| 8 | Starter Pack popup item list | Shows "Name  —  Slot  —  Rarity" format for all 6 starter items |
| 9 | Victory/GameOver screen item rewards | Each item line shows "Name  —  Slot  —  Rarity" format |
| 10 | Sort by Rar High | Items ordered mythic→legendary→epic→rare→uncommon→common; empty cells follow |
| 11 | Sort by Rar Low | Items ordered common→uncommon→rare→epic→legendary→mythic; empty cells follow |
| 12 | Inspect diff | No balance, stat values, reward chances, quantities, hero kits, or combat changes |

---

## Inventory Management QoL (Lock / Favorite / Dismantle)

### Lock

| # | Test | Expected |
|---|------|----------|
| 1 | Click an occupied inventory cell | Item action popup opens with Lock button enabled |
| 2 | Press Lock on an unlocked item | Button text changes to "Unlock"; cell shows [L] marker; item detail shows "Locked: Yes" |
| 3 | Press Unlock on a locked item | Button text changes to "Lock"; [L] marker removed; item detail shows "Locked: No" |
| 4 | Lock an item, then inspect Dismantle | Dismantle button is disabled and muted |
| 5 | Lock state persists across sessions | Reload game; locked item still shows [L] and Dismantle is still disabled |

### Favorite

| # | Test | Expected |
|---|------|----------|
| 1 | Click an occupied cell | [*]On button visible and enabled in popup |
| 2 | Press [*]On to favorite an item | Button changes to "[*]Off"; cell shows [*] marker; item detail shows "Favorite: Yes" |
| 3 | Press [*]Off to unfavorite | Button changes to "[*]On"; [*] marker removed; item detail shows "Favorite: No" |
| 4 | Favorite state persists across sessions | Reload game; item still shows [*] marker |

### Dismantle / Gold / Materials

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training -> Equipment | Currency label remains; Gold label is visible and starts at 0 on migrated saves; Materials shows none when all balances are 0 |
| 2 | Click an occupied inventory cell | Sell button is gone; Dismantle button is visible in the item action popup |
| 3 | Click an unequipped, unlocked item | Dismantle button is enabled; detail shows Gold/material reward |
| 4 | Press Dismantle | Confirmation opens with item name, Gold reward, and material reward |
| 5 | Cancel Dismantle | Dialog closes; item remains in inventory; Gold/materials unchanged |
| 6 | Confirm Dismantle | Item removed from inventory; Gold increases; matching rarity material increases; popup closes; grid refreshes |
| 7 | Favorite item -> Dismantle | Confirmation includes "Warning: this item is marked as Favorite." |
| 8 | Common item | Awards common_dust |
| 9 | Equipped item | Dismantle disabled and muted; item detail shows "Cannot dismantle: Equipped item cannot be dismantled." |
| 10 | Locked item | Dismantle disabled and muted; item detail shows "Cannot dismantle: Locked item cannot be dismantled." |
| 11 | Uncommon item | Awards uncommon_dust |
| 12 | Rare item | Awards rare_dust |
| 13 | Upgrade an item after earning Gold/materials | Upgrade spends Gold/materials only; old Training/progression currency is unchanged |
| 14 | Restart game after dismantle | Gold and equipment_materials persist in `user://superheroes_meta_progress.json` |

### Capacity Display

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training → Equipment tab | Inventory header shows "(N / 60)" capacity label |
| 2 | Grant items to reach capacity | Label shows "(60 / 60)" in normal color |
| 3 | Exceed soft capacity (debug or reward) | Label turns warning/amber color |
| 4 | Capacity never blocks grants | Items above 60 are accepted; no error; just label color change |

### Sort Modes

| # | Test | Expected |
|---|------|----------|
| 1 | Set Sort to "Fav First" | All favorited items appear before non-favorited items; within each group, order is by original Default sort |
| 2 | Set Sort to "Newest" | Items ordered by created_index descending (most recently granted first) |
| 3 | Set Sort to "Rar High" | Mythic → … → Common ordering |
| 4 | Set Sort to "Rar Low" | Common → … → Mythic ordering |

### Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Equip flow | Unaffected; equipping still free; Equip button still works |
| 2 | Upgrade flow | Unaffected; upgrade cost/level unchanged |
| 3 | Training tab | Entirely unaffected |
| 4 | Item reward flow | Unaffected; item count/rarity unchanged |
| 5 | In-run combat, abilities, evolutions | Entirely unaffected |
| 6 | No gacha/drops/affixes/crafting/multi-dismantle/auto-sell/hard-cap added | Diff shows none of these |

---

## Inventory Actions Popup UI Rework

### Main Inventory Panel

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training → Equipment tab | Main Inventory panel shows only: Inventory title + capacity label + hint text + filter row + grid |
| 2 | Inspect main panel | No action buttons (Equip/Upgrade/Lock/Favorite/Dismantle) in the main panel; no detail text label in the main panel |
| 3 | Inspect filter row | Slot / State / Sort OptionButtons are present and functional |
| 4 | Inventory grid | 5-column grid fills the remaining height; items and empty cells render correctly |

### Item Action Popup

| # | Test | Expected |
|---|------|----------|
| 1 | Click an occupied inventory cell | Item action popup opens near center of screen; title shows item display name |
| 2 | Popup content | Scrollable detail text: slot, rarity, level, status (EQUIPPED/In Inventory), Locked, Favorite, gameplay note, stat, next-level stat, Dismantle reward; action rows with Equip + Upgrade and Lock + Favorite + Dismantle + Close |
| 3 | Click a different occupied cell while popup is open | Popup content updates to new item; popup does NOT re-center (stays in place) |
| 4 | Click an empty cell while popup is open | Popup closes |
| 5 | Press Close button in popup | Popup closes |
| 6 | Lock/Favorite/Upgrade/Equip action from popup | Action applies; grid refreshes; popup stays open in place (no re-center) |
| 7 | Dismantle action from popup | Confirmation dialog opens; on confirm, popup closes after dismantle; grid and Gold/material labels refresh |
| 8 | Equip action for item already equipped | Equip button shows "Equipped" and is disabled |
| 9 | Lock button state | "Lock" when item is unlocked; "Unlock" when locked |
| 10 | Favorite button state | "[*]On" when not favorited; "[*]Off" when favorited |
| 11 | Dismantle button state | Disabled+muted when item is locked or equipped; enabled otherwise |

### Equipped Slot Popup (regression)

| # | Test | Expected |
|---|------|----------|
| 1 | Click a filled slot button in the Equipped Gear panel | Equipped slot popup opens (separate from item action popup) showing item name, level, stat bonus |
| 2 | Click Unequip in slot popup | Item moves back to inventory; slot shows empty; slot popup closes |
| 3 | Click an empty slot button | Slot popup opens with "No item equipped" text; Unequip disabled |

### Scope Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Training upgrades | Unaffected |
| 2 | Currency, mastery, goals | Unaffected |
| 3 | In-run combat, abilities, evolutions | Entirely unaffected |
| 4 | Item reward flow | Unaffected |
| 5 | Starter pack flow | Unaffected |
| 6 | No gacha/drops/affixes/crafting/fusion/multi-dismantle/auto-sell/hard-cap added | Diff shows none of these |

---

## Starter Equipment Grant Flow

### Popup Trigger

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training for the first time (fresh save) | Starter Equipment Pack popup appears automatically |
| 2 | Popup header and body | Title: "Starter Equipment Pack"; description text visible |
| 3 | Popup item list | Shows 6 items: Power Core, Reinforced Suit, Awareness Emblem, Striker Gauntlets, Runner Boots, Shield Artifact; each shows slot and rarity |
| 4 | Popup has Accept button | Button is visible and enabled |

### Accept Flow

| # | Test | Expected |
|---|------|----------|
| 1 | Click Accept | Popup closes immediately |
| 2 | After Accept — inventory grid | 6 new items appear in the inventory grid (one per slot) |
| 3 | After Accept — equipped slots panel | All 6 slot panels remain empty (no auto-equip) |
| 4 | Open Training again (same session) | Popup does NOT reappear |
| 5 | Restart game, open Training | Popup does NOT reappear (grant tracked in save) |

### Grant Persistence

| # | Test | Expected |
|---|------|----------|
| 1 | `MetaProgressionManager.has_equipment_grant("starter_pack_v1")` after Accept | Returns `true` |
| 2 | `MetaProgressionManager.can_claim_starter_equipment()` after Accept | Returns `false` |
| 3 | Inspect save data | `equipment_grants.starter_pack_v1 = true`; 6 items in `inventory_items` with `source = "starter_pack_v1"` |

### Equip After Grant

| # | Test | Expected |
|---|------|----------|
| 1 | Select any granted item → click Equip | Item moves to equipped slot; slot panel updates |
| 2 | Switch to a different hero | Equipped slot remains filled (global equipment model) |
| 3 | Start a run after equipping | Equipment stat modifiers apply to the run (`get_equipment_stat_modifiers_for_hero` returns non-zero) |
| 4 | Return to meta, check equipped slot | Equipped slot still shows the item from before the run |

### Global Shared Equipment

| # | Test | Expected |
|---|------|----------|
| 1 | Equip item as Hero A, view as Hero B | Slot panel shows same equipped item for Hero B |
| 2 | Unequip item as Hero B, view as Hero A | Slot panel shows empty for Hero A |
| 3 | Equip different item in same slot as Hero A | Slot panel updates for both heroes |

### Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Training tab purchases | Unaffected |
| 2 | Hero unlock, goals, mastery, stage mastery, currency | All unaffected |
| 3 | In-run combat, abilities, evolutions, waves | Entirely unaffected |
| 4 | No gacha, random items, enemy drops, random affixes, crafting, auto-equip added | Diff shows none of these |

---

## Loadout Power Summary + Item Power

### Power Visibility in Inventory Grid

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training → Equipment tab, look at inventory grid | Each occupied cell shows 4 lines: name / slot+rarity / Lv N/10 / PWR X |
| 2 | Item at level 0 | Cell shows "PWR 0" |
| 3 | Upgrade an item | Cell PWR X updates immediately after upgrade |
| 4 | Open inventory with no items | Empty cells show "+  Empty"; no PWR line on empty cells |

### Power Visibility: Loadout Button

| # | Test | Expected |
|---|------|----------|
| 1 | Open Training → Equipment tab, no items equipped | Equipped Gear header shows "Loadout: 0" button |
| 2 | Equip an item at level 5 (attack_damage) | Button updates to "Loadout: 50" (1.0 × 5 × 10) |
| 3 | Equip/unequip items | Button score updates each time |
| 4 | Upgrade an equipped item | Button score increases |

### Item Power in Popups

| # | Test | Expected |
|---|------|----------|
| 1 | Click an occupied inventory cell | Item action popup shows "Power: N" line after the Level line |
| 2 | Item at level 0 | "Power: 0" (no stat contribution yet) |
| 3 | Upgrade item from level 1 to level 5, re-open popup | Power increases proportionally; no rarity bonus is added |
| 4 | Compare common vs mythic item with same stat and same level | Both show identical power; rarity does not inflate score |
| 5 | Click an occupied equipped slot button | Equipped slot popup shows "Power: N" after the Level line |
| 6 | Click an empty equipped slot button | Slot popup shows; no power line needed (item is absent) |

### Loadout Summary Popup Open/Close

| # | Test | Expected |
|---|------|----------|
| 1 | Click "Loadout: X" button with no gear equipped | Popup opens; shows Power: 0, 0 / 6 slots, all 6 empty slots, no stats, no sets, no items |
| 2 | Click "Loadout: X" with some gear equipped | Popup shows power score, equipped count, stats, active sets, strongest/weakest items |
| 3 | Click X / Close button in popup | Popup closes; Equipment UI remains usable |
| 4 | Open popup, then equip an item | Popup content updates without re-centering |
| 5 | Open popup, then upgrade an item | Popup power score increases in-place |

### Power Score Correctness

| # | Test | Expected |
|---|------|----------|
| 1 | Equip Power Core (attack_damage +1/lv) at level 5 | Item power = 1.0 × 5 × 10 = 50 |
| 2 | Equip Momentum Boots (shield_capacity +1/lv) at level 4 | Item power = 1.0 × 4 × 25 = 100 |
| 3 | Equip Cooldown Core (support_damage +2/lv) at level 3 | Item power = 2.0 × 3 × 8 = 48 |
| 4 | Equip all 6 slots | Loadout Power = sum of all 6 item powers + set bonus power |
| 5 | Active 2-piece Storm Set bonus (ability_cooldown: 0.05) | Set bonus power = round(0.05 × 8) = 0; small contribution |
| 6 | Active 2-piece Fury Set bonus (attack_damage: 3) | Set bonus power includes round(3 × 10) = 30 |
| 7 | Strongest/Weakest item display | Strongest shows highest-power item; Weakest shows lowest; empty slots excluded |

### Flat Stat Item Template Validation

| # | Test | Expected |
|---|------|----------|
| 1 | Open Cooldown Core popup (was ability_cooldown, now support_damage) | Shows "+2 Support Damage / level", not percent |
| 2 | Open Awareness Emblem popup (was xp_gain, now mark_damage) | Shows "+1 Mark Damage / level" |
| 3 | Open Force Gauntlets popup (was ability_damage, now impact_damage) | Shows "+1.2 Impact Damage / level" |
| 4 | Open Runner Boots popup (was move_speed, now max_health) | Shows "+5 Max HP / level" |
| 5 | Open Momentum Boots popup (was move_speed, now shield_capacity) | Shows "+1 Shield Capacity / level" |
| 6 | Open Fury Artifact popup (was low_health_damage, now rage_gain) | Shows "+1 Rage Gain / level" |
| 7 | Open Apex Artifact popup (was ability_damage, now support_damage) | Shows "+2.5 Support Damage / level" |
| 8 | No item in any template shows move_speed bonus | Diff confirms no move_speed in item templates |

### Storm Set Bonus Validation

| # | Test | Expected |
|---|------|----------|
| 1 | Equip 2 storm_set items | 2-piece bonus: "-5% Ability Cooldown" (not Move Speed) |
| 2 | Equip 4 storm_set items | 4-piece bonus: "-8% Ability Cooldown" |
| 3 | Equip all 6 storm_set slots (if possible) | 6-piece bonus: "+10% Ability Damage, +5% XP Gain" (not Move Speed) |

### Scope Regression

| # | Test | Expected |
|---|------|----------|
| 1 | Start a run after opening Loadout popup | Arena starts normally; no crash; no combat stat change from power score |
| 2 | Upgrade an item | Upgrade cost unchanged; power score updates as expected |
| 3 | Dismantle an item | Dismantle reward unchanged; power score updates |
| 4 | Active set bonuses | Set bonus values unchanged; power score reflects them but does not modify them |
| 5 | Item reward flow | Reward count and rarity rules unchanged |
| 6 | Training upgrades | Unaffected |
| 7 | Hero kits, evolutions, boss flow, in-run 4/4/4 rules | Entirely unaffected |
| 8 | No gacha, crafting, new items/materials/sets, auto-equip, stages/zones added | Diff shows none of these |

