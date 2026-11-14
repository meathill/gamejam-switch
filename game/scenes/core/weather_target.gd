@tool
class_name WeatherTarget
extends Node2D
## 能被天气施放的对象（水域、水车、农田……）的基类。
## 小猫在 get_target_rect() 范围内时，WeatherCaster 选中离它最近的一个；施放结果用 CastResult 返回。
## blocked_weathers：这个目标上禁用的天气 → 提示文案（如 { "snow": "会冻坏站顶的居民" }）

signal state_changed(target: WeatherTarget)

const GROUP := "weather_targets"

var blocked_weathers: Dictionary[String, String] = {}


func _init() -> void:
	add_to_group(GROUP)


func cast_weather(weather: Weather.Type, direction: int) -> CastResult:
	var key := Weather.get_key(weather)
	if blocked_weathers.has(key):
		return CastResult.fail(blocked_weathers[key])
	return _cast(weather, direction)


## 解除所有禁用的天气（如站顶的居民离开后，广场可以下雪了）
func clear_blocked_weathers() -> void:
	blocked_weathers.clear()


func get_target_rect() -> Rect2:
	return Rect2(global_position, Vector2.ZERO)


func get_center_global() -> Vector2:
	return global_position


## 施放特效的范围，顶边是特效的落点（水面、田面）
func get_effect_rect() -> Rect2:
	return Rect2(global_position, Vector2(200, 1))


func get_display_name() -> String:
	return name


func get_status_text() -> String:
	return ""


func set_highlight(_color: Color) -> void:
	pass


func _cast(_weather: Weather.Type, _direction: int) -> CastResult:
	return CastResult.fail("这里施放不了天气")
