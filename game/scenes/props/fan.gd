@tool
class_name Fan
extends WeatherTarget
## 地下通风机：风天吹动后一直转，发出 started 事件。原点在地面中点。

const RADIUS := 80.0
const TEXTURE := preload("res://assets/sprites/farm/fan.png")
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
	return display_name if display_name else "通风机"


func get_unmet_reason(_condition: Dictionary) -> String:
	return "" if _is_running else "%s还没转起来" % get_display_name()


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
	level_event.emit("started")
	state_changed.emit(self)
	return CastResult.ok()


func _draw() -> void:
	var center := Vector2(0, -HEIGHT + RADIUS)
	draw_rect(Rect2(-12, center.y, 24, -center.y), Color(0.45, 0.42, 0.58))
	draw_set_transform(center, _angle)
	draw_texture_rect(TEXTURE, Rect2(-Vector2.ONE * RADIUS, Vector2.ONE * RADIUS * 2.0), false)
	draw_set_transform(Vector2.ZERO)
	if _highlight_color.a > 0.0:
		draw_arc(center, RADIUS + 16.0, 0.0, TAU, 32, _highlight_color, 4.0)
