class_name Hud
extends CanvasLayer
## 关卡 HUD：天气圆环、选中目标的状态、通关目标进度、提示消息

const TOAST_SECONDS := 2.4

var _weather_label: Label
var _target_label: Label
var _objective_label: Label
var _gauge_label: Label
var _gauge_tween: Tween
var _toast_label: Label
var _toast_tween: Tween
var _target: WeatherTarget = null
## 远程天气目标的 HUD 行（spot → 按钮）
var _spot_buttons: Dictionary[WeatherSpot, Button] = {}


func _ready() -> void:
	layer = 10
	_build()
	GameState.weather_changed.connect(func(_weather: Weather.Type) -> void: _refresh_weather())
	GameState.target_changed.connect(_on_target_changed)
	GameState.objectives_changed.connect(_refresh_objectives)
	GameState.weather_rules_changed.connect(_refresh_weather)
	GameState.message_posted.connect(show_toast)
	GameState.touch_mode_changed.connect(func(_enabled: bool) -> void: _refresh_weather())
	GameState.gauge_changed.connect(func(_value: int, _maximum: int) -> void: _refresh_gauge())
	_refresh_weather()
	_on_target_changed(null)
	_refresh_objectives()
	_refresh_gauge()


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


## 水尺：「水尺 ■■■□□」，快满时变红闪烁；本关没有水尺时隐藏
func _refresh_gauge() -> void:
	_gauge_label.visible = GameState.gauge_max > 0
	if _gauge_tween:
		_gauge_tween.kill()
		_gauge_tween = null
		_gauge_label.modulate.a = 1.0
	if not _gauge_label.visible:
		return
	var filled := "■".repeat(mini(GameState.gauge_value, GameState.gauge_max))
	_gauge_label.text = "水尺 %s%s" % [filled, "□".repeat(maxi(GameState.gauge_max - GameState.gauge_value, 0))]
	var is_critical := GameState.gauge_value >= GameState.gauge_max - 1
	_gauge_label.add_theme_color_override("font_color", Color(1, 0.45, 0.4) if is_critical else Color(0.95, 0.95, 0.9))
	if is_critical:
		_gauge_tween = create_tween().set_loops()
		_gauge_tween.tween_property(_gauge_label, "modulate:a", 0.25, 0.5)
		_gauge_tween.tween_property(_gauge_label, "modulate:a", 1.0, 0.5)


func _refresh_weather() -> void:
	var weather := GameState.current_weather
	var is_disabled := GameState.is_weather_disabled(weather)
	var hint := "\n这里不能用" if is_disabled else GameState.pick_hint("\nShift 切换 · F 施放", "")
	_weather_label.text = Weather.get_display_name(weather) + hint
	_weather_label.modulate = Color(0.6, 0.6, 0.6) if is_disabled else Weather.get_color(weather).lightened(0.3)
	_refresh_spot_rows()


func _make_spot_row(spot: WeatherSpot) -> Button:
	var row := Button.new()
	row.flat = true
	row.text = _spot_row_text(spot)
	row.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_theme_font_size_override("font_size", 26)
	row.add_theme_constant_override("outline_size", 8)
	row.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	row.pressed.connect(func() -> void:
		GameState.focus_requested.emit(spot.get_view_center(), WeatherSpot.FOCUS_SECONDS)
	)
	return row


func _spot_row_text(spot: WeatherSpot) -> String:
	var names: Array[String] = []
	for weather in spot.accepts:
		names.append(Weather.get_display_name(weather))
	var text := "%s · %s" % [spot.get_display_name(), "/".join(names)]
	return "%s → %s" % [text, spot.note] if spot.note else text


func _refresh_spot_rows() -> void:
	for spot: WeatherSpot in _spot_buttons:
		var row: Button = _spot_buttons[spot]
		# 用 modulate 压暗整行（连描边一起），只改字色时深色描边反而显得更醒目
		var is_selected := spot == _target
		row.modulate.a = 1.0 if is_selected else 0.45
		row.add_theme_color_override("font_color", Color.WHITE if is_selected else Color(0.85, 0.85, 0.85))


func _refresh_target() -> void:
	if not is_instance_valid(_target):
		_target_label.text = "附近没有可以施放天气的地方"
		return
	var status := _target.get_status_text()
	_target_label.text = "%s：%s" % [_target.get_display_name(), status] if status else _target.get_display_name()
	_refresh_spot_rows()


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

	var status_box := VBoxContainer.new()
	status_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status_box.offset_left = -400
	status_box.offset_right = -40
	status_box.offset_top = 36
	status_box.offset_bottom = 320
	status_box.add_theme_constant_override("separation", 8)
	root.add_child(status_box)
	_objective_label = _make_label(32, HORIZONTAL_ALIGNMENT_RIGHT)
	status_box.add_child(_objective_label)
	_gauge_label = _make_label(32, HORIZONTAL_ALIGNMENT_RIGHT)
	status_box.add_child(_gauge_label)
	# 远程天气目标各一行，点击预览真实地点；选中时高亮
	for node in get_tree().get_nodes_in_group(WeatherSpot.SPOTS_GROUP):
		var spot := node as WeatherSpot
		var row := _make_spot_row(spot)
		status_box.add_child(row)
		_spot_buttons[spot] = row

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
