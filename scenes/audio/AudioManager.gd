extends Node

@export var ui_click_stream: AudioStream
@export var projectile_hit_stream: AudioStream
@export var enemy_death_stream: AudioStream
@export var pickup_stream: AudioStream
@export var level_up_stream: AudioStream
@export var game_over_stream: AudioStream

var settings_manager: Node

@onready var ui_click_player: AudioStreamPlayer = get_node_or_null("UiClickPlayer")
@onready var projectile_hit_player: AudioStreamPlayer = get_node_or_null("ProjectileHitPlayer")
@onready var enemy_death_player: AudioStreamPlayer = get_node_or_null("EnemyDeathPlayer")
@onready var pickup_player: AudioStreamPlayer = get_node_or_null("PickupPlayer")
@onready var level_up_player: AudioStreamPlayer = get_node_or_null("LevelUpPlayer")
@onready var game_over_player: AudioStreamPlayer = get_node_or_null("GameOverPlayer")


func _ready() -> void:
	_assign_streams()
	apply_settings()


func setup(new_settings_manager: Node = null) -> void:
	settings_manager = new_settings_manager
	if settings_manager != null and settings_manager.has_signal("settings_changed") and not settings_manager.settings_changed.is_connected(apply_settings):
		settings_manager.settings_changed.connect(apply_settings)

	_assign_streams()
	apply_settings()


func play_ui_click() -> void:
	_play_player(ui_click_player)


func play_projectile_hit() -> void:
	_play_player(projectile_hit_player)


func play_enemy_death() -> void:
	_play_player(enemy_death_player)


func play_pickup() -> void:
	_play_player(pickup_player)


func play_level_up() -> void:
	_play_player(level_up_player)


func play_game_over() -> void:
	_play_player(game_over_player)


func apply_settings() -> void:
	var volume := 1.0
	if settings_manager != null:
		var master := float(settings_manager.get_setting("master_volume", 1.0))
		var sfx := float(settings_manager.get_setting("sfx_volume", 1.0))
		var muted := bool(settings_manager.get_setting("mute_all", false))
		volume = 0.0 if muted else master * sfx

	var volume_db := _linear_to_db_safe(volume)
	for player in _get_players():
		player.volume_db = volume_db


func _linear_to_db_safe(value: float) -> float:
	if value <= 0.001:
		return -80.0

	return linear_to_db(clampf(value, 0.0, 1.0))


func _assign_streams() -> void:
	if ui_click_player != null:
		ui_click_player.stream = ui_click_stream
	if projectile_hit_player != null:
		projectile_hit_player.stream = projectile_hit_stream
	if enemy_death_player != null:
		enemy_death_player.stream = enemy_death_stream
	if pickup_player != null:
		pickup_player.stream = pickup_stream
	if level_up_player != null:
		level_up_player.stream = level_up_stream
	if game_over_player != null:
		game_over_player.stream = game_over_stream


func _play_player(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return

	player.play()


func _get_players() -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = []
	for player in [ui_click_player, projectile_hit_player, enemy_death_player, pickup_player, level_up_player, game_over_player]:
		if player != null:
			players.append(player)

	return players
