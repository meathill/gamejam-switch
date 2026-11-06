class_name WeatherCaster
extends Node2D
## 选中小猫附近的水域，并把天气施放到它上面

var target: WaterZone = null


func _ready() -> void:
	GameState.weather_changed.connect(func(_weather: Weather.Type) -> void: _refresh_highlight())


func _physics_process(_delta: float) -> void:
	var next := _find_target()
	if next == target:
		return
	if target:
		target.set_highlight(Color.TRANSPARENT)
	target = next
	_refresh_highlight()
	GameState.target_changed.emit(target)


func cast(weather: Weather.Type, direction: int) -> void:
	if not target:
		GameState.post_warning("附近没有可以施放天气的水域")
		return
	var result := target.apply_weather(weather, direction)
	if result.is_success:
		WeatherEffect.spawn_on_zone(get_tree().current_scene, weather, target, direction)
		GameState.weather_cast.emit(target, weather)
	elif result.reason != WaterRules.Reason.BUSY:
		GameState.post_warning(WaterRules.get_reason_text(result.reason))


func _find_target() -> WaterZone:
	var best: WaterZone = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("water_zones"):
		var zone := node as WaterZone
		if not zone.get_target_rect().has_point(global_position):
			continue
		var distance := absf(zone.get_center_global().x - global_position.x)
		if distance < best_distance:
			best = zone
			best_distance = distance
	return best


func _refresh_highlight() -> void:
	if target:
		target.set_highlight(Weather.get_color(GameState.current_weather))
