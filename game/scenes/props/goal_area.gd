@tool
class_name GoalArea
extends Area2D
## 终点（避难所）：完成所有目标后到达这里即通关。原点在地面中点。

const AREA_SIZE := Vector2(360, 400)

## 由种子车送达才算通关（小猫走进来不结算）
@export var is_cart_goal: bool = false
## 画出避难所小屋；用美术贴图（decor）表现时关掉
@export var is_house_drawn: bool = true

var _has_warned: bool = false


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = AREA_SIZE
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -AREA_SIZE.y / 2.0)
	add_child(collision)
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(func(_body: Node2D) -> void: _has_warned = false)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or is_cart_goal:
		return
	if GameState.is_all_objectives_done():
		GameState.complete_level()
	elif not _has_warned:
		_has_warned = true
		GameState.post_warning(GameState.get_remaining_text())


func arrive_by_cart() -> void:
	GameState.complete_level()


func _draw() -> void:
	if not is_house_drawn:
		draw_line(Vector2(0, 0), Vector2(0, -180), Color(0.85, 0.85, 0.8), 5.0)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -180), Vector2(80, -155), Vector2(0, -130)]), Color(1.0, 0.85, 0.35))
		return
	draw_rect(Rect2(-160, -220, 320, 220), Color(0.62, 0.52, 0.38))
	draw_colored_polygon(PackedVector2Array([Vector2(-190, -220), Vector2(0, -330), Vector2(190, -220)]), Color(0.75, 0.35, 0.3))
	draw_rect(Rect2(-40, -120, 80, 120), Color(0.3, 0.22, 0.15))
	draw_line(Vector2(120, -220), Vector2(120, -400), Color(0.85, 0.85, 0.8), 5.0)
	draw_colored_polygon(PackedVector2Array([Vector2(120, -400), Vector2(200, -375), Vector2(120, -350)]), Color(1.0, 0.85, 0.35))
