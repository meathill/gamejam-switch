@tool
class_name Resident
extends Area2D
## 等待救援的居民。原点在脚底。小猫靠近后按 E 救援。

const BODY_COLOR := Color(0.62, 0.58, 0.52)
const HEAD_COLOR := Color(0.85, 0.78, 0.68)
const LIGHT_COLOR := Color(1.0, 0.95, 0.7)
const DETECT_SIZE := Vector2(260, 260)

@export var resident_name: String = "居民"
@export_multiline var thanks_text: String = "谢谢你，小猫！"

var _is_player_near: bool = false
var _is_rescued: bool = false
var _prompt: Label
var _time: float = 0.0


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = DETECT_SIZE
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -DETECT_SIZE.y / 2.0)
	add_child(collision)
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt = Label.new()
	_prompt.text = GameState.pick_hint("E 救援", "救援")
	_prompt.add_theme_font_size_override("font_size", 28)
	_prompt.add_theme_constant_override("outline_size", 8)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.position = Vector2(-50, -230)
	_prompt.visible = false
	add_child(_prompt)
	GameState.register_resident()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _is_player_near and not _is_rescued and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_rescue()


func _rescue() -> void:
	_is_rescued = true
	_prompt.visible = false
	GameState.set_interact_available(false)
	GameState.rescue_resident()
	GameState.post_message("%s：%s" % [resident_name, thanks_text])
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	tween.tween_property(self, "position:y", position.y - 120.0, 1.2)
	await tween.finished
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _is_rescued:
		_is_player_near = true
		_prompt.text = GameState.pick_hint("E 救援", "救援")
		_prompt.visible = true
		GameState.set_interact_available(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and _is_player_near:
		_is_player_near = false
		_prompt.visible = false
		GameState.set_interact_available(false)


func _draw() -> void:
	draw_rect(Rect2(-26, -110, 52, 110), BODY_COLOR)
	draw_circle(Vector2(0, -135), 26.0, HEAD_COLOR)
	var blink := 0.55 + 0.45 * sin(_time * 5.0)
	draw_circle(Vector2(36, -80), 10.0, Color(LIGHT_COLOR, blink))
	draw_circle(Vector2(36, -80), 32.0, Color(LIGHT_COLOR, blink * 0.25))
