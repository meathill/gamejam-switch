class_name WaterState
extends RefCounted

var level: int
var is_frozen: bool
var is_polluted: bool


func _init(level_value: int = 0, frozen: bool = false, polluted: bool = false) -> void:
	level = level_value
	is_frozen = frozen
	is_polluted = polluted


func copy() -> WaterState:
	return WaterState.new(level, is_frozen, is_polluted)


func equals(other: WaterState) -> bool:
	return level == other.level and is_frozen == other.is_frozen and is_polluted == other.is_polluted


func is_deep_liquid() -> bool:
	return level >= WaterRules.MAX_LEVEL and not is_frozen


func is_shallow_liquid() -> bool:
	return level > 0 and level < WaterRules.MAX_LEVEL and not is_frozen


func _to_string() -> String:
	return "WaterState(level=%d, frozen=%s, polluted=%s)" % [level, is_frozen, is_polluted]
