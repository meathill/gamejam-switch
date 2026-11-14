@tool
class_name SeedCart
extends Interactable
## 种子车：完成所有通关目标（和 requires）后按 E 启动，沿地面驶到 target_x。
## 出发时发出 departed、到达时发出 arrived 事件（通常联动 complete_level）。原点在地面中点。

signal level_event(event: String)

const SIZE := Vector2(260, 170)
const TEXTURE := preload("res://assets/sprites/farm/cart.png")
const SACK_TEXTURE := preload("res://assets/sprites/farm/seed_sack.png")
const SACK_WIDTH := 70.0
const SPEED := 260.0

@export var target_x: float = 0.0

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
	level_event.emit("departed")
	var distance := absf(target_x - global_position.x)
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position:x", target_x, distance / SPEED)
	await tween.finished
	level_event.emit("arrived")


func _draw() -> void:
	var cart_size := TEXTURE.get_size() * SIZE.x / TEXTURE.get_width()
	draw_texture_rect(TEXTURE, Rect2(Vector2(-cart_size.x / 2.0, -cart_size.y), cart_size), false)
	var sack_size := SACK_TEXTURE.get_size() * SACK_WIDTH / SACK_TEXTURE.get_width()
	var body_top := -cart_size.y + 8.0
	for x: float in [-SACK_WIDTH * 0.9, 0.0, SACK_WIDTH * 0.9]:
		draw_texture_rect(SACK_TEXTURE, Rect2(Vector2(x - sack_size.x / 2.0, body_top - sack_size.y * 0.7), sack_size), false)
