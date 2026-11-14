@tool
class_name Fog
extends StaticBody2D
## 挡路的冻雾：一堵过不去的墙，被关联的机关触发后（clear）散开。原点在左上角。

@export var size: Vector2 = Vector2(120, 600):
	set(value):
		size = value
		queue_redraw()

var _collision: CollisionShape2D


func _ready() -> void:
	_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	_collision.shape = shape
	_collision.position = size / 2.0
	add_child(_collision)


func clear() -> void:
	_collision.set_deferred("disabled", true)
	create_tween().tween_property(self, "modulate:a", 0.0, 1.2)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.82, 0.9, 0.98, 0.7))
	var y := 40.0
	while y < size.y:
		draw_circle(Vector2(size.x * 0.3, y), size.x * 0.45, Color(0.92, 0.96, 1.0, 0.5))
		draw_circle(Vector2(size.x * 0.75, y + 50.0), size.x * 0.4, Color(0.92, 0.96, 1.0, 0.45))
		y += 110.0
