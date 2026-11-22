class_name LevelSelectMenu
extends MenuOverlay
## 选关弹层：每关一个按钮 + 返回。内部调试入口，正式发布时由导出开关移除标题页入口。

signal closed


func _init() -> void:
	super("选关", 20)
	for level_id: String in LevelCatalog.get_ids():
		var data := LevelData.load_level(level_id)
		add_button("%s · %s" % [data.chapter, data.title], _go_to.bind(level_id))
	add_button("返回", _close)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()


## 和标题页「跳过序章」一致：清掉看过对白的记录，进关后开场对白照常播放
func _go_to(level_id: String) -> void:
	GameState.seen_intros.clear()
	SceneRouter.go_to_level(level_id)


func _close() -> void:
	closed.emit()
	queue_free()
