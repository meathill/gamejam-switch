extends Node
## 全局状态：当前天气、救援进度、检查点、消息提示

signal weather_changed(weather: Weather.Type)
signal message_posted(text: String, color: Color)
signal rescue_progress_changed(rescued: int, total: int)
signal level_completed
signal target_changed(zone: WaterZone)
signal weather_cast(zone: WaterZone, weather: Weather.Type)

const MESSAGE_COLOR := Color(0.95, 0.95, 0.9)
const WARNING_COLOR := Color(1.0, 0.72, 0.55)

var current_weather: Weather.Type = Weather.Type.RAIN
var rescued_count: int = 0
var total_residents: int = 0
var checkpoint_position: Vector2 = Vector2.ZERO
var has_seen_level_intro: bool = false
var is_level_complete: bool = false


func _ready() -> void:
	InputBindings.register()


func set_weather(weather: Weather.Type) -> void:
	if weather == current_weather:
		return
	current_weather = weather
	weather_changed.emit(weather)


func cycle_weather(step: int) -> void:
	set_weather(Weather.cycle(current_weather, step))


func post_message(text: String, color: Color = MESSAGE_COLOR) -> void:
	message_posted.emit(text, color)


func post_warning(text: String) -> void:
	post_message(text, WARNING_COLOR)


func reset_level() -> void:
	rescued_count = 0
	total_residents = 0
	checkpoint_position = Vector2.ZERO
	is_level_complete = false
	current_weather = Weather.Type.RAIN


func register_resident() -> void:
	total_residents += 1
	rescue_progress_changed.emit(rescued_count, total_residents)


func rescue_resident() -> void:
	rescued_count += 1
	rescue_progress_changed.emit(rescued_count, total_residents)


func is_all_rescued() -> bool:
	return rescued_count >= total_residents


func complete_level() -> void:
	if is_level_complete:
		return
	is_level_complete = true
	level_completed.emit()
