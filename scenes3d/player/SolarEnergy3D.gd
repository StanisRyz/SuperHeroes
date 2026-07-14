class_name SolarEnergy3D
extends Node

signal resource_state_changed(resource_name: String, current: float, maximum: float, empowered: bool)

const GAIN_PER_SECOND := 2.0
const MAX_ENERGY := 100.0
const EMPOWERED_DURATION := 15.0
const EMPOWERED_DAMAGE_MULTIPLIER := 2.0

var energy := 0.0
var empowered_remaining := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	publish_state()

func _process(delta: float) -> void:
	if empowered_remaining > 0.0:
		empowered_remaining = maxf(empowered_remaining - delta, 0.0)
		publish_state()
		return
	energy = minf(energy + GAIN_PER_SECOND * delta, MAX_ENERGY)
	if energy >= MAX_ENERGY:
		energy = 0.0
		empowered_remaining = EMPOWERED_DURATION
	publish_state()

func get_damage_multiplier() -> float:
	return EMPOWERED_DAMAGE_MULTIPLIER if empowered_remaining > 0.0 else 1.0

func get_resource_state() -> Dictionary:
	return {"resource_name": "Solar Energy", "current": energy, "maximum": MAX_ENERGY, "empowered": empowered_remaining > 0.0, "empowered_remaining": empowered_remaining, "damage_multiplier": get_damage_multiplier()}

func reset_run_state() -> void:
	energy = 0.0
	empowered_remaining = 0.0
	publish_state()

func publish_state() -> void:
	resource_state_changed.emit("Solar Energy" if empowered_remaining <= 0.0 else "Solar Energy (Empowered)", energy if empowered_remaining <= 0.0 else MAX_ENERGY, MAX_ENERGY, empowered_remaining > 0.0)
