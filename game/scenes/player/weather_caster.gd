class_name WeatherCaster
extends Node2D
## 选中小猫附近的天气目标（水域、水车、农田……），并把天气施放到它上面

var target: WeatherTarget = null


func _ready() -> void:
	GameState.weather_changed.connect(func(_weather: Weather.Type) -> void: _refresh_highlight())


func _physics_process(_delta: float) -> void:
	var next := _find_target()
	if next == target:
		return
	if is_instance_valid(target):
		target.set_highlight(Color.TRANSPARENT)
	target = next
	_refresh_highlight()
	GameState.target_changed.emit(target)


func cast(weather: Weather.Type, direction: int) -> void:
	if GameState.is_weather_disabled(weather):
		GameState.post_warning(GameState.get_disabled_reason(weather))
		return
	if not target:
		GameState.post_warning("附近没有可以施放天气的地方")
		return
	var result := target.cast_weather(weather, direction)
	if result.is_success:
		_spawn_effect(target, weather, direction)
		GameState.weather_cast.emit(target, weather)
	elif not result.is_busy:
		GameState.post_warning(result.reason_text)


## 特效可能延迟到镜头就位才生成；延迟的 spawn 放进独立协程发射后不管，保住 cast 的同步语义
func _spawn_effect(target: WeatherTarget, weather: Weather.Type, direction: int) -> void:
	var delay := target.get_effect_delay()
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if is_instance_valid(target):
		WeatherEffect.spawn_on_target(target.get_parent(), weather, target, direction)


func _find_target() -> WeatherTarget:
	var best: WeatherTarget = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(WeatherTarget.GROUP):
		var candidate := node as WeatherTarget
		if not candidate.is_inside_tree() or not candidate.get_target_rect().has_point(global_position):
			continue
		var distance := absf(candidate.get_center_global().x - global_position.x)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _refresh_highlight() -> void:
	if target:
		target.set_highlight(Weather.get_color(GameState.current_weather))
