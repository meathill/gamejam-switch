@tool
class_name Interactable
extends Area2D
## 可互动对象的基类：小猫进入检测区后显示“E xxx”提示（触屏显示互动按钮），按互动键调用 _interact()。
## 原点在脚底。子类覆盖 get_action_name()、can_interact()、_interact()。
## requirements（关卡数据的 requires）没满足时，按互动键只提示原因。

const PROMPT_FONT_SIZE := 28

## 检测区大小（底边中点在原点）
var detect_size: Vector2 = Vector2(260, 260)
## 提示文字相对原点的高度
var prompt_height: float = 290.0
var is_player_near: bool = false
var requirements: Array[Requirement] = []
var _prompt: Label


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = detect_size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -detect_size.y / 2.0)
	add_child(collision)
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", PROMPT_FONT_SIZE)
	_prompt.add_theme_constant_override("outline_size", 8)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.size = Vector2(300, 40)
	_prompt.position = Vector2(-150, -prompt_height)
	_prompt.visible = false
	_prompt.z_index = 10
	add_child(_prompt)


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func get_action_name() -> String:
	return "互动"


func can_interact() -> bool:
	return true


## 状态变化（可互动与否）后调用，刷新提示和触屏按钮
func refresh_prompt() -> void:
	if not _prompt:
		return
	var available := is_player_near and can_interact()
	_prompt.text = GameState.pick_hint("E " + get_action_name(), get_action_name())
	_prompt.visible = available
	GameState.set_interact_available(self, available)


func _unhandled_input(event: InputEvent) -> void:
	if is_player_near and can_interact() and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		var reason := Requirement.first_unmet(requirements)
		if reason:
			GameState.post_warning(reason)
			return
		_interact()
		refresh_prompt()


func _interact() -> void:
	pass


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		GameState.set_interact_available(self, false)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = true
		refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = false
		refresh_prompt()
