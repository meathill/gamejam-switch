@tool
class_name Lever
extends Interactable
## 拉杆 / 开关：按 E 拉下后发出 triggered，只能拉一次。原点在地面。
## requires_deep 不为空时，那片水域必须是液态深水才拉得动（排水开关要先把排水槽灌满）。

signal triggered

const TEXTURE := preload("res://assets/sprites/farm/lever.png")
const DRAW_HEIGHT := 110.0

@export var requires_deep: WaterZone
@export var action_name: String = "拉开关"
@export var locked_text: String = "拉不动……"
@export var pulled_text: String = ""

var is_pulled: bool = false


func get_action_name() -> String:
	return action_name


func can_interact() -> bool:
	return not is_pulled


func _interact() -> void:
	if requires_deep and not requires_deep.get_state().is_deep_liquid():
		GameState.post_warning(locked_text)
		return
	is_pulled = true
	queue_redraw()
	if pulled_text:
		GameState.post_message(pulled_text)
	triggered.emit()


func _draw() -> void:
	var draw_size := TEXTURE.get_size() * DRAW_HEIGHT / TEXTURE.get_height()
	# 拉下后把手倒向另一边
	if is_pulled:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect(TEXTURE, Rect2(Vector2(-draw_size.x / 2.0, -draw_size.y), draw_size), false)
	draw_set_transform(Vector2.ZERO)
	var light := Color(0.4, 0.85, 0.5) if is_pulled else Color(0.85, 0.3, 0.25)
	draw_circle(Vector2(0, -DRAW_HEIGHT - 24.0), 9.0, light)
