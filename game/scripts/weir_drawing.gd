class_name WeirDrawing
extends RefCounted
## 活动堰的绘制工具：堰板（带各自的显示角度）和翻过板顶的水帘。
## 全部是静态方法，在调用节点（Weir）的本地坐标系内绘制。

const BOARD_SIZE := Vector2(50, 200)
## 放倒后的角度（度）
const LOWERED_ANGLE := -80.0
## 被冲开的板的角度（度）
const BLOWN_ANGLE := -60.0
const CASCADE_WIDTH := 22.0
const CURVE_STEPS := 12
const STRIPE_COUNT := 4
## 条纹沿水帘每秒前进的份数
const STRIPE_SPEED := 0.55
const STRIPE_LENGTH := 0.09
const FOAM_COUNT := 5
const WATER_COLOR := Color(0.35, 0.62, 0.9, 0.5)
const STRIPE_COLOR := Color(0.8, 0.92, 1.0, 0.85)
const FOAM_COLOR := Color(0.95, 0.98, 1.0, 0.9)
## 跌水潭（pool）深水水面和湖岸西沿的世界坐标，画水帘落点用
const POOL_SURFACE := Vector2(6040.0, 100.0)
const LAKE_LIP := Vector2(6560.0, -454.0)


## 一块板的水帘路径（origin 为 Weir 原点，返回本地坐标）：从板上游沿口翻过板顶，
## 落到下一级；下段落进跌水潭水面
static func cascade_path(boards: PackedVector2Array, index: int, origin: Vector2) -> PackedVector2Array:
	var top := boards[index] - origin
	var from := top + Vector2(50.0, -BOARD_SIZE.y - 2.0)
	var over := top + Vector2(-5.0, -BOARD_SIZE.y - 12.0)
	var landing := (
		POOL_SURFACE - origin if index == 0 else boards[index - 1] - origin + Vector2(60.0, 0.0))
	return PackedVector2Array([from, over, landing])


## stage 3 后湖口到上段台阶的一段（本地坐标），把整条阶梯水帘接到湖上
static func lake_cascade_path(boards: PackedVector2Array, origin: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		LAKE_LIP - origin,
		LAKE_LIP - origin + Vector2(-75.0, -10.0),
		boards[boards.size() - 1] - origin + Vector2(60.0, 0.0),
	])


## 画一块堰板：base 是板底边中点。is_blown 时固定 -60° 半透明（溃泄画法不变）；
## 否则按 angle 从站立 0° 到放倒 LOWERED_ANGLE，倒得越多压得越暗；站立时 is_selected 加白框
static func draw_board(canvas: CanvasItem, base: Vector2, angle: float, color: Color, is_selected: bool, is_blown: bool) -> void:
	var rect := Rect2(-BOARD_SIZE.x / 2.0, -BOARD_SIZE.y, BOARD_SIZE.x, BOARD_SIZE.y)
	if is_blown:
		canvas.draw_set_transform(base, deg_to_rad(BLOWN_ANGLE))
		canvas.draw_rect(rect, Color(color, 0.45))
	else:
		canvas.draw_set_transform(base, deg_to_rad(angle))
		var fill := color.lerp(color.darkened(0.45), clampf(angle / LOWERED_ANGLE, 0.0, 1.0))
		canvas.draw_rect(rect, fill)
		if is_selected:
			canvas.draw_rect(rect, Color.WHITE, false, 4.0)
	canvas.draw_set_transform(Vector2.ZERO)


## 画一道水帘：二次贝塞尔 from（上游沿口）→ control（翻过的高点）→ to（落点）。
## alpha 淡入；time 驱动条纹下移和泡沫闪动
static func draw_cascade(canvas: CanvasItem, from: Vector2, control: Vector2, to: Vector2, alpha: float, time: float) -> void:
	var points := PackedVector2Array()
	for step in CURVE_STEPS + 1:
		points.append(_bezier(from, control, to, float(step) / CURVE_STEPS))
	var water := WATER_COLOR
	water.a *= alpha
	canvas.draw_polyline(points, water, CASCADE_WIDTH)
	var stripe := STRIPE_COLOR
	stripe.a *= alpha
	for index in STRIPE_COUNT:
		var t := fmod(time * STRIPE_SPEED + float(index) / STRIPE_COUNT, 1.0)
		canvas.draw_line(
			_bezier(from, control, to, t),
			_bezier(from, control, to, minf(t + STRIPE_LENGTH, 1.0)),
			stripe, 8.0)
	for index in FOAM_COUNT:
		var flicker := 0.7 + 0.3 * sin(time * 9.0 + index * 1.7)
		var foam := FOAM_COLOR
		foam.a *= alpha * flicker
		var radius := 5.0 + 2.5 * sin(time * 7.0 + index * 2.3)
		canvas.draw_circle(to + Vector2((index - 2) * 11.0, -4.0), radius, foam)


static func _bezier(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(c, t).lerp(c.lerp(b, t), t)
