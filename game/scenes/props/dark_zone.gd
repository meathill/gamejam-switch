@tool
class_name DarkZone
extends WeatherTarget
## 暗区：一片漆黑，日照照亮后发出 triggered（露出隐藏的平台）。原点在左上角。

signal triggered

const DARK_COLOR := Color(0.02, 0.02, 0.05, 0.88)
const FADE_SECONDS := 1.0

@export var size: Vector2 = Vector2(600, 600):
	set(value):
		size = value
		queue_redraw()

var _is_lit: bool = false
var _highlight_color: Color = Color.TRANSPARENT


func _ready() -> void:
	z_index = 4


func get_target_rect() -> Rect2:
	return Rect2(global_position, size)


func get_center_global() -> Vector2:
	return global_position + size / 2.0


func get_effect_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y + size.y * 0.6, size.x, 1.0)


func get_display_name() -> String:
	return "漆黑的作业区"


func get_status_text() -> String:
	return "已照亮" if _is_lit else "太暗了，什么都看不清"


func set_highlight(color: Color) -> void:
	_highlight_color = color
	queue_redraw()


func _cast(weather: Weather.Type, _direction: int) -> CastResult:
	if _is_lit:
		return CastResult.fail("这里已经亮了")
	if weather != Weather.Type.SUN:
		return CastResult.fail("这里太暗了，需要光")
	_is_lit = true
	GameState.post_message("阳光照进了作业区，露出一块平台")
	create_tween().tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	triggered.emit()
	state_changed.emit(self)
	return CastResult.ok()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), DARK_COLOR)
	if _highlight_color.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size).grow(-6.0), _highlight_color, false, 4.0)
