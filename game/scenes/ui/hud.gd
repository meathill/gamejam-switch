class_name Hud
extends CanvasLayer
## 关卡 HUD：天气圆环、选中目标的状态、通关目标进度、提示消息

const TOAST_SECONDS := 2.4

var _weather_label: Label
var _target_label: Label
var _objective_label: Label
var _toast_label: Label
var _toast_tween: Tween
var _target: WeatherTarget = null


func _ready() -> void:
	layer = 10
	_build()
	GameState.weather_changed.connect(func(_weather: Weather.Type) -> void: _refresh_weather())
	GameState.target_changed.connect(_on_target_changed)
	GameState.objectives_changed.connect(_refresh_objectives)
	GameState.weather_rules_changed.connect(_refresh_weather)
	GameState.message_posted.connect(show_toast)
	GameState.touch_mode_changed.connect(func(_enabled: bool) -> void: _refresh_weather())
	_refresh_weather()
	_on_target_changed(null)
	_refresh_objectives()


func show_toast(text: String, color: Color = GameState.MESSAGE_COLOR) -> void:
	_toast_label.text = text
	_toast_label.modulate = Color(color, 1.0)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.5)


func _on_target_changed(target: WeatherTarget) -> void:
	if is_instance_valid(_target) and _target.state_changed.is_connected(_on_target_state_changed):
		_target.state_changed.disconnect(_on_target_state_changed)
	_target = target
	if _target:
		_target.state_changed.connect(_on_target_state_changed)
	_refresh_target()


func _on_target_state_changed(_target_node: WeatherTarget) -> void:
	_refresh_target()


func _refresh_objectives() -> void:
	var parts: Array[String] = []
	for kind in GameState.get_objective_kinds():
		var progress := GameState.get_objective(kind)
		parts.append("%s  %d / %d" % [GameState.OBJECTIVE_LABELS[kind], progress.x, progress.y])
	_objective_label.text = "\n".join(parts)


func _refresh_weather() -> void:
	var weather := GameState.current_weather
	var is_disabled := GameState.is_weather_disabled(weather)
	var hint := "\n这里不能用" if is_disabled else GameState.pick_hint("\nShift 切换 · F 施放", "")
	_weather_label.text = Weather.get_display_name(weather) + hint
	_weather_label.modulate = Color(0.6, 0.6, 0.6) if is_disabled else Weather.get_color(weather).lightened(0.3)


func _refresh_target() -> void:
	if not is_instance_valid(_target):
		_target_label.text = "附近没有可以施放天气的地方"
		return
	var status := _target.get_status_text()
	_target_label.text = "%s：%s" % [_target.get_display_name(), status] if status else _target.get_display_name()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var ring_box := VBoxContainer.new()
	ring_box.position = Vector2(36, 28)
	ring_box.add_theme_constant_override("separation", 6)
	root.add_child(ring_box)
	ring_box.add_child(WeatherRing.new())
	_weather_label = _make_label(26, HORIZONTAL_ALIGNMENT_CENTER)
	ring_box.add_child(_weather_label)

	_objective_label = _make_label(32, HORIZONTAL_ALIGNMENT_RIGHT)
	_objective_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_objective_label.offset_left = -360
	_objective_label.offset_right = -40
	_objective_label.offset_top = 36
	root.add_child(_objective_label)

	_target_label = _make_label(28, HORIZONTAL_ALIGNMENT_CENTER)
	_target_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_target_label.offset_left = -600
	_target_label.offset_right = 600
	_target_label.offset_top = -90
	_target_label.offset_bottom = -40
	root.add_child(_target_label)

	_toast_label = _make_label(34, HORIZONTAL_ALIGNMENT_CENTER)
	_toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast_label.offset_left = -700
	_toast_label.offset_right = 700
	_toast_label.offset_top = 120
	_toast_label.modulate.a = 0.0
	root.add_child(_toast_label)


func _make_label(font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
