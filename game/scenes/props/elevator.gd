@tool
class_name Elevator
extends Interactable
## 竖井升降梯：水车在 power_gear 档位时通电，按 E 在井口和井底之间往返。原点在井口地面中点，travel 为向下的行程。
## 第一次通电时井口的防水挡板合上（之后一直关着），并发出 powered 事件。

signal level_event(event: String)

const PLATFORM_SIZE := Vector2(260, 30)
const RIDE_SPEED := 520.0
const SHAFT_TEXTURE := preload("res://assets/sprites/farm/shaft.png")
const PLATFORM_TEXTURE := preload("res://assets/sprites/farm/elevator_platform.png")
const PLATFORM_DRAW_HEIGHT := 44.0

@export var travel: float = 1200.0:
	set(value):
		travel = value
		queue_redraw()
@export var wheel: Waterwheel
@export_range(1, 3) var power_gear: int = 2

var _platform: AnimatableBody2D
## 0 = 井口，1 = 井底
var _progress: float = 0.0:
	set(value):
		_progress = value
		if _platform:
			_platform.position.y = travel * _progress
		queue_redraw()
var _is_riding: bool = false
var _is_cover_closed: bool = false


func _init() -> void:
	detect_size = Vector2(PLATFORM_SIZE.x + 60.0, 240.0)
	prompt_height = 260.0


func _ready() -> void:
	super()
	_platform = AnimatableBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = PLATFORM_SIZE
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, PLATFORM_SIZE.y / 2.0)
	_platform.add_child(collision)
	add_child(_platform)
	if Engine.is_editor_hint():
		return
	wheel.add_pipe(power_gear, global_position + Vector2(-PLATFORM_SIZE.x / 2.0 - 30.0, 0))
	wheel.gear_changed.connect(_on_gear_changed)


func get_action_name() -> String:
	return "乘坐升降梯"


func can_interact() -> bool:
	return not _is_riding


func is_powered() -> bool:
	return wheel.is_gear(power_gear)


func _interact() -> void:
	if not is_powered():
		GameState.post_warning("升降梯没有动力：" + wheel.get_unmet_reason({ "gear": power_gear }))
		return
	_ride(1.0 - roundf(_progress))


func _ride(target: float) -> void:
	var player := get_player()
	_is_riding = true
	player.is_input_locked = true
	player.velocity = Vector2.ZERO
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(func(value: float) -> void:
		_progress = value
		player.global_position = global_position + Vector2(0, travel * value - 1.0)
	, _progress, target, travel / RIDE_SPEED)
	await tween.finished
	player.is_input_locked = false
	_is_riding = false
	_move_detector()
	refresh_prompt()


func _move_detector() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).position.y = travel * _progress - detect_size.y / 2.0
	if _prompt:
		_prompt.position.y = travel * _progress - prompt_height


func _on_gear_changed(gear: int) -> void:
	if gear == power_gear and not _is_cover_closed:
		_is_cover_closed = true
		level_event.emit("powered")
	queue_redraw()


func _draw() -> void:
	var half := PLATFORM_SIZE.x / 2.0 + 20.0
	draw_texture_rect(SHAFT_TEXTURE, Rect2(-half, -20.0, half * 2.0, travel + PLATFORM_SIZE.y + 20.0), false)
	var cable_y := travel * _progress
	draw_line(Vector2(-half + 24, -40), Vector2(-half + 24, cable_y), Color(0.15, 0.15, 0.2), 4.0)
	draw_line(Vector2(half - 24, -40), Vector2(half - 24, cable_y), Color(0.15, 0.15, 0.2), 4.0)
	draw_rect(Rect2(-half - 20, -60, half * 2.0 + 40, 20), Color(0.45, 0.42, 0.55))
	var is_lit := not Engine.is_editor_hint() and wheel and is_powered()
	draw_circle(Vector2(0, -80), 16.0, Color(1.0, 0.8, 0.3) if is_lit else Color(0.35, 0.3, 0.25))
	draw_texture_rect(PLATFORM_TEXTURE, Rect2(-PLATFORM_SIZE.x / 2.0, cable_y - 6.0, PLATFORM_SIZE.x, PLATFORM_DRAW_HEIGHT), false)
	if _is_cover_closed:
		draw_rect(Rect2(-half - 20, -8, 30, 16), Color(0.75, 0.6, 0.3))
		draw_rect(Rect2(half - 10, -8, 30, 16), Color(0.75, 0.6, 0.3))
