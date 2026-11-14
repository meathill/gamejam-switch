@tool
class_name Ladder
extends Interactable
## 机械爬梯：拉杆拉下后出现（enable），按 E 在底端和顶端之间自动爬过去。原点在底端地面，height 向上。

const CLIMB_SPEED := 420.0
const RAIL_COLOR := Color(0.55, 0.45, 0.3)
const TEXTURE := preload("res://assets/sprites/farm/ladder.png")
const DRAW_WIDTH := 110.0

@export var height: float = 900.0:
	set(value):
		height = value
		queue_redraw()
@export var is_enabled: bool = false:
	set(value):
		is_enabled = value
		queue_redraw()

var _is_climbing: bool = false


func _ready() -> void:
	detect_size = Vector2(220, height + 160.0)
	prompt_height = 220.0
	super()


func enable() -> void:
	is_enabled = true
	GameState.post_message("一架爬梯放了下来，直通地面")
	refresh_prompt()


func get_action_name() -> String:
	return "爬梯子"


func can_interact() -> bool:
	return is_enabled and not _is_climbing


func _interact() -> void:
	var player := get_player()
	var is_at_bottom := player.global_position.y > global_position.y - height / 2.0
	var target := global_position + (Vector2(0, -height) if is_at_bottom else Vector2.ZERO)
	_is_climbing = true
	player.is_input_locked = true
	player.velocity = Vector2.ZERO
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(player, "global_position", Vector2(global_position.x, player.global_position.y), 0.15)
	tween.tween_property(player, "global_position", target - Vector2(0, 1), height / CLIMB_SPEED)
	await tween.finished
	_prompt.position.y = (-height if is_at_bottom else 0.0) - prompt_height
	player.is_input_locked = false
	_is_climbing = false
	refresh_prompt()


func _draw() -> void:
	if not is_enabled:
		if Engine.is_editor_hint():
			draw_rect(Rect2(-50, -height, 100, height), Color(RAIL_COLOR, 0.25), false, 3.0)
		return
	draw_texture_rect(TEXTURE, Rect2(-DRAW_WIDTH / 2.0, -height - 20.0, DRAW_WIDTH, height + 20.0), false)
