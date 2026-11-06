@tool
class_name SolidBlock
extends StaticBody2D
## 灰盒地形块。原点在左上角。

@export var size: Vector2 = Vector2(800, 600):
	set(value):
		size = value
		_rebuild()
@export var color: Color = Color(0.29, 0.29, 0.32):
	set(value):
		color = value
		queue_redraw()
## 作为楼房绘制窗户
@export var is_building: bool = false:
	set(value):
		is_building = value
		queue_redraw()

var _collision: CollisionShape2D


func _ready() -> void:
	_collision = CollisionShape2D.new()
	_collision.shape = RectangleShape2D.new()
	add_child(_collision)
	_rebuild()


func _rebuild() -> void:
	if not _collision:
		return
	(_collision.shape as RectangleShape2D).size = size
	_collision.position = size / 2.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_line(Vector2.ZERO, Vector2(size.x, 0), color.lightened(0.25), 6.0)
	if is_building:
		_draw_windows()


func _draw_windows() -> void:
	var window_color := color.darkened(0.35)
	var cell := Vector2(110, 130)
	var columns := int(size.x / cell.x)
	var rows := int(size.y / cell.y)
	var margin_x := (size.x - columns * cell.x) / 2.0
	for row in rows:
		for column in columns:
			var origin := Vector2(margin_x + column * cell.x + 25, row * cell.y + 35)
			draw_rect(Rect2(origin, Vector2(60, 70)), window_color)
