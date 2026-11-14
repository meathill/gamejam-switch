class_name TitleCard
extends CanvasLayer
## 关卡标题卡：“第一关 / 被淹没的城市”。淡入停留后结束；is_fading_out 时再淡出并移除自己。

const FADE_SECONDS := 1.0
const HOLD_SECONDS := 1.6

var _label: Label


func _init(level: LevelData) -> void:
	layer = 30
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 72)
	_label.add_theme_constant_override("outline_size", 12)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.text = "%s\n%s" % [level.chapter, level.title]
	_label.modulate.a = 0.0
	add_child(_label)


func play(is_fading_out: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_label, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_interval(HOLD_SECONDS)
	if is_fading_out:
		tween.tween_property(_label, "modulate:a", 0.0, FADE_SECONDS)
	await tween.finished
	if is_fading_out:
		queue_free()
