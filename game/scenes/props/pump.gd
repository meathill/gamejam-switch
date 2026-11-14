@tool
class_name Pump
extends Machine
## 地下排水泵：水车在 power_gear 档位、其他前置条件（如“动力管拉杆已拉下”）都满足后启动。
## 抽干哪片水、灌溉哪块田、救谁，写在关卡数据的 links 里。

const BODY_SIZE := Vector2(230, 110)
const TEXTURE := preload("res://assets/sprites/farm/pump.png")


func _init() -> void:
	machine_name = "排水泵"


func _get_pipe_offset() -> Vector2:
	return Vector2(0, -BODY_SIZE.y)


func _draw() -> void:
	var rect := Rect2(-BODY_SIZE.x / 2.0, -BODY_SIZE.y, BODY_SIZE.x, BODY_SIZE.y)
	draw_texture_rect(TEXTURE, rect, false)
	var is_ready := Engine.is_editor_hint() or Requirement.first_unmet(requirements).is_empty()
	var light := Color(0.45, 0.85, 0.45) if _is_starting else (Color(1.0, 0.8, 0.3) if is_ready else Color(0.4, 0.25, 0.25))
	draw_circle(rect.position + Vector2(rect.size.x - 40.0, -18.0), 16.0, light)
