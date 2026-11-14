@tool
class_name Resident
extends Interactable
## 等待救援的居民，计入通关目标。原点在脚底。
## 默认小猫靠近后按 E 救援；关卡数据 rescue_on_interact = false 的居民要靠联动（do: rescue）救出，按 E 只对话。
## 获救时发出 rescued 事件。

signal level_event(event: String)

const LIGHT_COLOR := Color(1.0, 0.95, 0.7)
const DISPLAY_HEIGHT := 240.0

@export var resident_name: String = "居民"
@export_multiline var thanks_text: String = "谢谢你，小猫！"
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
## 手里拿着手电筒（序章里对面楼闪烁的那束光）
@export var has_flashlight: bool = false
## 由联动救出（如排水后自己离开），小猫不能直接救
@export var is_rescued_by_trigger: bool = false
## 互动时先播放的对白（可选）
@export_file("*.json") var dialogue: String = ""

var _is_rescued: bool = false
var _time: float = 0.0


func _init() -> void:
	prompt_height = DISPLAY_HEIGHT + 50.0


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		GameState.register_objective("resident")


func _process(delta: float) -> void:
	if has_flashlight:
		_time += delta
		queue_redraw()


func get_action_name() -> String:
	return "对话" if is_rescued_by_trigger else "救援"


func can_interact() -> bool:
	return not _is_rescued and (not is_rescued_by_trigger or not dialogue.is_empty())


func rescue() -> void:
	if _is_rescued:
		return
	_is_rescued = true
	refresh_prompt()
	GameState.complete_objective("resident")
	level_event.emit("rescued")
	GameState.post_message("%s：%s" % [resident_name, thanks_text])
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	tween.tween_property(self, "position:y", position.y - 120.0, 1.2)
	await tween.finished
	queue_free()


func do_rescue(_params: Dictionary) -> void:
	rescue()


func get_unmet_reason(_condition: Dictionary) -> String:
	return "" if _is_rescued else "%s还没得救" % resident_name


func _interact() -> void:
	if dialogue:
		await GameState.play_dialogue(dialogue)
	if not is_rescued_by_trigger:
		rescue()


func _draw() -> void:
	if texture:
		var display_size := texture.get_size() * DISPLAY_HEIGHT / texture.get_height()
		draw_texture_rect(texture, Rect2(Vector2(-display_size.x / 2.0, -display_size.y), display_size), false)
	if has_flashlight:
		var blink := 0.55 + 0.45 * sin(_time * 5.0)
		var light_position := Vector2(DISPLAY_HEIGHT * 0.2, -DISPLAY_HEIGHT * 0.4)
		draw_circle(light_position, 40.0, Color(LIGHT_COLOR, blink * 0.25))
		draw_circle(light_position, 10.0, Color(LIGHT_COLOR, blink))
