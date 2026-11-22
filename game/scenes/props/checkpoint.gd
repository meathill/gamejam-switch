@tool
class_name Checkpoint
extends Node2D
## 检查点。小猫站在它附近的地面上后，落水会在这里重生（以最近经过的为准）。原点在地面。
## 第一次被激活时发 reached 事件（小猫走到或重生到它旁边都算一次）。

signal level_event(event: String)

var _was_reached := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("checkpoints")


## Player 把它设成当前检查点时调用；只有第一次发事件
func notify_reached() -> void:
	if _was_reached:
		return
	_was_reached = true
	level_event.emit("reached")


func _draw() -> void:
	draw_line(Vector2.ZERO, Vector2(0, -120), Color(0.8, 0.8, 0.75), 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -120), Vector2(46, -104), Vector2(0, -88)]), Color(0.55, 0.85, 0.6))
