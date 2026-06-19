extends CanvasLayer

const REFRESH_INTERVAL := 0.25

var _player: Node = null
var _auto_attack: Node = null
var _ability_manager: Node = null
var _upgrade_manager: Node = null
var _powerup_manager: Node = null
var _enemy_spawner: Node = null

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
	bg.size = Vector2(318.0, 530.0)
	bg.position = Vector2(4.0, 4.0)
	add_child(bg)

	_stats_label = Label.new()
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_label.position = Vector2(10.0, 8.0)
	_stats_label.size = Vector2(302.0, 520.0)
	_stats_label.add_theme_font_size_override("font_size", 11)
	_stats_label.text = "DEBUG OFF"
	add_child(_stats_label)


func setup(p_player: Node, p_auto_attack: Node, p_ability_manager: Node, p_upgrade_manager: Node, p_powerup_manager: Node, p_enemy_spawner: Node) -> void:
	_player = p_player
	_auto_attack = p_auto_attack
	_ability_manager = p_ability_manager
	_upgrade_manager = p_upgrade_manager
	_powerup_manager = p_powerup_manager
	_enemy_spawner = p_enemy_spawner


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
		var dmg: int = _auto_attack.get("attack_damage") if _auto_attack.get("attack_damage") != null else 0
		var interval: float = _auto_attack.get("attack_interval") if _auto_attack.get("attack_interval") != null else 0.0
		var count: int = _auto_attack.get("projectile_count") if _auto_attack.get("projectile_count") != null else 0
		var pierce: int = _auto_attack.get("projectile_pierce") if _auto_attack.get("projectile_pierce") != null else 0
		var spread: float = _auto_attack.get("projectile_spread_degrees") if _auto_attack.get("projectile_spread_degrees") != null else 0.0
		var size_m: float = _auto_attack.get("projectile_size_multiplier") if _auto_attack.get("projectile_size_multiplier") != null else 1.0
		var expl: float = _auto_attack.get("projectile_explosion_radius") if _auto_attack.get("projectile_explosion_radius") != null else 0.0
		var bounce: int = _auto_attack.get("projectile_bounce") if _auto_attack.get("projectile_bounce") != null else 0
		lines.append("DMG: %d  Interval: %.2f  Count: %d" % [dmg, interval, count])
		lines.append("Pierce: %d  Spread: %.0f  Size: %.2f" % [pierce, spread, size_m])
		lines.append("Explosion R: %.0f  Bounce: %d" % [expl, bounce])
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
		if _ability_manager.has_method("get_ability_state"):
			nova_cd_remaining = float(_ability_manager.get_ability_state(1).get("cooldown_remaining", 0.0))
			laser_cd_remaining = float(_ability_manager.get_ability_state(2).get("cooldown_remaining", 0.0))
			slam_cd_remaining = float(_ability_manager.get_ability_state(3).get("cooldown_remaining", 0.0))

		lines.append("Nova: dmg=%d r=%.0f cd=%.1f/%.1f" % [nova_dmg, nova_r, nova_cd_remaining, nova_cd])
		lines.append("Laser: dmg=%d r=%.0f w=%.0f cd=%.1f/%.1f" % [laser_dmg, laser_r, laser_w, laser_cd_remaining, laser_cd])
		lines.append("Slam: dmg=%d r=%.0f cd=%.1f/%.1f" % [slam_dmg, slam_r, slam_cd_remaining, slam_cd])
		lines.append("Synergy: nova=%s laser2=%s slam2=%s" % [nova_aftershock, laser_double, slam_second])
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
		elif _upgrade_manager.has_method("get_dominant_archetype"):
			lines.append("Dominant: %s" % _upgrade_manager.get_dominant_archetype())
	else:
		lines.append("-- Build: null --")

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

	return "\n".join(lines)
