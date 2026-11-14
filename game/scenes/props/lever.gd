@tool
class_name Lever
extends Interactable
## 拉杆 / 开关：按 E 拉下后发出 triggered，只能拉一次。原点在地面。
## requires_deep 不为空时，那片水域必须是液态深水才拉得动（排水开关要先把排水槽灌满）。

signal triggered

const BOX_SIZE := Vector2(70, 110)

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
	draw_rect(Rect2(-8, -BOX_SIZE.y, 16, BOX_SIZE.y), Color(0.3, 0.3, 0.33))
	var box := Rect2(-BOX_SIZE.x / 2.0, -BOX_SIZE.y - 40.0, BOX_SIZE.x, 70.0)
	draw_rect(box, Color(0.42, 0.44, 0.48))
	draw_rect(box, Color(0.22, 0.22, 0.25), false, 4.0)
	var pivot := box.get_center()
	var handle_end := pivot + (Vector2(18, 30) if is_pulled else Vector2(18, -40))
	draw_line(pivot, handle_end, Color(0.2, 0.2, 0.22), 7.0)
	draw_circle(handle_end, 11.0, Color(0.85, 0.3, 0.25) if not is_pulled else Color(0.4, 0.85, 0.5))
