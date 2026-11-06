@tool
class_name Checkpoint
extends Node2D
## 检查点。小猫站上地面并越过它的 x 坐标后，落水会在这里重生。原点在地面。


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("checkpoints")


func _draw() -> void:
	draw_line(Vector2.ZERO, Vector2(0, -120), Color(0.8, 0.8, 0.75), 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -120), Vector2(46, -104), Vector2(0, -88)]), Color(0.55, 0.85, 0.6))
