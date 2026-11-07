class_name MenuOverlay
extends CanvasLayer
## 半透明遮罩 + 标题文字 + 一列按钮。暂停菜单、通关画面共用，键盘（焦点）和触屏都能操作。

var _column: VBoxContainer
var _first_button: Button


func _init(title: String, layer_index: int) -> void:
	layer = layer_index
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 22)
	center.add_child(_column)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_constant_override("line_spacing", 10)
	_column.add_child(label)
	_column.add_child(Control.new())


func add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 80)
	button.add_theme_font_size_override("font_size", 34)
	button.pressed.connect(callback)
	_column.add_child(button)
	if not _first_button:
		_first_button = button


func add_note(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color(1, 1, 1, 0.6)
	_column.add_child(label)


func focus_first() -> void:
	if _first_button:
		_first_button.grab_focus.call_deferred()
