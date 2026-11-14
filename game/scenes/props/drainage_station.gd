@tool
class_name DrainageStation
extends Node2D
## 废弃排水站：排水槽被雨水灌满（液态深水）后启动，把关联水域的污水排掉一级并净化。原点在地面中点。

const BUILDING_SIZE := Vector2(300, 260)
const OFF_COLOR := Color(0.35, 0.3, 0.3)
const ON_COLOR := Color(0.55, 1.0, 0.7)

@export var channel: WaterZone
@export var drained_zone: WaterZone
@export var message: String = "排水站重新启动了！"

var _is_active: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	channel.state_changed.connect(_on_channel_changed)


func _on_channel_changed(zone: WaterZone) -> void:
	if _is_active or not zone.get_state().is_deep_liquid():
		return
	_is_active = true
	queue_redraw()
	GameState.post_message(message)
	await get_tree().create_timer(0.8).timeout
	var state := drained_zone.get_state()
	drained_zone.transition_to(WaterState.new(maxi(state.level - 1, 0), state.is_frozen, false))


func _draw() -> void:
	var rect := Rect2(-BUILDING_SIZE.x / 2.0, -BUILDING_SIZE.y, BUILDING_SIZE.x, BUILDING_SIZE.y)
	draw_rect(rect, Color(0.33, 0.35, 0.38))
	draw_rect(Rect2(rect.position + Vector2(40, 60), Vector2(90, 90)), Color(0.2, 0.22, 0.25))
	draw_circle(rect.position + Vector2(85, 105), 36.0, Color(0.45, 0.47, 0.5))
	var light := ON_COLOR if _is_active else OFF_COLOR
	draw_circle(rect.position + Vector2(220, 60), 22.0, light)
	if _is_active:
		draw_circle(rect.position + Vector2(220, 60), 50.0, Color(ON_COLOR, 0.25))
	draw_rect(Rect2(rect.position + Vector2(180, 140), Vector2(80, 120)), Color(0.25, 0.25, 0.28))
