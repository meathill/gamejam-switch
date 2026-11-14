@tool
class_name Machine
extends Node2D
## 机器（排水站、排水泵）的基类：前置条件（requirements）全部满足后自动启动，start_delay 秒后发出 started 事件。
## 接了水车（wheel）的机器还要水车在 power_gear 档位才有动力；动力到了但其他条件没满足时提示原因。
## 启动后做什么（排水、灌溉、救人、提示）都写在关卡数据的 links 里。原点在地面中点。

signal level_event(event: String)

@export var machine_name: String = "机器"
@export var wheel: Waterwheel
@export_range(1, 3) var power_gear: int = 3
@export var start_delay: float = 0.6

var requirements: Array[Requirement] = []
var is_running: bool = false
var _is_starting: bool = false
var _last_reason: String = ""


func _ready() -> void:
	if Engine.is_editor_hint() or not wheel:
		return
	wheel.add_pipe(power_gear, global_position + _get_pipe_offset())
	wheel.gear_changed.connect(_on_gear_changed)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or _is_starting:
		return
	var reason := get_blocking_reason()
	if reason != _last_reason:
		_last_reason = reason
		queue_redraw()
	if reason.is_empty():
		_start()


## 还不能启动的原因；能启动时为空
func get_blocking_reason() -> String:
	if wheel and not wheel.is_gear(power_gear):
		return wheel.get_unmet_reason({ "gear": power_gear })
	return Requirement.first_unmet(requirements)


func get_unmet_reason(_condition: Dictionary) -> String:
	return "" if is_running else "%s还没启动" % machine_name


func is_lit() -> bool:
	return _is_starting or Engine.is_editor_hint()


func _get_pipe_offset() -> Vector2:
	return Vector2.ZERO


func _on_gear_changed(gear: int) -> void:
	if gear != power_gear or _is_starting:
		return
	var reason := Requirement.first_unmet(requirements)
	if reason:
		GameState.post_warning(reason)


func _start() -> void:
	_is_starting = true
	queue_redraw()
	await get_tree().create_timer(start_delay, false).timeout
	is_running = true
	level_event.emit("started")
