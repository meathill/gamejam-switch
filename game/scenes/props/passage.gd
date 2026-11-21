@tool
class_name Passage
extends Interactable
## 应急便道：溃泄后启用，按 E 沿路线把小猫送到终点。原点是路线起点（path[0]，世界坐标点列）。
## 未启用时画淡紫色虚线；启用时高亮并脉动。堰恢复后用 carry_back() 沿原路送回。

const LINE_COLOR := Color(0.62, 0.5, 0.9)
const CARRY_SPEED := 900.0
const CARRY_BACK_RANGE := 300.0
const DASH := 24.0

## 启用后互动可用
@export var is_enabled: bool = false:
	set(value):
		is_enabled = value
		queue_redraw()
## 路线（世界坐标），第一个是起点（即原点）
var path: PackedVector2Array = PackedVector2Array()

var _is_carrying: bool = false
var _pulse: float = 0.0


func _process(delta: float) -> void:
	if is_enabled:
		_pulse += delta
		queue_redraw()


func get_action_name() -> String:
	return "走应急便道"


func can_interact() -> bool:
	return is_enabled and not _is_carrying


func do_enable(_params: Dictionary) -> void:
	is_enabled = true
	refresh_prompt()


func do_disable(_params: Dictionary) -> void:
	is_enabled = false
	refresh_prompt()


## 小猫在终点附近时沿原路送回起点（堰恢复后调用）
func carry_back() -> void:
	var player := get_player()
	if path.size() < 2 or player.global_position.distance_to(path[-1]) >= CARRY_BACK_RANGE:
		return
	var reversed := PackedVector2Array()
	for index in range(path.size() - 1, -1, -1):
		reversed.append(path[index])
	_carry(reversed)


func _interact() -> void:
	_carry(path)


func _carry(points: PackedVector2Array) -> void:
	var player := get_player()
	_is_carrying = true
	player.is_input_locked = true
	player.velocity = Vector2.ZERO
	for point in points:
		var distance := player.global_position.distance_to(point)
		if distance < 1.0:
			continue
		var tween := create_tween()
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_property(player, "global_position", point, distance / CARRY_SPEED)
		await tween.finished
	player.is_input_locked = false
	_is_carrying = false
	refresh_prompt()


func _draw() -> void:
	if path.size() < 2:
		return
	var points := PackedVector2Array()
	for point in path:
		points.append(point - global_position)
	var alpha := 0.75 + 0.25 * sin(_pulse * 5.0) if is_enabled else 0.3
	for index in points.size() - 1:
		draw_dashed_line(points[index], points[index + 1], Color(LINE_COLOR, alpha), 6.0, DASH)
