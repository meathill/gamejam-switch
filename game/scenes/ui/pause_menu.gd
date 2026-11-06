class_name PauseMenu
extends CanvasLayer
## Esc 暂停。暂停时整棵树停止，只有这一层处理输入。

const TITLE_SCENE := "res://scenes/story/title.tscn"

var _root: Control


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = ColorRect.new()
	(_root as ColorRect).color = Color(0, 0, 0, 0.6)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.text = "暂停\n\nEsc 继续　　R 重新开始　　Q 返回标题\n\n← → 移动　Space 跳跃　Shift / 1-4 切换天气　F 施放　E 救援"
	_root.add_child(label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
	elif get_tree().paused and event.is_action_pressed("restart"):
		_set_paused(false)
		SceneRouter.reload()
	elif get_tree().paused and event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_Q:
		_set_paused(false)
		SceneRouter.go_to(TITLE_SCENE)


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_root.visible = paused
