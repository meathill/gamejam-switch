class_name WeatherRing
extends Control
## 天气轮盘（美术素材，四个象限顺时针为 雨 → 风 → 雪 → 日照）。
## 切换天气时轮盘旋转，当前天气的象限转到正上方的指针下，中心显示当前天气图标；当前位置禁用的天气显示为灰色并划斜线。

const WHEEL := preload("res://assets/ui/weather_wheel.png")
const WHEEL_SIZE := 210.0
const ICON_SIZE := 72.0
const POINTER_COLOR := Color(1.0, 0.85, 0.4)
const ROTATE_SECONDS := 0.32
const DISABLED_TINT := Color(0.45, 0.45, 0.45, 0.8)

var _rotation_angle: float = 0.0:
	set(value):
		_rotation_angle = value
		queue_redraw()
var _icons: Dictionary[Weather.Type, Texture2D] = {}
var _current: Weather.Type = Weather.Type.RAIN


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * (WHEEL_SIZE + 24.0)
	for weather: int in Weather.Type.values():
		_icons[weather] = load(Weather.get_icon_path(weather))
	_current = GameState.current_weather
	_rotation_angle = _angle_for(_current)
	GameState.weather_changed.connect(_on_weather_changed)
	GameState.weather_rules_changed.connect(queue_redraw)


func _on_weather_changed(weather: Weather.Type) -> void:
	var target := _angle_for(weather)
	var delta := wrapf(target - _rotation_angle, -PI, PI)
	_current = weather
	create_tween().tween_property(self, "_rotation_angle", _rotation_angle + delta, ROTATE_SECONDS) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 素材里第 i 个象限的中心角是 -135° + i·90°，旋转 45° - i·90° 后正好转到正上方
func _angle_for(weather: Weather.Type) -> float:
	return PI / 4.0 - float(weather) * TAU / Weather.Type.size()


func _draw() -> void:
	var center := size / 2.0
	var wheel_scale := WHEEL_SIZE / maxf(WHEEL.get_width(), WHEEL.get_height())
	draw_circle(center, WHEEL_SIZE * 0.36, Color(0.05, 0.06, 0.09, 0.55))
	draw_set_transform(center, _rotation_angle, Vector2.ONE * wheel_scale)
	draw_texture(WHEEL, -WHEEL.get_size() / 2.0)
	draw_set_transform(Vector2.ZERO)
	var top := center.y - WHEEL_SIZE / 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - 14, top - 10), Vector2(center.x + 14, top - 10), Vector2(center.x, top + 14),
	]), POINTER_COLOR)
	var icon := _icons[_current]
	var icon_scale := ICON_SIZE / maxf(icon.get_width(), icon.get_height())
	var is_disabled := GameState.is_weather_disabled(_current)
	var icon_rect := Rect2(center - icon.get_size() * icon_scale / 2.0, icon.get_size() * icon_scale)
	draw_texture_rect(icon, icon_rect, false, DISABLED_TINT if is_disabled else Color.WHITE)
	if is_disabled:
		var half := ICON_SIZE * 0.45
		draw_line(center + Vector2(-half, half), center + Vector2(half, -half), Color(1.0, 0.55, 0.45), 6.0)
