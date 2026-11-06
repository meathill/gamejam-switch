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
}
const SPEAKER_COLORS: Dictionary[String, Color] = {
	"ilda": Color(0.7, 1.0, 0.75),
	"cat": Color(1.0, 0.88, 0.55),
	"system": Color(0.7, 0.85, 1.0),
}

var _lines: Array[Dictionary] = []
var _index: int = -1
var _panel: PanelContainer
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
	_panel.visible = false


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
	_panel.visible = true
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
	_speaker_label.modulate = SPEAKER_COLORS.get(speaker, Color.WHITE)
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
		button.custom_minimum_size = Vector2(260, 64)
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
	_panel.visible = false
	finished.emit()


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -300
	_panel.offset_left = 160
	_panel.offset_right = -160
	_panel.offset_bottom = -50
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.86)
	style.border_color = Color(0.85, 0.78, 0.5, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(28)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 32)
	column.add_child(_speaker_label)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("font_size", 34)
	column.add_child(_text_label)
	var footer := Label.new()
	footer.text = "Space / 点击 继续　　Esc 跳过"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_theme_font_size_override("font_size", 20)
	footer.modulate = Color(1, 1, 1, 0.5)
	column.add_child(footer)

	_choice_box = VBoxContainer.new()
	_choice_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_choice_box.offset_left = -130
	_choice_box.offset_right = 130
	_choice_box.offset_top = -120
	_choice_box.add_theme_constant_override("separation", 16)
	add_child(_choice_box)
