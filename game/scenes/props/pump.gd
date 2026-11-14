@tool
class_name Pump
extends Node2D
## 地下排水泵：动力管接好（拉杆拉下）且水车在 power_gear 档位时启动，只启动一次：
## 把关联水域排干，抽上来的水浇灌井口田，完成后发出 triggered（被困的家人顺着斜坡回去）。原点在地面中点。

signal triggered

const BODY_SIZE := Vector2(220, 150)
const START_DELAY := 0.6

@export var wheel: Waterwheel
@export_range(1, 3) var power_gear: int = 3
@export var lever: Lever
@export var drained_zones: Array[WaterZone] = []
@export var irrigated_field: Field

var _is_running: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	wheel.add_pipe(power_gear, global_position + Vector2(0, -BODY_SIZE.y))
	wheel.gear_changed.connect(func(_gear: int) -> void: _try_start())
	if lever:
		lever.triggered.connect(func() -> void:
			GameState.post_message("动力管接上了，水车切到档位 %d 就能抽水" % power_gear)
			queue_redraw()
			_try_start()
		)


func is_connected_to_wheel() -> bool:
	return lever == null or lever.is_pulled


func _try_start() -> void:
	if _is_running or not wheel.is_gear(power_gear):
		return
	if not is_connected_to_wheel():
		GameState.post_warning("抽水泵的动力管还没接上")
		return
	_is_running = true
	queue_redraw()
	GameState.post_message("排水泵启动了！地下的积水被抽上了地面")
	await get_tree().create_timer(START_DELAY).timeout
	for zone in drained_zones:
		var state := zone.get_state()
		zone.transition_to(WaterState.new(0, false, state.is_polluted))
	await get_tree().create_timer(WaterZone.TWEEN_SECONDS).timeout
	if irrigated_field:
		irrigated_field.irrigate()
	triggered.emit()


func _draw() -> void:
	var rect := Rect2(-BODY_SIZE.x / 2.0, -BODY_SIZE.y, BODY_SIZE.x, BODY_SIZE.y)
	draw_rect(rect, Color(0.4, 0.42, 0.46))
	draw_rect(rect, Color(0.2, 0.2, 0.24), false, 4.0)
	draw_circle(rect.get_center() + Vector2(-40, 0), 40.0, Color(0.3, 0.32, 0.36))
	var is_connected := Engine.is_editor_hint() or is_connected_to_wheel()
	var light := Color(0.45, 0.85, 0.45) if _is_running else (Color(1.0, 0.8, 0.3) if is_connected else Color(0.4, 0.25, 0.25))
	draw_circle(rect.position + Vector2(170, 40), 18.0, light)
