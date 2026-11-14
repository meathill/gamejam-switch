@tool
class_name Lever
extends Interactable
## 拉杆 / 开关：按 E 拉下后发出 pulled 事件，只能拉一次。原点在地面。
## 拉不动的条件写在关卡数据的 requires 里（如排水槽要灌满），不满足时自动提示还差什么。

signal level_event(event: String)

const TEXTURE := preload("res://assets/sprites/farm/lever.png")
const DRAW_HEIGHT := 110.0

@export var lever_name: String = "拉杆"
@export var action_name: String = "拉开关"

var is_pulled: bool = false


func get_action_name() -> String:
	return action_name


func can_interact() -> bool:
	return not is_pulled


func get_unmet_reason(_condition: Dictionary) -> String:
	return "" if is_pulled else "先拉下%s" % lever_name


func _interact() -> void:
	is_pulled = true
	queue_redraw()
	level_event.emit("pulled")


func _draw() -> void:
	var draw_size := TEXTURE.get_size() * DRAW_HEIGHT / TEXTURE.get_height()
	# 拉下后把手倒向另一边
	if is_pulled:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect(TEXTURE, Rect2(Vector2(-draw_size.x / 2.0, -draw_size.y), draw_size), false)
	draw_set_transform(Vector2.ZERO)
	var light := Color(0.4, 0.85, 0.5) if is_pulled else Color(0.85, 0.3, 0.25)
	draw_circle(Vector2(0, -DRAW_HEIGHT - 24.0), 9.0, light)
