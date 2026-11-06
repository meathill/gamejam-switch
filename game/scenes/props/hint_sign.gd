@tool
class_name HintSign
extends Node2D
## 路边提示牌。原点在地面。

@export_multiline var text: String = "提示":
	set(value):
		text = value
		if _label:
			_label.text = value

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = Vector2(420, 120)
	_label.position = Vector2(-210, -300)
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color(0.15, 0.13, 0.1))
	add_child(_label)


func _draw() -> void:
	draw_rect(Rect2(-8, -180, 16, 180), Color(0.4, 0.3, 0.2))
	draw_rect(Rect2(-220, -310, 440, 140), Color(0.86, 0.8, 0.62))
	draw_rect(Rect2(-220, -310, 440, 140), Color(0.4, 0.3, 0.2), false, 5.0)
