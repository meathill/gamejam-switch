@tool
class_name DrainageStation
extends Machine
## 废弃排水站：前置条件（通常是“排水开关已拉下”）满足后启动。排掉哪片水、救谁，写在关卡数据的 links 里。

const BUILDING_SIZE := Vector2(300, 260)
const OFF_COLOR := Color(0.35, 0.3, 0.3)
const ON_COLOR := Color(0.55, 1.0, 0.7)


func _init() -> void:
	machine_name = "排水站"
	start_delay = 0.8


func _draw() -> void:
	var rect := Rect2(-BUILDING_SIZE.x / 2.0, -BUILDING_SIZE.y, BUILDING_SIZE.x, BUILDING_SIZE.y)
	draw_rect(rect, Color(0.33, 0.35, 0.38))
	draw_rect(Rect2(rect.position + Vector2(40, 60), Vector2(90, 90)), Color(0.2, 0.22, 0.25))
	draw_circle(rect.position + Vector2(85, 105), 36.0, Color(0.45, 0.47, 0.5))
	var is_on := _is_starting
	draw_circle(rect.position + Vector2(220, 60), 22.0, ON_COLOR if is_on else OFF_COLOR)
	if is_on:
		draw_circle(rect.position + Vector2(220, 60), 50.0, Color(ON_COLOR, 0.25))
	draw_rect(Rect2(rect.position + Vector2(180, 140), Vector2(80, 120)), Color(0.25, 0.25, 0.28))
