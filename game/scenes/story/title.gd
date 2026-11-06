extends Node2D
## 标题画面

const PROLOGUE_SCENE := "res://scenes/story/prologue.tscn"
const LEVEL_SCENE := "res://scenes/levels/level_01.tscn"
const CAT_PORTRAIT := preload("res://assets/portraits/cat.png")


func _ready() -> void:
	add_child(StoryBackdrop.new())
	var cat := Sprite2D.new()
	cat.texture = CAT_PORTRAIT
	cat.scale = Vector2.ONE * 0.42
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
	var start := _make_button("开始游戏")
	start.pressed.connect(func() -> void: SceneRouter.go_to(PROLOGUE_SCENE))
	column.add_child(start)
	var skip := _make_button("跳过序章")
	skip.pressed.connect(func() -> void:
		GameState.has_seen_level_intro = false
		SceneRouter.go_to(LEVEL_SCENE)
	)
	column.add_child(skip)
	start.grab_focus.call_deferred()

	var footer := _make_label("GitHub Game Off 2026 · SHIFT", 22)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.offset_left = -520
	footer.offset_top = -60
	footer.offset_right = -40
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.modulate.a = 0.6
	layer.add_child(footer)


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 72)
	button.add_theme_font_size_override("font_size", 34)
	return button
