class_name PauseMenu
extends Node
## Esc / 暂停键暂停。暂停时整棵树停止，只有这个节点和菜单处理输入。

const TITLE_SCENE := "res://scenes/story/title.tscn"
const KEY_HELP := "← → 移动　Space 跳跃　Shift / 1-4 切换天气　F 施放　E 互动"

var _menu: MenuOverlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_set_paused(not get_tree().paused)


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if not paused:
		if _menu:
			_menu.queue_free()
			_menu = null
		return
	_menu = MenuOverlay.new("暂停", 40)
	_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu.add_button("继续", _set_paused.bind(false))
	_menu.add_button("重新开始", func() -> void:
		_set_paused(false)
		SceneRouter.reload()
	)
	_menu.add_button("返回标题", func() -> void:
		_set_paused(false)
		SceneRouter.go_to(TITLE_SCENE)
	)
	if not GameState.is_touch_mode:
		_menu.add_note(KEY_HELP)
	add_child(_menu)
	_menu.focus_first()
