class_name WeatherEffect
extends RefCounted
## 施放天气时生成一次性粒子。area 是受影响区域（顶边视为水面）。


static func spawn_on_zone(parent: Node, weather: Weather.Type, zone: WaterZone, direction: int) -> void:
	var top := zone.get_surface_global_y()
	spawn(parent, weather, Rect2(zone.global_position.x, top, zone.size.x, 1.0), direction)


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
