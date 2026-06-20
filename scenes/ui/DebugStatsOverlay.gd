extends CanvasLayer

const REFRESH_INTERVAL := 0.25

var _player: Node = null
var _auto_attack: Node = null
var _ability_manager: Node = null
var _upgrade_manager: Node = null
var _powerup_manager: Node = null
var _enemy_spawner: Node = null
var _run_manager: Node = null
var _enemy_container: Node = null
var _projectile_container: Node = null
var _pickup_container: Node = null
var _passive_ability_manager: Node = null
var _evolution_manager: Node = null
var _meta_manager: Node = null
var _settings_manager: Node = null

var _debug_enabled: bool = false
var _refresh_timer: float = 0.0

var _stats_label: Label = null


func _ready() -> void:
	layer = 15
	hide()
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.68)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.size = Vector2(336.0, 650.0)
	bg.position = Vector2(4.0, 4.0)
	add_child(bg)

	_stats_label = Label.new()
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_label.position = Vector2(10.0, 8.0)
	_stats_label.size = Vector2(320.0, 640.0)
	_stats_label.add_theme_font_size_override("font_size", 11)
	_stats_label.text = "DEBUG OFF"
	add_child(_stats_label)


func setup(p_player: Node, p_auto_attack: Node, p_ability_manager: Node, p_upgrade_manager: Node, p_powerup_manager: Node, p_enemy_spawner: Node, p_run_manager: Node = null, p_enemy_container: Node = null, p_projectile_container: Node = null, p_pickup_container: Node = null, p_passive_ability_manager: Node = null) -> void:
	_player = p_player
	_auto_attack = p_auto_attack
	_ability_manager = p_ability_manager
	_upgrade_manager = p_upgrade_manager
	_powerup_manager = p_powerup_manager
	_enemy_spawner = p_enemy_spawner
	_run_manager = p_run_manager
	_enemy_container = p_enemy_container
	_projectile_container = p_projectile_container
	_pickup_container = p_pickup_container
	_passive_ability_manager = p_passive_ability_manager


func setup_evolution_manager(evolution_manager: Node) -> void:
	_evolution_manager = evolution_manager


func setup_meta_manager(meta_manager: Node) -> void:
	_meta_manager = meta_manager


func setup_settings_manager(settings_manager: Node) -> void:
	_settings_manager = settings_manager


func set_debug_enabled(enabled: bool) -> void:
	_debug_enabled = enabled
	if enabled:
		show()
		refresh_now()
	else:
		hide()


func refresh_now() -> void:
	if _stats_label == null:
		return
	_stats_label.text = _build_stats_text()
	_refresh_timer = 0.0


func _process(delta: float) -> void:
	if not visible or not _debug_enabled:
		return
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		refresh_now()


func _build_stats_text() -> String:
	var lines: PackedStringArray = PackedStringArray()

	lines.append("=== DEBUG ON ===")

	# Run
	if _run_manager != null and is_instance_valid(_run_manager):
		lines.append("-- Run --")
		var run_time: float = _run_manager.get("run_time") if _run_manager.get("run_time") != null else 0.0
		var target_time := 0.0
		if _run_manager.has_method("get_target_run_time"):
			target_time = float(_run_manager.get_target_run_time())
		var final_active: bool = _run_manager.get("is_final_phase_active") if _run_manager.get("is_final_phase_active") != null else false
		lines.append("Time: %.0f / %.0f  Final: %s" % [run_time, target_time, final_active])
		lines.append("Enemies: %d  Projectiles: %d  Pickups: %d" % [
			_count_children(_enemy_container),
			_count_children(_projectile_container),
			_count_children(_pickup_container)
		])

	# Player
	if _player != null and is_instance_valid(_player):
		lines.append("-- Player --")
		var hp: int = _player.get("current_health") if _player.get("current_health") != null else 0
		var max_hp: int = _player.get("max_health") if _player.get("max_health") != null else 0
		var lvl: int = _player.get("level") if _player.get("level") != null else 1
		var xp: int = _player.get("current_xp") if _player.get("current_xp") != null else 0
		var xp_next: int = _player.get("xp_to_next_level") if _player.get("xp_to_next_level") != null else 0
		var spd: float = _player.get("speed") if _player.get("speed") != null else 0.0
		var dash_cd: float = _player.get("dash_cooldown_remaining") if _player.get("dash_cooldown_remaining") != null else 0.0
		var invu: bool = _player.get("debug_invulnerable") if _player.get("debug_invulnerable") != null else false
		var dash_trail: bool = _player.get("dash_damage_trail_enabled") if _player.get("dash_damage_trail_enabled") != null else false
		lines.append("HP: %d/%d  Lvl: %d" % [hp, max_hp, lvl])
		lines.append("XP: %d/%d  Speed: %.0f" % [xp, xp_next, spd])
		lines.append("Dash CD: %.2fs  DBG Invu: %s" % [dash_cd, invu])
		lines.append("Dash trail damage: %s" % dash_trail)
	else:
		lines.append("-- Player: null --")

	# Weapon
	if _auto_attack != null and is_instance_valid(_auto_attack):
		lines.append("-- Weapon --")
		var weapon_id := ""
		if _auto_attack.has_method("get_primary_weapon_id"):
			weapon_id = str(_auto_attack.get_primary_weapon_id())
		if not weapon_id.is_empty():
			lines.append("Primary: %s" % weapon_id)
		var dmg: int = _auto_attack.get("attack_damage") if _auto_attack.get("attack_damage") != null else 0
		var interval: float = _auto_attack.get("attack_interval") if _auto_attack.get("attack_interval") != null else 0.0
		var rng: float = _auto_attack.get("attack_range") if _auto_attack.get("attack_range") != null else 0.0
		var count: int = _auto_attack.get("projectile_count") if _auto_attack.get("projectile_count") != null else 0
		var pierce: int = _auto_attack.get("projectile_pierce") if _auto_attack.get("projectile_pierce") != null else 0
		var spread: float = _auto_attack.get("projectile_spread_degrees") if _auto_attack.get("projectile_spread_degrees") != null else 0.0
		var size_m: float = _auto_attack.get("projectile_size_multiplier") if _auto_attack.get("projectile_size_multiplier") != null else 1.0
		var expl: float = _auto_attack.get("projectile_explosion_radius") if _auto_attack.get("projectile_explosion_radius") != null else 0.0
		var bounce: int = _auto_attack.get("projectile_bounce") if _auto_attack.get("projectile_bounce") != null else 0
		lines.append("DMG: %d  Interval: %.2f  Range: %.0f" % [dmg, interval, rng])
		lines.append("Count: %d  Pierce: %d  Bounce: %d" % [count, pierce, bounce])
		lines.append("Spread: %.0f  Size: %.2f  Expl R: %.0f" % [spread, size_m, expl])
	else:
		lines.append("-- Weapon: null --")

	# Abilities
	if _ability_manager != null and is_instance_valid(_ability_manager):
		lines.append("-- Abilities --")
		var nova_dmg: int = _ability_manager.get("nova_damage") if _ability_manager.get("nova_damage") != null else 0
		var nova_r: float = _ability_manager.get("nova_radius") if _ability_manager.get("nova_radius") != null else 0.0
		var nova_cd: float = _ability_manager.get("nova_cooldown") if _ability_manager.get("nova_cooldown") != null else 0.0
		var laser_dmg: int = _ability_manager.get("laser_damage") if _ability_manager.get("laser_damage") != null else 0
		var laser_r: float = _ability_manager.get("laser_range") if _ability_manager.get("laser_range") != null else 0.0
		var laser_w: float = _ability_manager.get("laser_width") if _ability_manager.get("laser_width") != null else 0.0
		var laser_cd: float = _ability_manager.get("laser_cooldown") if _ability_manager.get("laser_cooldown") != null else 0.0
		var slam_dmg: int = _ability_manager.get("slam_damage") if _ability_manager.get("slam_damage") != null else 0
		var slam_r: float = _ability_manager.get("slam_radius") if _ability_manager.get("slam_radius") != null else 0.0
		var slam_cd: float = _ability_manager.get("slam_cooldown") if _ability_manager.get("slam_cooldown") != null else 0.0
		var nova_aftershock: bool = _ability_manager.get("nova_aftershock_enabled") if _ability_manager.get("nova_aftershock_enabled") != null else false
		var laser_double: bool = _ability_manager.get("laser_double_pulse_enabled") if _ability_manager.get("laser_double_pulse_enabled") != null else false
		var slam_second: bool = _ability_manager.get("slam_second_wave_enabled") if _ability_manager.get("slam_second_wave_enabled") != null else false

		var nova_cd_remaining: float = 0.0
		var laser_cd_remaining: float = 0.0
		var slam_cd_remaining: float = 0.0
		var slot_1_name: String = "Ability 1"
		var slot_2_name: String = "Ability 2"
		var slot_3_name: String = "Ability 3"
		if _ability_manager.has_method("get_ability_state"):
			nova_cd_remaining = float(_ability_manager.get_ability_state(1).get("cooldown_remaining", 0.0))
			laser_cd_remaining = float(_ability_manager.get_ability_state(2).get("cooldown_remaining", 0.0))
			slam_cd_remaining = float(_ability_manager.get_ability_state(3).get("cooldown_remaining", 0.0))
		if _ability_manager.has_method("get_ability_name"):
			slot_1_name = str(_ability_manager.get_ability_name(1))
			slot_2_name = str(_ability_manager.get_ability_name(2))
			slot_3_name = str(_ability_manager.get_ability_name(3))

		lines.append("%s: dmg=%d r=%.0f cd=%.1f/%.1f" % [slot_1_name, nova_dmg, nova_r, nova_cd_remaining, nova_cd])
		lines.append("%s: dmg=%d r=%.0f w=%.0f cd=%.1f/%.1f" % [slot_2_name, laser_dmg, laser_r, laser_w, laser_cd_remaining, laser_cd])
		lines.append("%s: dmg=%d r=%.0f cd=%.1f/%.1f" % [slot_3_name, slam_dmg, slam_r, slam_cd_remaining, slam_cd])
		lines.append("Synergy: nova=%s laser2=%s slam2=%s" % [nova_aftershock, laser_double, slam_second])
		if _ability_manager.has_method("get_hero_kit_state"):
			var kit: Dictionary = _ability_manager.get_hero_kit_state()
			lines.append("Kit: %s (%s)" % [kit.get("kit_id", "generic"), kit.get("passive_name", "None")])
			match str(kit.get("kit_id", "")):
				"solar_guardian":
					lines.append("Solar Charge: %.0f / %.0f" % [float(kit.get("solar_charge", 0.0)), float(kit.get("solar_charge_max", 0.0))])
				"night_tactician":
					lines.append("Tactical Mark: %s" % str(kit.get("tactical_mark_target", "none")))
				"fury_vanguard":
					lines.append("Rage: %.0f / %.0f" % [float(kit.get("rage", 0.0)), float(kit.get("rage_max", 0.0))])
	else:
		lines.append("-- Abilities: null --")

	# Build
	if _upgrade_manager != null and is_instance_valid(_upgrade_manager):
		lines.append("-- Build --")
		if _upgrade_manager.has_method("debug_get_build_state"):
			var build: Dictionary = _upgrade_manager.debug_get_build_state()
			lines.append("Dominant: %s" % build.get("dominant_archetype", "none"))
			var pts: Dictionary = build.get("archetype_points", {})
			var pts_short: Array[String] = []
			for arch in pts:
				pts_short.append("%s:%d" % [str(arch).left(3), int(pts[arch])])
			lines.append("Points: [%s]" % ", ".join(pts_short))
			lines.append("Upgrades: %d  Synergies: %d" % [
				build.get("selected_upgrade_history_size", 0),
				build.get("unlocked_synergy_upgrade_ids", []).size()
			])
			lines.append("Build-def: %d picked / %d available" % [
				build.get("selected_build_defining_upgrade_ids", []).size(),
				build.get("unlocked_build_defining_upgrade_ids", []).size()
			])
			var slot_state: Dictionary = build.get("slot_state", {})
			if slot_state.is_empty() and _upgrade_manager.has_method("debug_get_slot_state"):
				slot_state = _upgrade_manager.debug_get_slot_state()
			if not slot_state.is_empty():
				lines.append("Slots: A %d/%d  P %d/%d  Act %d/%d" % [
					int(slot_state.get("attack", {}).get("used", 0)),
					int(slot_state.get("attack", {}).get("max", 0)),
					int(slot_state.get("passive", {}).get("used", 0)),
					int(slot_state.get("passive", {}).get("max", 0)),
					int(slot_state.get("active", {}).get("used", 0)),
					int(slot_state.get("active", {}).get("max", 0)),
				])
				lines.append("Attack ids: %s" % _format_slot_ids(slot_state, "attack"))
				lines.append("Passive ids: %s" % _format_slot_ids(slot_state, "passive"))
				lines.append("Active ids: %s" % _format_slot_ids(slot_state, "active"))
		elif _upgrade_manager.has_method("get_dominant_archetype"):
			lines.append("Dominant: %s" % _upgrade_manager.get_dominant_archetype())
	else:
		lines.append("-- Build: null --")

	if _evolution_manager != null and is_instance_valid(_evolution_manager):
		lines.append("-- Evolutions --")
		if _evolution_manager.has_method("debug_get_evolution_state"):
			var evo: Dictionary = _evolution_manager.debug_get_evolution_state()
			lines.append("Available: %d" % int(evo.get("available_count", 0)))
			var titles: Array = evo.get("applied_titles", [])
			lines.append("Applied: %s" % (", ".join(titles) if not titles.is_empty() else "None"))

	if _passive_ability_manager != null and is_instance_valid(_passive_ability_manager):
		lines.append("-- Passives --")
		if _passive_ability_manager.has_method("get_passive_state"):
			var passive_state: Dictionary = _passive_ability_manager.get_passive_state()
			var levels: Dictionary = passive_state.get("levels", {})
			if levels.is_empty():
				lines.append("Selected: none")
			else:
				var passive_lines: PackedStringArray = []
				for passive_id in levels:
					passive_lines.append("%s:%d" % [str(passive_id), int(levels[passive_id])])
				lines.append("Selected: %s" % ", ".join(passive_lines))
			var timers: Dictionary = passive_state.get("timers", {})
			var timer_lines: PackedStringArray = []
			for timer_id in timers:
				if levels.has(timer_id):
					timer_lines.append("%s %.1fs" % [str(timer_id).left(6), float(timers[timer_id])])
			if not timer_lines.is_empty():
				lines.append("Timers: %s" % ", ".join(timer_lines))
			lines.append("Pickup bonus: %.0f  Shield: %d/%d" % [
				float(passive_state.get("pickup_radius_bonus", 0.0)),
				int(passive_state.get("shield_charges", 0)),
				int(passive_state.get("shield_max_charges", 0)),
			])
			lines.append("Last: %s" % str(passive_state.get("last_event", "none")))

	# Shield / buffs from PlayerBuffManager
	if _player != null and is_instance_valid(_player):
		var buff_manager: Node = _player.get_node_or_null("PlayerBuffManager")
		if buff_manager != null:
			lines.append("-- Buffs --")
			var shield: int = 0
			if buff_manager.has_method("get_shield_charges"):
				shield = buff_manager.get_shield_charges()
			lines.append("Shield charges: %d" % shield)
			if buff_manager.has_method("get_active_buffs"):
				var buffs: Dictionary = buff_manager.get_active_buffs()
				if buffs.is_empty():
					lines.append("Active buffs: none")
				else:
					for buff_id in buffs:
						var b: Dictionary = buffs[buff_id]
						lines.append("  %s: %.1fs" % [buff_id, b.get("time_left", 0.0)])

	# Spawner wiring
	if _enemy_spawner != null and is_instance_valid(_enemy_spawner):
		lines.append("-- Spawner --")
		if _enemy_spawner.has_method("debug_get_spawn_state"):
			var spawn: Dictionary = _enemy_spawner.debug_get_spawn_state()
			lines.append("Profile: %s  MaxAlive: %d" % [
				spawn.get("stage_profile", "?"),
				int(spawn.get("max_alive_enemies", 0)),
			])
			lines.append("Interval: %.2f  WaveEvery: %.0fs" % [
				float(spawn.get("spawn_interval", 0.0)),
				float(spawn.get("wave_interval", 0.0)),
			])
			var last_pkg: String = str(spawn.get("last_wave_package", ""))
			lines.append("Last pkg: %s" % (last_pkg if last_pkg != "" else "(none yet)"))
		if _enemy_spawner.has_method("debug_get_powerup_wiring_state"):
			var wiring: Dictionary = _enemy_spawner.debug_get_powerup_wiring_state()
			lines.append("Pickup scene: %s" % wiring.get("pickup_scene_assigned", false))
			lines.append("PM assigned: %s" % wiring.get("powerup_manager_assigned", false))
			lines.append("Container: %s" % wiring.get("pickup_container_valid", false))
			lines.append("Drop chance: %.2f" % wiring.get("drop_chance", 0.0))
		else:
			lines.append("(no wiring state method)")
	else:
		lines.append("-- Spawner: null --")

	if _meta_manager != null and is_instance_valid(_meta_manager):
		lines.append("-- Meta --")
		if _meta_manager.has_method("get_currency"):
			lines.append("Currency: %d" % int(_meta_manager.get_currency()))
		if _meta_manager.has_method("get_progress_summary"):
			var ps: Dictionary = _meta_manager.get_progress_summary()
			lines.append("Runs: %d  Wins: %d" % [int(ps.get("total_runs", 0)), int(ps.get("total_victories", 0))])
		if _meta_manager.has_method("get_debug_training_summary"):
			var training: Dictionary = _meta_manager.get_debug_training_summary()
			var training_lines: PackedStringArray = []
			for hero_id in training:
				var levels: Dictionary = training.get(hero_id, {})
				if levels.is_empty():
					continue
				var parts: PackedStringArray = []
				for upgrade_id in levels:
					parts.append("%s:%d" % [str(upgrade_id).replace("meta_", ""), int(levels[upgrade_id])])
				training_lines.append("%s [%s]" % [str(hero_id), ", ".join(parts)])
			if training_lines.is_empty():
				lines.append("Training: none")
			else:
				lines.append("Training: %s" % " | ".join(training_lines))

	# Feedback settings
	if _settings_manager != null and is_instance_valid(_settings_manager):
		lines.append("-- Feedback --")
		var shake_on: bool = bool(_settings_manager.get_setting("screen_shake_enabled", true))
		var shake_int: float = float(_settings_manager.get_setting("screen_shake_intensity", 1.0))
		var ft_on: bool = bool(_settings_manager.get_setting("floating_text_enabled", true))
		var flash_on: bool = bool(_settings_manager.get_setting("impact_flash_enabled", true))
		lines.append("Shake: %s  Intensity: %.2f" % [shake_on, shake_int])
		lines.append("FloatText: %s  ImpactFlash: %s" % [ft_on, flash_on])

	return "\n".join(lines)


func _count_children(node: Node) -> int:
	return node.get_child_count() if node != null and is_instance_valid(node) else 0


func _format_slot_ids(slot_state: Dictionary, category: String) -> String:
	var category_state: Dictionary = slot_state.get(category, {})
	var ids: Array = category_state.get("selected", [])
	return ", ".join(ids) if not ids.is_empty() else "none"
