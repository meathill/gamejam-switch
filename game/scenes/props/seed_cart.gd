@tool
class_name SeedCart
extends Interactable
## 种子车：完成所有通关目标后按 E 启动，沿地面驶向终点，到达后由终点结算。原点在地面中点。

const SIZE := Vector2(260, 170)
const TEXTURE := preload("res://assets/sprites/farm/cart.png")
const SACK_TEXTURE := preload("res://assets/sprites/farm/seed_sack.png")
const SACK_WIDTH := 70.0
const SPEED := 260.0

@export var goal: GoalArea

var _is_moving: bool = false


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
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position:x", goal.global_position.x, distance / SPEED)
	await tween.finished
	goal.arrive_by_cart()


func _draw() -> void:
	var cart_size := TEXTURE.get_size() * SIZE.x / TEXTURE.get_width()
	draw_texture_rect(TEXTURE, Rect2(Vector2(-cart_size.x / 2.0, -cart_size.y), cart_size), false)
	var sack_size := SACK_TEXTURE.get_size() * SACK_WIDTH / SACK_TEXTURE.get_width()
	var body_top := -cart_size.y + 8.0
	for x: float in [-SACK_WIDTH * 0.9, 0.0, SACK_WIDTH * 0.9]:
		draw_texture_rect(SACK_TEXTURE, Rect2(Vector2(x - sack_size.x / 2.0, body_top - sack_size.y * 0.7), sack_size), false)
