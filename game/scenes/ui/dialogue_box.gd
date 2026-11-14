class_name DialogueBox
extends CanvasLayer
## 通用文游对话框：说话人、逐字显示、点击/按键推进、跳过、选项、演出事件。
## 数据格式见 docs/TECH_SPEC.md 第 6 节。

signal event_triggered(event_name: String)
signal finished

const CHARS_PER_SECOND := 36.0
const SPEAKER_NAMES: Dictionary[String, String] = {
	"ilda": "伊尔妲",
	"cat": "小猫",
	"system": "系统提示",
	"farmer": "老农",
	"family": "老农的家人",
}
## 文字框/姓名框是浅色水彩纸，文字用深色
const SPEAKER_COLORS: Dictionary[String, Color] = {
	"ilda": Color(0.22, 0.42, 0.3),
	"cat": Color(0.5, 0.35, 0.12),
	"system": Color(0.25, 0.36, 0.5),
	"farmer": Color(0.45, 0.32, 0.2),
	"family": Color(0.4, 0.3, 0.35),
}
const TEXT_COLOR := Color(0.23, 0.2, 0.16)
const TEXT_BOX := preload("res://assets/ui/text_box.png")
const NAME_BOX := preload("res://assets/ui/name_box.png")
const PANEL_TOP := -310.0
const NAME_BOX_SIZE := Vector2(300, 78)

var _lines: Array[Dictionary] = []
var _index: int = -1
var _root: Control
var _name_box: TextureRect
var _speaker_label: Label
var _text_label: Label
var _choice_box: VBoxContainer
var _typing_tween: Tween
var _is_waiting_choice: bool = false
var _is_running: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


static func load_lines(path: String) -> Array[Dictionary]:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var lines: Array[Dictionary] = []
	for line: Dictionary in data["lines"]:
		lines.append(line)
	return lines


func play(lines: Array[Dictionary]) -> void:
	_lines = lines
	_index = -1
	_is_running = true
	_root.visible = true
	_next()
	await finished


func _unhandled_input(event: InputEvent) -> void:
	if not _is_running or _is_waiting_choice:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_skip()
	elif event.is_action_pressed("advance") or event.is_action_pressed("interact") or _is_click(event):
		get_viewport().set_input_as_handled()
		_advance()


func _is_click(event: InputEvent) -> bool:
	var mouse := event as InputEventMouseButton
	return mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT


func _advance() -> void:
	if _typing_tween and _typing_tween.is_running():
		_typing_tween.kill()
		_text_label.visible_ratio = 1.0
		return
	_next()


func _skip() -> void:
	if _typing_tween:
		_typing_tween.kill()
	for index in range(_index + 1, _lines.size()):
		var line := _lines[index]
		if line.get("type") == "event" and line.get("on_skip", false):
			event_triggered.emit(line["name"])
	_finish()


func _next() -> void:
	_index += 1
	if _index >= _lines.size():
		_finish()
		return
	var line := _lines[_index]
	match line.get("type", "line"):
		"event":
			event_triggered.emit(line["name"])
			if line.has("wait"):
				await get_tree().create_timer(float(line["wait"])).timeout
			_next()
		"goto":
			_jump_to(line["target"])
		"choice":
			_show_text("system", line["text"])
			_show_choices(line["options"])
		_:
			_show_text(line.get("speaker", ""), line["text"])


func _jump_to(id: String) -> void:
	for index in _lines.size():
		if _lines[index].get("id") == id:
			_index = index - 1
			_next()
			return
	push_error("DialogueBox: unknown id %s" % id)
	_finish()


func _show_text(speaker: String, text: String) -> void:
	_speaker_label.text = SPEAKER_NAMES.get(speaker, "")
	_speaker_label.add_theme_color_override("font_color", SPEAKER_COLORS.get(speaker, TEXT_COLOR))
	# 旁白没有说话人，不显示姓名框
	_name_box.visible = _speaker_label.text != ""
	_text_label.text = text
	_text_label.visible_ratio = 0.0
	_typing_tween = create_tween()
	_typing_tween.tween_property(_text_label, "visible_ratio", 1.0, maxf(text.length() / CHARS_PER_SECOND, 0.05))


func _show_choices(options: Array) -> void:
	_is_waiting_choice = true
	for option: Dictionary in options:
		var button := Button.new()
		button.text = option["label"]
		button.add_theme_font_size_override("font_size", 30)
		button.custom_minimum_size = NAME_BOX_SIZE
		_style_choice_button(button)
		button.pressed.connect(_on_choice.bind(option["next"]))
		_choice_box.add_child(button)
	(_choice_box.get_child(0) as Button).grab_focus.call_deferred()


func _on_choice(target: String) -> void:
	for child in _choice_box.get_children():
		child.queue_free()
	_is_waiting_choice = false
	_jump_to(target)


func _finish() -> void:
	_is_running = false
	_root.visible = false
	finished.emit()


func _build() -> void:
	# 整体容器不拦截鼠标，点文字框任意位置都能推进对话（触屏同理）
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = PANEL_TOP
	panel.offset_left = 160
	panel.offset_right = -160
	panel.offset_bottom = -40
	panel.add_theme_stylebox_override("panel", _make_texture_style(TEXT_BOX, 40.0, Vector4(72, 52, 72, 24)))
	_root.add_child(panel)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("font_size", 34)
	_text_label.add_theme_color_override("font_color", TEXT_COLOR)
	column.add_child(_text_label)
	var footer_row := HBoxContainer.new()
	footer_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer_row.add_theme_constant_override("separation", 24)
	column.add_child(footer_row)
	var footer := Label.new()
	footer.text = "点击 / Space 继续"
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_theme_font_size_override("font_size", 22)
	footer.add_theme_color_override("font_color", Color(TEXT_COLOR, 0.55))
	footer_row.add_child(footer)
	var skip_button := Button.new()
	skip_button.text = "跳过 ▶▶"
	skip_button.flat = true
	# 不抢焦点，否则 Space 会触发它
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.custom_minimum_size = Vector2(140, 52)
	skip_button.add_theme_font_size_override("font_size", 24)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		skip_button.add_theme_color_override(state, TEXT_COLOR)
	skip_button.pressed.connect(func() -> void:
		if not _is_waiting_choice:
			_skip()
	)
	footer_row.add_child(skip_button)

	# 姓名框压在文字框左上角
	_name_box = TextureRect.new()
	_name_box.texture = NAME_BOX
	_name_box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_name_box.stretch_mode = TextureRect.STRETCH_SCALE
	_name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_name_box.offset_left = 220
	_name_box.offset_right = 220 + NAME_BOX_SIZE.x
	_name_box.offset_top = PANEL_TOP - NAME_BOX_SIZE.y * 0.55
	_name_box.offset_bottom = PANEL_TOP + NAME_BOX_SIZE.y * 0.45
	_root.add_child(_name_box)
	_speaker_label = Label.new()
	_speaker_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speaker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speaker_label.add_theme_font_size_override("font_size", 32)
	_name_box.add_child(_speaker_label)

	_choice_box = VBoxContainer.new()
	_choice_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_choice_box.offset_left = -NAME_BOX_SIZE.x / 2.0
	_choice_box.offset_right = NAME_BOX_SIZE.x / 2.0
	_choice_box.offset_top = -140
	_choice_box.add_theme_constant_override("separation", 16)
	add_child(_choice_box)


## 选项按钮用姓名框素材；悬停/焦点时偏暖色，方便键盘玩家看清当前选中项
func _style_choice_button(button: Button) -> void:
	var states: Dictionary[String, Color] = {
		"normal": Color.WHITE,
		"hover": Color(1.0, 0.9, 0.68),
		"focus": Color(1.0, 0.9, 0.68),
		"pressed": Color(0.88, 0.8, 0.62),
	}
	for state: String in states:
		var style := _make_texture_style(NAME_BOX, 30.0, Vector4(40, 8, 40, 8))
		style.modulate_color = states[state]
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(state, TEXT_COLOR)


## 九宫格贴图样式：texture_margin 是不被拉伸的边角宽度，content 是内容内边距（左、上、右、下）
func _make_texture_style(texture: Texture2D, texture_margin: float, content: Vector4) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin_all(texture_margin)
	style.content_margin_left = content.x
	style.content_margin_top = content.y
	style.content_margin_right = content.z
	style.content_margin_bottom = content.w
	return style
