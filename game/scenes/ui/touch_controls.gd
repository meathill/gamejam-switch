class_name TouchControls
extends CanvasLayer
## 手机虚拟按键：左侧左右移动，右侧跳跃/施放/切换天气/救援，右上暂停。
## 只在触屏模式下显示；坐标基于 1920×1080 视口。

const ICON_DIR := "res://assets/icons/"

var is_active: bool = true:
	set(value):
		is_active = value
		_refresh_visibility()
var _weather_button: TouchButton
var _interact_button: TouchButton


func _ready() -> void:
	layer = 15
	_add("move_left", "caret_left", Vector2(170, 900), 105.0, true)
	_add("move_right", "caret_right", Vector2(420, 900), 105.0, true)
	_add("jump", "arrow_fat_up", Vector2(1745, 890), 115.0)
	_add("cast", "magic_wand", Vector2(1500, 960), 95.0)
	_weather_button = _add("weather_next", "", Vector2(1530, 735), 85.0)
	_interact_button = _add("interact", "hand_heart", Vector2(1745, 640), 85.0)
	_interact_button.tint = Color(1.0, 0.85, 0.5)
	_add("pause", "pause", Vector2(1855, 150), 50.0)
	_refresh_weather(GameState.current_weather)
	GameState.weather_changed.connect(_refresh_weather)
	GameState.touch_mode_changed.connect(func(_enabled: bool) -> void: _refresh_visibility())
	GameState.interact_available_changed.connect(func(_available: bool) -> void: _refresh_visibility())
	_refresh_visibility()


func _add(action: StringName, icon_name: String, center: Vector2, radius: float, slide_to_press: bool = false) -> TouchButton:
	var texture: Texture2D = load(ICON_DIR + icon_name + ".svg") if icon_name else null
	var button := TouchButton.new(action, texture, radius, slide_to_press)
	button.position = center
	add_child(button)
	return button


func _refresh_weather(weather: Weather.Type) -> void:
	_weather_button.icon = load(Weather.get_icon_path(weather))
	_weather_button.tint = Weather.get_color(weather)


func _refresh_visibility() -> void:
	visible = is_active and GameState.is_touch_mode
	if _interact_button:
		_interact_button.visible = GameState.is_interact_available
