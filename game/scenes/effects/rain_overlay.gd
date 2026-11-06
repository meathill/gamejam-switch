class_name RainOverlay
extends CanvasLayer
## 全屏持续的暴雨（屏幕空间），只做氛围，不影响玩法

@export var amount: int = 420
@export var intensity: float = 1.0

var _particles: CPUParticles2D


func _ready() -> void:
	layer = 5
	var streak := GradientTexture2D.new()
	streak.width = 3
	streak.height = 34
	streak.fill_from = Vector2(0.5, 0.0)
	streak.fill_to = Vector2(0.5, 1.0)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0))
	gradient.set_color(1, Color(0.8, 0.88, 1.0, 0.55))
	streak.gradient = gradient

	var particles := CPUParticles2D.new()
	particles.texture = streak
	particles.amount = amount
	particles.lifetime = 0.7
	particles.preprocess = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(1300, 10)
	particles.position = Vector2(1100, -60)
	particles.direction = Vector2(-0.22, 1.0)
	particles.spread = 2.0
	particles.initial_velocity_min = 1700.0 * intensity
	particles.initial_velocity_max = 2100.0 * intensity
	particles.gravity = Vector2.ZERO
	particles.particle_flag_align_y = true
	particles.scale_amount_min = 0.8
	particles.scale_amount_max = 1.4
	add_child(particles)
	_particles = particles


func fade_to(alpha: float, seconds: float) -> void:
	create_tween().tween_property(_particles, "modulate:a", alpha, seconds)
