class_name FarmRules
extends RefCounted
## 第二关「农田」的规则：三档位水车、农田状态机。纯逻辑，不依赖节点。

## 水车档位：0 停转，1 农田管，2 升降梯，3 抽水泵。风每次推进一档：0 → 1 → 2 → 3 → 1
const GEAR_COUNT := 3
const GEAR_NAMES: Array[String] = ["停转", "农田管", "升降梯", "抽水泵"]

enum FieldState { DRY, WATERLOGGED, MUD_ICE, RESTORED }

const FIELD_STATE_NAMES: Dictionary[FieldState, String] = {
	FieldState.DRY: "干旱",
	FieldState.WATERLOGGED: "积水淤泥",
	FieldState.MUD_ICE: "泥冰",
	FieldState.RESTORED: "已恢复",
}


class FieldResult:
	extends RefCounted

	var is_success: bool
	var state: FieldState
	var reason_text: String

	func _init(success: bool, next_state: FieldState, reason: String = "") -> void:
		is_success = success
		state = next_state
		reason_text = reason


static func next_gear(gear: int) -> int:
	return 1 if gear >= GEAR_COUNT else gear + 1


static func get_gear_name(gear: int) -> String:
	return GEAR_NAMES[gear]


## is_pipe_open：水车正好在这块田的灌溉档位；can_flood：已恢复后再下雨会重新积水（低洼田）；
## is_pump_only：只能靠排水泵灌溉（井口田）
static func apply_field(weather: Weather.Type, state: FieldState, is_pipe_open: bool, can_flood: bool, is_pump_only: bool) -> FieldResult:
	if is_pump_only:
		if state == FieldState.RESTORED:
			return _fail(state, "井口田已经浇透了")
		return _fail(state, "井口田离水源太远，要靠地下抽上来的水")
	match state:
		FieldState.DRY:
			if weather == Weather.Type.RAIN:
				return FieldResult.new(true, FieldState.RESTORED) if is_pipe_open else _fail(state, "雨水流不进田里，先把水车切到农田管（档位 1）")
			return _fail(state, "田里干透了，需要水")
		FieldState.WATERLOGGED:
			match weather:
				Weather.Type.SUN:
					return FieldResult.new(true, FieldState.DRY)
				Weather.Type.SNOW:
					return FieldResult.new(true, FieldState.MUD_ICE)
				Weather.Type.RAIN:
					return _fail(state, "积水太多了，先把它晒干")
			return _fail(state, "风吹不干淤泥")
		FieldState.MUD_ICE:
			if weather == Weather.Type.SUN:
				return FieldResult.new(true, FieldState.WATERLOGGED)
			return _fail(state, "淤泥冻住了")
		FieldState.RESTORED:
			if weather == Weather.Type.RAIN and can_flood:
				return FieldResult.new(true, FieldState.WATERLOGGED)
			return _fail(state, "这块田已经浇好了")
	return _fail(state, "")


static func _fail(state: FieldState, reason: String) -> FieldResult:
	return FieldResult.new(false, state, reason)
