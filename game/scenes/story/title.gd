extends Node2D
## 标题画面

const PROLOGUE_SCENE := "res://scenes/story/prologue.tscn"
const CAT_PORTRAIT := preload("res://assets/portraits/cat.png")


func _ready() -> void:
	var backdrop := StoryBackdrop.new()
	backdrop.has_opposite_building = false
	add_child(backdrop)
	var cat := Sprite2D.new()
	cat.texture = CAT_PORTRAIT
	cat.scale = Vector2.ONE * StoryBackdrop.CAT_HEIGHT / CAT_PORTRAIT.get_height()
	cat.position = Vector2(480, 520)
	add_child(cat)
	var ring := IldaRing.new()
	ring.position = Vector2(1490, 250)
	add_child(ring)
	add_child(RainOverlay.new())
	_build_menu()


func _build_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	column.offset_left = -760
	column.offset_right = -220
	column.offset_top = -20
	column.add_theme_constant_override("separation", 18)
	layer.add_child(column)

	var title := _make_label("Weather Shift", 96)
	column.add_child(title)
	column.add_child(_make_label("雨 · 风 · 雪 · 日照", 36))
	column.add_child(Control.new())
	var start := _make_button("开始游戏", 72, 34)
	start.pressed.connect(func() -> void: SceneRouter.go_to(PROLOGUE_SCENE))
	# 有通关进度时提供「继续游戏」，刷新网页后直接从上次没打完的关进入
	var focus_button := start
	var continue_id := SaveGame.load_level_id()
	if not continue_id.is_empty():
		var continue_button := _make_button("继续游戏 · %s" % LevelData.load_level(continue_id).chapter, 72, 34)
		continue_button.pressed.connect(func() -> void: SceneRouter.go_to_level(continue_id))
		column.add_child(continue_button)
		focus_button = continue_button
	column.add_child(start)
	# 次要操作收进同一行，避免按钮多了挤出屏幕、压到右下角 footer
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var skip := _make_button("跳过序章", 56, 26)
	skip.pressed.connect(func() -> void:
		GameState.seen_intros.clear()
		SceneRouter.go_to_level(LevelCatalog.first())
	)
	row.add_child(skip)
	if BuildFlags.is_level_select_enabled():
		var select := _make_button("选关", 56, 26)
		select.pressed.connect(func() -> void: _open_level_select(select))
		row.add_child(select)
	# 手机浏览器的地址栏会占掉不少高度，Web 版提供全屏入口（浏览器要求由用户点击触发）
	if OS.has_feature("web"):
		var fullscreen := _make_button("全屏", 56, 26)
		fullscreen.pressed.connect(func() -> void:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		)
		row.add_child(fullscreen)
	focus_button.grab_focus.call_deferred()

	var footer := _make_label("GitHub Game Off 2026 · SHIFT", 22)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.offset_left = -520
	footer.offset_top = -60
	footer.offset_right = -40
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.modulate.a = 0.6
	layer.add_child(footer)


func _open_level_select(button: Button) -> void:
	var menu := LevelSelectMenu.new()
	menu.closed.connect(func() -> void: button.grab_focus.call_deferred())
	add_child(menu)
	menu.focus_first()


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	return label


func _make_button(text: String, height: float, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", font_size)
	return button
