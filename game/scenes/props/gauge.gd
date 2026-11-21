@tool
class_name Gauge
extends Node2D
## 场景水尺：水尺杆 + 5 格灯，显示堰的压力（和 HUD 水尺同步）。原点在杆底中点。

const POLE_TEXTURE := preload("res://assets/sprites/valley/gauge_pole.png")
const POLE_HEIGHT := 300.0
const LAMP_COUNT := 5
const LAMP_SPACING := 42.0
const LIT_COLOR := Color(0.45, 0.75, 1.0)
const DANGER_COLOR := Color(1.0, 0.45, 0.4)
const OFF_COLOR := Color(0.2, 0.22, 0.28)

var weir: Weir
var _pressure: int = 0:
	set(value):
		_pressure = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint() or not weir:
		return
	weir.pressure_changed.connect(_on_pressure_changed)
	_pressure = weir.pressure


func _on_pressure_changed(value: int) -> void:
	_pressure = value


func _draw() -> void:
	var pole_size := POLE_TEXTURE.get_size() * POLE_HEIGHT / POLE_TEXTURE.get_height()
	draw_texture_rect(POLE_TEXTURE, Rect2(Vector2(-pole_size.x / 2.0, -POLE_HEIGHT), pole_size), false)
	var is_danger := _pressure >= LAMP_COUNT - 1
	var lit := DANGER_COLOR if is_danger else LIT_COLOR
	for index in LAMP_COUNT:
		var center := Vector2(0, -POLE_HEIGHT + 60.0 + index * LAMP_SPACING)
		draw_circle(center, 14.0, lit if index >= LAMP_COUNT - _pressure else OFF_COLOR)
