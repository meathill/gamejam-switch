class_name InputBindings
extends RefCounted
## 输入映射集中在代码里注册，便于 review 和 diff；见 docs/PRD.md 3.2


static func register() -> void:
	_add("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT])
	_add("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT])
	_add("jump", [KEY_SPACE, KEY_W, KEY_UP], [JOY_BUTTON_A])
	_add("weather_next", [KEY_SHIFT], [JOY_BUTTON_RIGHT_SHOULDER])
	_add("weather_prev", [], [JOY_BUTTON_LEFT_SHOULDER])
	_add("weather_rain", [KEY_1], [])
	_add("weather_wind", [KEY_2], [])
	_add("weather_snow", [KEY_3], [])
	_add("weather_sun", [KEY_4], [])
	_add("cast", [KEY_F, KEY_J], [JOY_BUTTON_X])
	_add("interact", [KEY_E, KEY_K], [JOY_BUTTON_Y])
	_add("advance", [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER], [JOY_BUTTON_A])
	_add("restart", [KEY_R], [JOY_BUTTON_BACK])
	_add("pause", [KEY_ESCAPE], [JOY_BUTTON_START])
	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)


static func _add(action: StringName, keys: Array[Key], buttons: Array[JoyButton]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	for button in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)


static func _add_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)
