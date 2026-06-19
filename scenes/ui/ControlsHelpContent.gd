extends RefCounted


static func get_sections() -> Array[Dictionary]:
	return [
		{
			"title": "Basic Controls",
			"lines": [
				"WASD / Arrow keys - move",
				"Space - dash",
				"Escape - pause or close menus",
				"H / F11 - open or close Help / Controls"
			]
		},
		{
			"title": "Active Abilities",
			"lines": [
				"J - ability slot 1",
				"K - ability slot 2",
				"L - ability slot 3",
				"Mobile buttons cast the same ability slots"
			]
		},
		{
			"title": "Run Systems",
			"lines": [
				"Collect XP gems to level up",
				"Choose one of three upgrades when leveling",
				"Powerups can heal, shield, damage, magnetize XP, or boost stats",
				"Survive until the final boss objective, then defeat the boss"
			]
		},
		{
			"title": "Meta / Progression",
			"lines": [
				"Select a hero and stage before a run",
				"Run rewards grant local training currency after victory or defeat",
				"Training upgrades apply to future runs only"
			]
		},
		{
			"title": "Debug Mode",
			"lines": [
				"F12 / F10 - toggle Debug Mode",
				"F1 / F2 - debug level up while Debug Mode is on",
				"F3-F9 - validation tools while Debug Mode is on"
			]
		},
		{
			"title": "Mobile Controls",
			"lines": [
				"Virtual joystick moves the hero",
				"Ability buttons show cooldown text",
				"Pause button opens the same pause menu"
			]
		}
	]
