class_name WeatherEffect
extends RefCounted
## 施放天气时生成一次性粒子（风、雪额外叠加美术素材）。area 是受影响区域（顶边视为水面）。

const SNOW_TEXTURE := preload("res://assets/effects/snow_overlay.png")
const WIND_SWIRLS: Array[Texture2D] = [
	preload("res://assets/effects/wind_swirl_1.png"),
	preload("res://assets/effects/wind_swirl_2.png"),
	preload("res://assets/effects/wind_swirl_3.png"),
]


static func spawn_on_target(parent: Node, weather: Weather.Type, target: WeatherTarget, direction: int) -> void:
	spawn(parent, weather, target.get_effect_rect(), direction)


static func spawn(parent: Node, weather: Weather.Type, area: Rect2, direction: int = 1, amount_scale: float = 1.0) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = false
	particles.z_index = 5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var half_width := area.size.x / 2.0
	var center_x := area.position.x + half_width
	var top := area.position.y
	var color := Weather.get_color(weather)
	var fade := Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	particles.color_ramp = fade
	match weather:
		Weather.Type.RAIN:
			_configure(particles, 220, 0.8, Vector2(half_width, 20), Vector2.DOWN, 900.0, Vector2(0, 1600), 3.0, 5.0)
			particles.global_position = Vector2(center_x, top - 520.0)
		Weather.Type.SNOW:
			_configure(particles, 140, 1.6, Vector2(half_width, 20), Vector2.DOWN, 160.0, Vector2(0, 180), 6.0, 11.0)
			particles.spread = 40.0
			particles.global_position = Vector2(center_x, top - 420.0)
		Weather.Type.WIND:
			var wind_direction := Vector2(1 if direction >= 0 else -1, 0)
			_configure(particles, 90, 0.7, Vector2(half_width, 120), wind_direction, 1300.0, Vector2.ZERO, 3.0, 6.0)
			particles.spread = 4.0
			particles.global_position = Vector2(center_x, top - 100.0)
		Weather.Type.SUN:
			_configure(particles, 120, 1.3, Vector2(half_width, 10), Vector2.UP, 140.0, Vector2(0, -60), 6.0, 12.0)
			particles.spread = 30.0
			particles.global_position = Vector2(center_x, top)
	particles.amount = maxi(int(particles.amount * amount_scale), 1)
	parent.add_child(particles)
	particles.finished.connect(particles.queue_free)
	particles.emitting = true
	if weather == Weather.Type.WIND:
		_spawn_wind_swirls(parent, area, 1 if direction >= 0 else -1)
	elif weather == Weather.Type.SNOW:
		_spawn_snow_veil(parent, area)


## 美术的风笔触：错开出现，顺风飘出一段后淡出
static func _spawn_wind_swirls(parent: Node, area: Rect2, direction: int) -> void:
	for index in WIND_SWIRLS.size():
		var swirl := Sprite2D.new()
		swirl.texture = WIND_SWIRLS[index]
		swirl.flip_h = direction < 0
		swirl.z_index = 5
		swirl.modulate.a = 0.0
		var spread := (float(index) / maxf(WIND_SWIRLS.size() - 1, 1) - 0.5) * area.size.x * 0.6
		swirl.global_position = Vector2(area.get_center().x + spread, area.position.y - 120.0 - index * 60.0)
		parent.add_child(swirl)
		var tween := swirl.create_tween()
		tween.tween_interval(index * 0.12)
		tween.tween_property(swirl, "modulate:a", 0.9, 0.2)
		tween.parallel().tween_property(swirl, "position:x", swirl.position.x + direction * 320.0, 0.9)
		tween.tween_property(swirl, "modulate:a", 0.0, 0.3)
		tween.tween_callback(swirl.queue_free)


## 美术的雪片纹理：在水域上方缓缓落下并淡出
static func _spawn_snow_veil(parent: Node, area: Rect2) -> void:
	var veil := Sprite2D.new()
	veil.texture = SNOW_TEXTURE
	veil.z_index = 5
	veil.scale = Vector2.ONE * maxf(area.size.x, 600.0) / SNOW_TEXTURE.get_width()
	veil.global_position = Vector2(area.get_center().x, area.position.y - veil.texture.get_height() * veil.scale.y / 2.0)
	veil.modulate.a = 0.0
	parent.add_child(veil)
	var tween := veil.create_tween()
	tween.tween_property(veil, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(veil, "position:y", veil.position.y + 160.0, 1.6)
	tween.tween_property(veil, "modulate:a", 0.0, 0.5)
	tween.tween_callback(veil.queue_free)


static func _configure(
	particles: CPUParticles2D,
	amount: int,
	lifetime: float,
	extents: Vector2,
	direction: Vector2,
	speed: float,
	gravity: Vector2,
	scale_min: float,
	scale_max: float,
) -> void:
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 0.35
	particles.emission_rect_extents = extents
	particles.direction = direction
	particles.spread = 6.0
	particles.initial_velocity_min = speed * 0.8
	particles.initial_velocity_max = speed
	particles.gravity = gravity
	particles.scale_amount_min = scale_min
	particles.scale_amount_max = scale_max
