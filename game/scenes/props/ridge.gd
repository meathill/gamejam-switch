@tool
class_name Ridge
extends Node2D
## 远山、山脊剪影，没有碰撞。points 是多边形顶点（世界坐标，对象不设 pos），
## snow_y 以上画成积雪色；下半截藏在前景地形后面，就是“后面的雪山”。

const SNOW_COLOR := Color(0.94, 0.95, 1.0)
## 与河谷远景协调的灰紫色
const DEFAULT_COLOR := Color(0.52, 0.49, 0.65)

var points: PackedVector2Array = PackedVector2Array()
var color: Color = DEFAULT_COLOR
## 这条 y 以上画积雪；不设则没有雪
var snow_y: float = INF


func _draw() -> void:
	if points.size() < 3:
		return
	draw_colored_polygon(points, color)
	if snow_y == INF:
		return
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	# 积雪 = 山脊多边形 ∩ 雪线以上的大矩形（交界呈锯齿状再补一条底线不自然，直接用求交结果）
	var cap := PackedVector2Array([
		bounds.position + Vector2(-20, -20),
		Vector2(bounds.end.x + 20, bounds.position.y - 20),
		Vector2(bounds.end.x + 20, snow_y),
		Vector2(bounds.position.x - 20, snow_y),
	])
	for snow: PackedVector2Array in Geometry2D.intersect_polygons(points, cap):
		draw_colored_polygon(snow, SNOW_COLOR)
