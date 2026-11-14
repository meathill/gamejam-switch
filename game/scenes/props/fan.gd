@tool
class_name Fan
extends WeatherTarget
## 地下通风机：风天吹动后一直转，发出 triggered（吹散冻雾）。原点在地面中点。

signal triggered

const RADIUS := 70.0
const HEIGHT := 200.0

var _is_running: bool = false
var _angle: float = 0.0
var _highlight_color: Color = Color.TRANSPARENT


func _process(delta: float) -> void:
	if _is_running:
		_angle += delta * 9.0
		queue_redraw()


func get_target_rect() -> Rect2:
	return Rect2(global_position + Vector2(-260, -HEIGHT - 200), Vector2(520, HEIGHT + 260))


func get_effect_rect() -> Rect2:
	return Rect2(global_position.x - RADIUS * 2.0, global_position.y - HEIGHT, RADIUS * 4.0, 1.0)


func get_display_name() -> String:
	return "通风机"


func get_status_text() -> String:
	return "运转中" if _is_running else "停转"


func set_highlight(color: Color) -> void:
	_highlight_color = color
	queue_redraw()


func _cast(weather: Weather.Type, _direction: int) -> CastResult:
	if weather != Weather.Type.WIND:
		return CastResult.fail("只有风能吹动通风机")
	if _is_running:
		return CastResult.fail("通风机已经转起来了")
	_is_running = true
	GameState.post_message("通风机转起来了，冻雾被吹散了")
	triggered.emit()
	state_changed.emit(self)
	return CastResult.ok()


func _draw() -> void:
	var center := Vector2(0, -HEIGHT + RADIUS)
	draw_rect(Rect2(-12, center.y, 24, -center.y), Color(0.3, 0.3, 0.33))
	draw_arc(center, RADIUS + 10.0, 0.0, TAU, 32, Color(0.45, 0.47, 0.5), 10.0)
	for index in 4:
		var direction := Vector2.from_angle(_angle + index * TAU / 4.0)
		draw_line(center, center + direction * RADIUS, Color(0.65, 0.68, 0.72), 18.0)
	draw_circle(center, 14.0, Color(0.25, 0.25, 0.28))
	if _highlight_color.a > 0.0:
		draw_arc(center, RADIUS + 26.0, 0.0, TAU, 32, _highlight_color, 4.0)
