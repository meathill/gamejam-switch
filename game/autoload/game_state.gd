extends Node
## 全局状态：当前天气、通关目标进度、检查点、天气限制、消息提示

signal weather_changed(weather: Weather.Type)
signal message_posted(text: String, color: Color)
signal objectives_changed
signal level_completed
signal target_changed(target: WeatherTarget)
signal weather_cast(target: WeatherTarget, weather: Weather.Type)
signal touch_mode_changed(enabled: bool)
signal interact_available_changed(available: bool)
signal weather_rules_changed
## 关卡里的机关、人物请求播放对白，由 Level 锁定操作并播放
signal dialogue_requested(path: String)
signal dialogue_finished

const MESSAGE_COLOR := Color(0.95, 0.95, 0.9)
const WARNING_COLOR := Color(1.0, 0.72, 0.55)
## 目标类别 → HUD 名称 / 未完成时的提示
const OBJECTIVE_LABELS: Dictionary[String, String] = { "resident": "救援", "field": "农田" }
const OBJECTIVE_REMAINING: Dictionary[String, String] = {
	"resident": "还有 %d 位居民没有得救",
	"field": "还有 %d 块田没有恢复",
}

var current_weather: Weather.Type = Weather.Type.RAIN
var checkpoint_position: Vector2 = Vector2.ZERO
var current_level_id: String = ""
## 已经看过开场对白的关卡（重开不再播放）
var seen_intros: Dictionary[String, bool] = {}
var is_level_complete: bool = false
## 触屏模式：有触摸屏或发生过触摸时开启，显示虚拟按键和触屏版提示文案
var is_touch_mode: bool = false
var is_interact_available: bool = false
## 类别 → [已完成, 总数]
var _objectives: Dictionary[String, Vector2i] = {}
var _interact_sources: Dictionary[Node, bool] = {}
## 小猫所在的天气限制区域
var _weather_rules: Array[WeatherRuleArea] = []


func _ready() -> void:
	InputBindings.register()
	is_touch_mode = DisplayServer.is_touchscreen_available()


func _input(event: InputEvent) -> void:
	if not is_touch_mode and event is InputEventScreenTouch:
		is_touch_mode = true
		touch_mode_changed.emit(true)


## 按输入方式选择提示文案
func pick_hint(keyboard_text: String, touch_text: String) -> String:
	return touch_text if is_touch_mode else keyboard_text


## 多个可互动对象可能同时在附近，任意一个可用就显示互动按钮
func set_interact_available(source: Node, available: bool) -> void:
	if available:
		_interact_sources[source] = true
	else:
		_interact_sources.erase(source)
	var any := not _interact_sources.is_empty()
	if any == is_interact_available:
		return
	is_interact_available = any
	interact_available_changed.emit(any)


func set_weather(weather: Weather.Type) -> void:
	if weather == current_weather:
		return
	current_weather = weather
	weather_changed.emit(weather)


func cycle_weather(step: int) -> void:
	set_weather(Weather.cycle(current_weather, step))


func post_message(text: String, color: Color = MESSAGE_COLOR) -> void:
	message_posted.emit(text, color)


func post_warning(text: String) -> void:
	post_message(text, WARNING_COLOR)


func reset_level() -> void:
	_objectives.clear()
	_interact_sources.clear()
	_weather_rules.clear()
	checkpoint_position = Vector2.ZERO
	is_level_complete = false
	is_interact_available = false
	current_weather = Weather.Type.RAIN


func register_objective(kind: String) -> void:
	var progress: Vector2i = _objectives.get(kind, Vector2i.ZERO)
	_objectives[kind] = progress + Vector2i(0, 1)
	objectives_changed.emit()


func complete_objective(kind: String) -> void:
	_objectives[kind] = _objectives[kind] + Vector2i(1, 0)
	objectives_changed.emit()


## 已完成的目标又失效了（如恢复的低洼田重新积水）
func revert_objective(kind: String) -> void:
	_objectives[kind] = _objectives[kind] - Vector2i(1, 0)
	objectives_changed.emit()


## x = 已完成，y = 总数
func get_objective(kind: String) -> Vector2i:
	return _objectives.get(kind, Vector2i.ZERO)


func get_objective_kinds() -> Array[String]:
	var kinds: Array[String] = []
	kinds.assign(_objectives.keys())
	return kinds


func is_all_objectives_done() -> bool:
	return _objectives.values().all(func(progress: Vector2i) -> bool: return progress.x >= progress.y)


## 未完成目标的提示，全部完成时为空
func get_remaining_text() -> String:
	var parts: Array[String] = []
	for kind in _objectives:
		var progress := _objectives[kind]
		if progress.x < progress.y:
			parts.append(OBJECTIVE_REMAINING[kind] % (progress.y - progress.x))
	return "，".join(parts)


## 播放对白并等待结束（由 Level 响应 dialogue_requested）
func play_dialogue(path: String) -> void:
	dialogue_requested.emit(path)
	await dialogue_finished


func complete_level() -> void:
	if is_level_complete:
		return
	is_level_complete = true
	level_completed.emit()


func enter_weather_rule(area: WeatherRuleArea) -> void:
	if not _weather_rules.has(area):
		_weather_rules.append(area)
		weather_rules_changed.emit()


func exit_weather_rule(area: WeatherRuleArea) -> void:
	if _weather_rules.has(area):
		_weather_rules.erase(area)
		weather_rules_changed.emit()


func is_weather_disabled(weather: Weather.Type) -> bool:
	return not get_disabled_reason(weather).is_empty()


func get_disabled_reason(weather: Weather.Type) -> String:
	for area in _weather_rules:
		if area.is_active and area.disabled_weathers.has(weather):
			return area.reason
	return ""
