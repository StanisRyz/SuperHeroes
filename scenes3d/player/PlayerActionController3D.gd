class_name PlayerActionController3D
extends Node

enum ActionType { NONE, AUTO_ATTACK, DASH, ABILITY }

var _type := ActionType.NONE
var _action_id := ""
var _token := 0
var _expires_at := 0.0

func try_begin_autoattack() -> int:
	return _begin(ActionType.AUTO_ATTACK, "autoattack", false)
func try_begin_dash() -> int:
	return _begin(ActionType.DASH, "dash", true)
func try_begin_ability(ability_id: String) -> int:
	return _begin(ActionType.ABILITY, ability_id, true)
func finish_action(token: int) -> bool:
	if token != _token or _type == ActionType.NONE: return false
	_type = ActionType.NONE; _action_id = ""; _expires_at = 0.0; return true
func cancel_action(token: int, _reason: String = "") -> bool:
	return finish_action(token)
func is_idle() -> bool: return _type == ActionType.NONE
func is_action_active(type: ActionType) -> bool: return _type == type
func get_current_action_state() -> Dictionary: return {"type": _type, "action_id": _action_id, "token": _token, "is_idle": is_idle()}
func _begin(type: ActionType, action_id: String, may_interrupt_autoattack: bool) -> int:
	if _type != ActionType.NONE and not (may_interrupt_autoattack and _type == ActionType.AUTO_ATTACK): return 0
	_token += 1; _type = type; _action_id = action_id; return _token
