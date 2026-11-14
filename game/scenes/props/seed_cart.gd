@tool
class_name SeedCart
extends Interactable
## 种子车：完成所有通关目标后按 E 启动，沿地面驶向终点，到达后由终点结算。原点在地面中点。

const SIZE := Vector2(220, 120)
const SPEED := 260.0

@export var goal: GoalArea

var _is_moving: bool = false
var _wheel_angle: float = 0.0:
	set(value):
		_wheel_angle = value
		queue_redraw()


func _init() -> void:
	detect_size = Vector2(SIZE.x + 120.0, 240.0)
	prompt_height = SIZE.y + 80.0


func get_action_name() -> String:
	return "推种子车"


func can_interact() -> bool:
	return not _is_moving


func _interact() -> void:
	if not GameState.is_all_objectives_done():
		GameState.post_warning(GameState.get_remaining_text())
		return
	_is_moving = true
	GameState.post_message("种子车出发了，跟着它去粮仓")
	var distance := absf(goal.global_position.x - global_position.x)
	var tween := create_tween().set_parallel()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position:x", goal.global_position.x, distance / SPEED)
	tween.tween_property(self, "_wheel_angle", distance / 40.0, distance / SPEED)
	await tween.finished
	goal.arrive_by_cart()


func _draw() -> void:
	var body := Rect2(-SIZE.x / 2.0, -SIZE.y, SIZE.x, SIZE.y - 30.0)
	draw_rect(body, Color(0.75, 0.45, 0.2))
	draw_rect(body, Color(0.45, 0.25, 0.1), false, 4.0)
	for index in 4:
		draw_circle(Vector2(-60 + index * 40, -SIZE.y - 6), 18.0, Color(0.95, 0.85, 0.5))
	for x: float in [-SIZE.x / 3.0, SIZE.x / 3.0]:
		var center := Vector2(x, -28)
		draw_circle(center, 28.0, Color(0.3, 0.22, 0.15))
		draw_line(center, center + Vector2.from_angle(_wheel_angle) * 24.0, Color(0.6, 0.5, 0.35), 5.0)
