@tool
class_name Waterwheel
extends WeatherTarget
## 三档位大水车：风天推进一档（0 → 1 → 2 → 3 → 1），档位决定哪条动力管通水。原点在地面中点。
## 用到档位的机关（农田、升降梯、排水泵）在关卡构建时调用 add_pipe() 登记，水车负责画出管道。

signal gear_changed(gear: int)

const WHEEL_TEXTURE := preload("res://assets/sprites/farm/waterwheel.png")
const STAND_TEXTURE := preload("res://assets/sprites/farm/waterwheel_stand.png")
## 美术里轮子直径 1473、支架高 1265、轴心离地 1070（原画像素），按轮子直径 400px 等比换算
const RADIUS := 200.0
const AXLE_HEIGHT := 290.0
const STAND_HEIGHT := 344.0
const TURN_SECONDS := 0.6
const TARGET_HALF_WIDTH := 520.0
const GEAR_COLORS: Array[Color] = [
	Color(0.5, 0.5, 0.5),
	Color(0.4, 0.65, 1.0),
	Color(1.0, 0.8, 0.3),
	Color(0.45, 0.85, 0.45),
]
const PIPE_OFF_COLOR := Color(0.32, 0.3, 0.3)
## 每个档位的管道在地下的深度，避免重叠
const PIPE_DEPTHS: Array[float] = [0.0, 60.0, 100.0, 140.0]

@export_range(0, 3) var gear: int = 0:
	set(value):
		gear = value
		queue_redraw()

var _angle: float = 0.0:
	set(value):
		_angle = value
		queue_redraw()
var _highlight_color: Color = Color.TRANSPARENT
## 档位 → 管道终点（本地坐标）
var _pipes: Dictionary[int, PackedVector2Array] = {}
var _is_busy: bool = false


func add_pipe(pipe_gear: int, global_point: Vector2) -> void:
	var points: PackedVector2Array = _pipes.get(pipe_gear, PackedVector2Array())
	points.append(global_point - position)
	_pipes[pipe_gear] = points
	queue_redraw()


func is_gear(target_gear: int) -> bool:
	return gear == target_gear


func get_target_rect() -> Rect2:
	return Rect2(global_position + Vector2(-TARGET_HALF_WIDTH, -AXLE_HEIGHT - RADIUS - 200.0), Vector2(TARGET_HALF_WIDTH * 2.0, AXLE_HEIGHT + RADIUS + 320.0))


func get_effect_rect() -> Rect2:
	return Rect2(global_position.x - RADIUS, global_position.y - AXLE_HEIGHT - RADIUS * 0.5, RADIUS * 2.0, 1.0)


func get_display_name() -> String:
	return "三档位大水车"


func get_status_text() -> String:
	return "档位 %d · %s" % [gear, FarmRules.get_gear_name(gear)]


func set_highlight(color: Color) -> void:
	_highlight_color = color
	queue_redraw()


func _cast(weather: Weather.Type, _direction: int) -> CastResult:
	if weather != Weather.Type.WIND:
		return CastResult.fail("只有风能转动水车")
	if _is_busy:
		return CastResult.busy()
	gear = FarmRules.next_gear(gear)
	GameState.post_message("水车转到档位 %d：%s" % [gear, FarmRules.get_gear_name(gear)])
	_turn()
	return CastResult.ok()


func _turn() -> void:
	_is_busy = true
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "_angle", _angle + TAU / 3.0, TURN_SECONDS)
	await tween.finished
	_is_busy = false
	gear_changed.emit(gear)
	state_changed.emit(self)


func _draw() -> void:
	for pipe_gear: int in _pipes:
		var color := GEAR_COLORS[pipe_gear] if gear == pipe_gear else PIPE_OFF_COLOR
		var depth := PIPE_DEPTHS[pipe_gear]
		for end in _pipes[pipe_gear]:
			var start_x := (pipe_gear - 2) * 60.0
			draw_polyline(PackedVector2Array([
				Vector2(start_x, 0), Vector2(start_x, depth), Vector2(end.x, depth), end,
			]), color, 14.0)
	var axle := Vector2(0, -AXLE_HEIGHT)
	var wheel_size := Vector2.ONE * RADIUS * 2.0
	draw_set_transform(axle, _angle)
	draw_texture_rect(WHEEL_TEXTURE, Rect2(-wheel_size / 2.0, wheel_size), false)
	draw_set_transform(Vector2.ZERO)
	var stand_size := STAND_TEXTURE.get_size() * STAND_HEIGHT / STAND_TEXTURE.get_height()
	draw_texture_rect(STAND_TEXTURE, Rect2(Vector2(-stand_size.x / 2.0, -STAND_HEIGHT), stand_size), false)
	for index in range(1, 4):
		var lamp := Vector2((index - 2) * 70.0, -AXLE_HEIGHT - RADIUS - 70.0)
		var is_lit := gear == index
		draw_circle(lamp, 28.0, GEAR_COLORS[index] if is_lit else GEAR_COLORS[index].darkened(0.6))
		if is_lit:
			draw_circle(lamp, 44.0, Color(GEAR_COLORS[index], 0.3))
	if _highlight_color.a > 0.0:
		draw_arc(axle, RADIUS + 26.0, 0.0, TAU, 48, _highlight_color, 4.0)
