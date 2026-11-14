@tool
class_name WaterRules
extends RefCounted
## 天气对水域的作用规则。纯逻辑，不依赖任何节点，规则表见 docs/TECH_SPEC.md 5.3。

const MAX_LEVEL := 2

enum Reason {
	NONE,
	LEVEL_FULL,
	FROZEN_NO_RISE,
	NO_WATER,
	ALREADY_FROZEN,
	ALREADY_DRY,
	POLLUTED_NO_FREEZE,
	POLLUTED_NO_EVAPORATE,
	TOO_SHALLOW,
	FROZEN_NO_WIND,
	NO_RAFT,
	NO_DOCK,
	DEEP_NO_FREEZE,
	BUSY,
}

const _REASON_TEXTS: Dictionary[Reason, String] = {
	Reason.NONE: "",
	Reason.LEVEL_FULL: "水位已满",
	Reason.FROZEN_NO_RISE: "冰面无法涨水",
	Reason.NO_WATER: "这里没有水可以冻结",
	Reason.ALREADY_FROZEN: "已经结冰了",
	Reason.ALREADY_DRY: "已经干了",
	Reason.POLLUTED_NO_FREEZE: "污染水结不了冰",
	Reason.POLLUTED_NO_EVAPORATE: "污染水无法蒸发",
	Reason.TOO_SHALLOW: "水太浅，浮箱漂不起来",
	Reason.FROZEN_NO_WIND: "浮箱被冻住了",
	Reason.NO_RAFT: "这里没有能被风推动的东西",
	Reason.NO_DOCK: "那个方向没有停靠点",
	Reason.DEEP_NO_FREEZE: "水太深了，冻不住",
	Reason.BUSY: "",
}


class Result:
	extends RefCounted

	var is_success: bool
	var state: WaterState
	var reason: Reason

	func _init(success: bool, next_state: WaterState, failure_reason: Reason = Reason.NONE) -> void:
		is_success = success
		state = next_state
		reason = failure_reason


## shallow_freeze_only：只能冻结浅水（地下深水冻不住）
static func apply(weather: Weather.Type, state: WaterState, shallow_freeze_only: bool = false) -> Result:
	match weather:
		Weather.Type.RAIN:
			return _apply_rain(state)
		Weather.Type.SNOW:
			if shallow_freeze_only and not state.is_frozen and state.level >= MAX_LEVEL:
				return _fail(state, Reason.DEEP_NO_FREEZE)
			return _apply_snow(state)
		Weather.Type.SUN:
			return _apply_sun(state)
		Weather.Type.WIND:
			return _apply_wind(state)
	return _fail(state, Reason.NONE)


static func get_reason_text(reason: Reason) -> String:
	return _REASON_TEXTS[reason]


## 风推浮箱的下一个停靠点；没有可用停靠点时返回 -1
static func find_next_dock(current: int, direction: int, dock_count: int, occupied: Array[int]) -> int:
	if direction == 0:
		return -1
	var next := current + signi(direction)
	if next < 0 or next >= dock_count or occupied.has(next):
		return -1
	return next


static func _apply_rain(state: WaterState) -> Result:
	if state.is_frozen:
		return _fail(state, Reason.FROZEN_NO_RISE)
	if state.level >= MAX_LEVEL:
		return _fail(state, Reason.LEVEL_FULL)
	var next := state.copy()
	next.level += 1
	return Result.new(true, next)


static func _apply_snow(state: WaterState) -> Result:
	if state.is_frozen:
		return _fail(state, Reason.ALREADY_FROZEN)
	if state.level == 0:
		return _fail(state, Reason.NO_WATER)
	if state.is_polluted:
		return _fail(state, Reason.POLLUTED_NO_FREEZE)
	var next := state.copy()
	next.is_frozen = true
	return Result.new(true, next)


static func _apply_sun(state: WaterState) -> Result:
	if state.is_frozen:
		var melted := state.copy()
		melted.is_frozen = false
		return Result.new(true, melted)
	if state.level == 0:
		return _fail(state, Reason.ALREADY_DRY)
	if state.is_polluted:
		return _fail(state, Reason.POLLUTED_NO_EVAPORATE)
	var next := state.copy()
	next.level -= 1
	return Result.new(true, next)


static func _apply_wind(state: WaterState) -> Result:
	if state.is_frozen:
		return _fail(state, Reason.FROZEN_NO_WIND)
	if state.level < MAX_LEVEL:
		return _fail(state, Reason.TOO_SHALLOW)
	return Result.new(true, state.copy())


static func _fail(state: WaterState, reason: Reason) -> Result:
	return Result.new(false, state.copy(), reason)
