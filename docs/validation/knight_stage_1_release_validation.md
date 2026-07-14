# Knight Stage 1 release validation

## Stable contract

- 27 Knight upgrades: 9 attack, 9 passive, 9 active; every line has five levels.
- Nine evolutions unlock only at their exact 5/5/5 triples.
- Upgrade offers uniformly shuffle the complete eligible pool, then take up to three unique options. Rarity, category, started lines, and evolution paths do not steer offers.
- The run remains a 300-second 3D survival slice. No balance values were changed during release finalization without measured evidence.

## Required manual smoke flow

1. Launch `Main.tscn`, start a Vanguard run, move, dash, and hit an enemy with Fury Strike.
2. Confirm Ground Shockwave, Earthsplitter, Seismic Fan, and Crushing Storm effects disappear after their short lifetimes.
3. Use Rage Wave, Shield Bash, and Crushing Leap; pause/unpause during cooldowns and delayed effects.
4. Take random level-up offers until an evolution is ready; verify multiple ready evolutions are selected sequentially.
5. Restart and end a run through death or victory; begin a second run and verify no upgrades, effects, or temporary indicators carry over.
6. Export Web and verify `export/index.html`, readable level-up cards, pause modals, and procedural crack visuals.

## Known limitations

- Full 300-second XP/outcome telemetry and browser smoke results require an interactive controlled run; they are not inferred from the editor parse check.
- No CI workflow is added because this repository does not pin a downloadable Godot binary version for reliable automation.
