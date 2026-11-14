@tool
class_name Npc
extends Interactable
## 只对话、不计入通关目标的人物。原点在脚底。

const DISPLAY_HEIGHT := 240.0

@export var npc_name: String = "路人"
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export_file("*.json") var dialogue: String = ""
@export var is_flipped: bool = false


func _init() -> void:
	prompt_height = DISPLAY_HEIGHT + 50.0


func get_action_name() -> String:
	return "对话"


func can_interact() -> bool:
	return not dialogue.is_empty()


func _interact() -> void:
	await GameState.play_dialogue(dialogue)


func _draw() -> void:
	if not texture:
		draw_rect(Rect2(-40, -DISPLAY_HEIGHT, 80, DISPLAY_HEIGHT), Color(0.6, 0.6, 0.55))
		return
	var display_size := texture.get_size() * DISPLAY_HEIGHT / texture.get_height()
	var rect := Rect2(Vector2(-display_size.x / 2.0, -display_size.y), display_size)
	if is_flipped:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect(texture, rect, false)
