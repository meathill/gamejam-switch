class_name Player
extends CharacterBody2D
## 小猫。原点在脚底。

signal drowned

const RUN_SPEED := 520.0
const ACCELERATION := 4200.0
const FRICTION := 5200.0
const ICE_ACCELERATION := 900.0
const ICE_FRICTION := 420.0
const SHALLOW_SPEED_SCALE := 0.55
const JUMP_VELOCITY := -1200.0
const JUMP_CUT_SCALE := 0.45
const COYOTE_SECONDS := 0.1
const JUMP_BUFFER_SECONDS := 0.12
const DROWN_DEPTH := 40.0
const CAST_SECONDS := 0.35
const DROWN_SECONDS := 0.9
const MAX_FALL_SPEED := 1800.0
const SPRITE_SCALE := 0.7
## 站着不动超过这个时间换成“稍息”姿势
const IDLE_REST_SECONDS := 6.0
const FRAME_DIR := "res://assets/sprites/cat/"

enum State { NORMAL, CASTING, DROWNING }

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _caster: WeatherCaster = $WeatherCaster
@onready var _camera: Camera2D = $Camera2D

var facing: int = 1
var is_input_locked: bool = false
var _state: State = State.NORMAL
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _walk_time: float = 0.0
var _idle_time: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_sprite.sprite_frames = _build_frames()
	_sprite.scale = Vector2.ONE * SPRITE_SCALE
	_sprite.play("idle")


func _physics_process(delta: float) -> void:
	if _state == State.DROWNING:
		return
	_update_checkpoint()
	var water := _find_water_under()
	if water and water.get_state().is_deep_liquid() and global_position.y > water.get_surface_global_y() + DROWN_DEPTH:
		_drown()
		return
	_apply_gravity(delta)
	if _state == State.NORMAL and not is_input_locked:
		_handle_jump(delta)
		_handle_move(delta, water)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	move_and_slide()
	_update_animation(delta)


func _unhandled_input(event: InputEvent) -> void:
	if is_input_locked or _state != State.NORMAL:
		return
	if event.is_action_pressed("weather_next"):
		GameState.cycle_weather(1)
	elif event.is_action_pressed("weather_prev"):
		GameState.cycle_weather(-1)
	elif event.is_action_pressed("weather_rain"):
		GameState.set_weather(Weather.Type.RAIN)
	elif event.is_action_pressed("weather_wind"):
		GameState.set_weather(Weather.Type.WIND)
	elif event.is_action_pressed("weather_snow"):
		GameState.set_weather(Weather.Type.SNOW)
	elif event.is_action_pressed("weather_sun"):
		GameState.set_weather(Weather.Type.SUN)
	elif event.is_action_pressed("cast"):
		_cast()


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	_state = State.NORMAL
	_sprite.modulate = Color.WHITE
	_camera.reset_smoothing()


func _cast() -> void:
	if not is_on_floor():
		return
	_state = State.CASTING
	_sprite.play("cast")
	_caster.cast(GameState.current_weather, facing)
	await get_tree().create_timer(CAST_SECONDS, false, true).timeout
	if _state == State.CASTING:
		_state = State.NORMAL


func _drown() -> void:
	_state = State.DROWNING
	velocity = Vector2.ZERO
	_sprite.play("dead")
	GameState.post_warning("小猫被深水卷走了……")
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, DROWN_SECONDS)
	await tween.finished
	drowned.emit()
	respawn(GameState.checkpoint_position)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = COYOTE_SECONDS
		return
	_coyote_timer -= delta
	velocity.y = minf(velocity.y + _gravity * delta, MAX_FALL_SPEED)


func _handle_jump(delta: float) -> void:
	_jump_buffer_timer = JUMP_BUFFER_SECONDS if Input.is_action_just_pressed("jump") else _jump_buffer_timer - delta
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_SCALE


func _handle_move(delta: float, water: WaterZone) -> void:
	var input := Input.get_axis("move_left", "move_right")
	if input != 0.0:
		facing = 1 if input > 0.0 else -1
	var is_on_ice := _is_standing_on_ice()
	var speed := RUN_SPEED
	if water and water.get_state().is_shallow_liquid() and global_position.y > water.get_surface_global_y():
		speed *= SHALLOW_SPEED_SCALE
	var acceleration := ICE_ACCELERATION if is_on_ice else ACCELERATION
	var friction := ICE_FRICTION if is_on_ice else FRICTION
	if input != 0.0:
		velocity.x = move_toward(velocity.x, input * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _is_standing_on_ice() -> bool:
	if not is_on_floor():
		return false
	for index in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider() as Node
		if collider and collider.is_in_group("ice"):
			return true
	return false


func _find_water_under() -> WaterZone:
	for node in get_tree().get_nodes_in_group("water_zones"):
		var zone := node as WaterZone
		if zone.contains_x(global_position.x) and global_position.y > zone.global_position.y - 1.0:
			return zone
	return null


func _update_checkpoint() -> void:
	if not is_on_floor():
		return
	for node in get_tree().get_nodes_in_group("checkpoints"):
		var marker := node as Node2D
		if global_position.x >= marker.global_position.x and marker.global_position.x > GameState.checkpoint_position.x:
			GameState.checkpoint_position = marker.global_position


func _update_animation(delta: float) -> void:
	if _state == State.CASTING:
		return
	_sprite.flip_h = facing > 0
	var animation := "idle"
	if not is_on_floor():
		animation = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 20.0:
		animation = "walk"
	_idle_time = _idle_time + delta if animation == "idle" and not is_input_locked else 0.0
	if _idle_time > IDLE_REST_SECONDS:
		animation = "rest"
	if _sprite.animation != animation:
		_sprite.play(animation)
	_walk_time = _walk_time + delta if animation == "walk" else 0.0
	_sprite.rotation = sin(_walk_time * 14.0) * 0.05


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var definitions: Dictionary[String, Array] = {
		"idle": ["stand"],
		"rest": ["walk_01"],
		"walk": ["walk_01", "walk_02"],
		"jump": ["jump_01"],
		"fall": ["jump_02"],
		"cast": ["cast"],
		"dead": ["dead"],
	}
	for animation: String in definitions:
		frames.add_animation(animation)
		frames.set_animation_speed(animation, 7.0)
		frames.set_animation_loop(animation, animation == "walk")
		for frame_name: String in definitions[animation]:
			frames.add_frame(animation, load(FRAME_DIR + frame_name + ".png"))
	return frames
