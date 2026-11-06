class_name WeatherRing
extends Control
## 伊尔妲的圆环：四段对应四种天气，切换时整体旋转，当前天气转到正上方

const RADIUS := 78.0
const RING_WIDTH := 16.0
const ICON_SIZE := 46.0
const GAP_RADIANS := 0.12
const ROTATE_SECONDS := 0.28

var _rotation_angle: float = 0.0:
	set(value):
		_rotation_angle = value
		queue_redraw()
var _icons: Dictionary[Weather.Type, Texture2D] = {}
var _current: Weather.Type = Weather.Type.RAIN


func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2.0 + ICON_SIZE, RADIUS * 2.0 + ICON_SIZE)
	for weather: int in Weather.Type.values():
		_icons[weather] = load(Weather.get_icon_path(weather))
	_current = GameState.current_weather
	_rotation_angle = _angle_for(_current)
	GameState.weather_changed.connect(_on_weather_changed)


func _on_weather_changed(weather: Weather.Type) -> void:
	var target := _angle_for(weather)
	var delta := wrapf(target - _rotation_angle, -PI, PI)
	_current = weather
	create_tween().tween_property(self, "_rotation_angle", _rotation_angle + delta, ROTATE_SECONDS) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 第 i 段的中心角在 -PI/2 + i * TAU/4；圆环反向旋转使当前段回到正上方
func _angle_for(weather: Weather.Type) -> float:
	return -float(weather) * TAU / Weather.Type.size()


func _draw() -> void:
	var center := size / 2.0
	var segment := TAU / Weather.Type.size()
	draw_circle(center, RADIUS + RING_WIDTH, Color(0, 0, 0, 0.35))
	for weather: int in Weather.Type.values():
		var mid := -PI / 2.0 + weather * segment + _rotation_angle
		var is_current := weather == _current
		var color := Weather.get_color(weather)
		if not is_current:
			color = Color(color, 0.35)
		draw_arc(center, RADIUS, mid - segment / 2.0 + GAP_RADIANS, mid + segment / 2.0 - GAP_RADIANS, 24, color, RING_WIDTH, true)
		var icon_size := ICON_SIZE * (1.0 if is_current else 0.72)
		var icon_center := center + Vector2.from_angle(mid) * (RADIUS - RING_WIDTH * 2.6)
		var icon_rect := Rect2(icon_center - Vector2.ONE * icon_size / 2.0, Vector2.ONE * icon_size)
		draw_texture_rect(_icons[weather], icon_rect, false, color)
	draw_circle(center, 10.0, Color(1.0, 0.85, 0.4, 0.9))
