@tool
class_name Lever
extends Interactable
## 拉杆 / 开关：按 E 拉下后发出 triggered，只能拉一次。原点在地面。
## requires_deep 不为空时，那片水域必须是液态深水才拉得动（排水开关要先把排水槽灌满），否则提示还差什么。

signal triggered

const TEXTURE := preload("res://assets/sprites/farm/lever.png")
const DRAW_HEIGHT := 110.0

@export var requires_deep: WaterZone
@export var action_name: String = "拉开关"
@export var pulled_text: String = ""

var is_pulled: bool = false


func get_action_name() -> String:
	return action_name


func can_interact() -> bool:
	return not is_pulled


func _interact() -> void:
	var reason := get_locked_reason()
	if reason:
		GameState.post_warning(reason)
		return
	is_pulled = true
	queue_redraw()
	if pulled_text:
		GameState.post_message(pulled_text)
	triggered.emit()


## 拉不动的原因（告诉玩家还差哪一步）；可以拉时为空
func get_locked_reason() -> String:
	if not requires_deep:
		return ""
	var state := requires_deep.get_state()
	var zone_name := requires_deep.zone_name
	if state.is_frozen:
		return "%s冻住了，水流不过去，先用日照融化" % zone_name
	if state.level == 0:
		return "%s是干的，先下雨把它灌满" % zone_name
	if not state.is_deep_liquid():
		return "%s里的水还不够，再下一场雨" % zone_name
	return ""


func _draw() -> void:
	var draw_size := TEXTURE.get_size() * DRAW_HEIGHT / TEXTURE.get_height()
	# 拉下后把手倒向另一边
	if is_pulled:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect(TEXTURE, Rect2(Vector2(-draw_size.x / 2.0, -draw_size.y), draw_size), false)
	draw_set_transform(Vector2.ZERO)
	var light := Color(0.4, 0.85, 0.5) if is_pulled else Color(0.85, 0.3, 0.25)
	draw_circle(Vector2(0, -DRAW_HEIGHT - 24.0), 9.0, light)
