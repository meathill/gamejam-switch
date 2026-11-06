class_name Hud
extends CanvasLayer
## 关卡 HUD：天气圆环、目标水域状态、救援进度、提示消息

const TOAST_SECONDS := 2.4

var _weather_label: Label
var _target_label: Label
var _rescue_label: Label
var _toast_label: Label
var _toast_tween: Tween
var _target: WaterZone = null


func _ready() -> void:
	layer = 10
	_build()
	GameState.weather_changed.connect(func(_weather: Weather.Type) -> void: _refresh_weather())
	GameState.target_changed.connect(_on_target_changed)
	GameState.rescue_progress_changed.connect(_on_rescue_progress_changed)
	GameState.message_posted.connect(show_toast)
	_refresh_weather()
	_on_target_changed(null)
	_on_rescue_progress_changed(GameState.rescued_count, GameState.total_residents)


func show_toast(text: String, color: Color = GameState.MESSAGE_COLOR) -> void:
	_toast_label.text = text
	_toast_label.modulate = Color(color, 1.0)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.5)


func _on_target_changed(zone: WaterZone) -> void:
	if _target and _target.state_changed.is_connected(_on_target_state_changed):
		_target.state_changed.disconnect(_on_target_state_changed)
	_target = zone
	if _target:
		_target.state_changed.connect(_on_target_state_changed)
	_refresh_target()


func _on_target_state_changed(_zone: WaterZone) -> void:
	_refresh_target()


func _on_rescue_progress_changed(rescued: int, total: int) -> void:
	_rescue_label.text = "救援  %d / %d" % [rescued, total]


func _refresh_weather() -> void:
	var weather := GameState.current_weather
	_weather_label.text = "%s\nShift 切换 · F 施放" % Weather.get_display_name(weather)
	_weather_label.modulate = Weather.get_color(weather).lightened(0.3)


func _refresh_target() -> void:
	if not _target:
		_target_label.text = "附近没有水域"
		return
	var state := _target.get_state()
	var level_names: Array[String] = ["干燥", "浅水", "深水"]
	var parts: Array[String] = ["水位 %d %s" % [state.level, level_names[state.level]]]
	parts.append("冰面" if state.is_frozen else "液态")
	if state.is_polluted:
		parts.append("污染")
	var rafts := _target.get_rafts().size()
	if rafts > 0:
		parts.append("浮箱 ×%d" % rafts)
	_target_label.text = "%s：%s" % [_target.zone_name, " · ".join(parts)]


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

	_rescue_label = _make_label(32, HORIZONTAL_ALIGNMENT_RIGHT)
	_rescue_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_rescue_label.offset_left = -360
	_rescue_label.offset_right = -40
	_rescue_label.offset_top = 36
	root.add_child(_rescue_label)

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
