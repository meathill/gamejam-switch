@tool
class_name Raft
extends AnimatableBody2D
## 浮箱。必须是 WaterZone 的子节点，位置由所在水域根据水位和停靠点控制。

const WIDTH := 200.0
const HEIGHT := 70.0
const WOOD_COLOR := Color(0.55, 0.38, 0.22)
const PLANK_COLOR := Color(0.42, 0.28, 0.16)
const FROST_COLOR := Color(0.85, 0.95, 1.0, 0.55)

@export var dock_index: int = 0

var _is_frozen: bool = false


func _ready() -> void:
	z_index = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, HEIGHT)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func set_frozen(frozen: bool) -> void:
	_is_frozen = frozen
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-WIDTH / 2.0, -HEIGHT / 2.0, WIDTH, HEIGHT)
	draw_rect(rect, WOOD_COLOR)
	for index in range(1, 4):
		var y := rect.position.y + HEIGHT * index / 4.0
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), PLANK_COLOR, 3.0)
	draw_line(rect.position, rect.end, PLANK_COLOR, 4.0)
	draw_rect(rect, PLANK_COLOR, false, 4.0)
	if _is_frozen:
		draw_rect(rect.grow(6.0), FROST_COLOR)
