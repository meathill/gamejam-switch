@tool
class_name PlantingSpot
extends Interactable
## 可选目标（不计入通关）：先清理垃圾（每按一次 E 清掉一堆），再种下种子，树苗长出来。原点在地面中点。

const TRASH_COLOR := Color(0.36, 0.33, 0.36)
const TRUNK_COLOR := Color(0.45, 0.32, 0.2)
const LEAF_COLOR := Color(0.45, 0.78, 0.4)
const TRASH_SPACING := 110.0
const TREE_HEIGHT := 220.0

@export var trash_count: int = 3:
	set(value):
		trash_count = value
		queue_redraw()
@export var planted_text: String = "种子落进土里，冒出了一点新绿。"

var _cleared: int = 0
var _is_planted: bool = false
var _growth: float = 0.0:
	set(value):
		_growth = value
		queue_redraw()


func _init() -> void:
	prompt_height = 260.0


func _ready() -> void:
	detect_size = Vector2(trash_count * TRASH_SPACING + 260.0, 260.0)
	super()


func get_action_name() -> String:
	return "清理垃圾" if _cleared < trash_count else "种下种子"


func can_interact() -> bool:
	return not _is_planted


func _interact() -> void:
	if _cleared < trash_count:
		_cleared += 1
		queue_redraw()
		if _cleared == trash_count:
			GameState.post_message("垃圾清干净了，露出一小块泥土")
		return
	_is_planted = true
	GameState.post_message(planted_text)
	create_tween().tween_property(self, "_growth", 1.0, 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var start_x := -(trash_count - 1) * TRASH_SPACING / 2.0
	for index in range(_cleared, trash_count):
		var center := Vector2(start_x + index * TRASH_SPACING, -18)
		draw_circle(center, 34.0, TRASH_COLOR)
		draw_rect(Rect2(center + Vector2(-20, -40), Vector2(26, 30)), TRASH_COLOR.lightened(0.15))
	draw_rect(Rect2(-60, -10, 120, 10), Color(0.35, 0.26, 0.18))
	if _growth <= 0.0:
		return
	var height := TREE_HEIGHT * _growth
	draw_line(Vector2.ZERO, Vector2(0, -height), TRUNK_COLOR, 10.0 * _growth)
	draw_circle(Vector2(0, -height), 70.0 * _growth, LEAF_COLOR)
	draw_circle(Vector2(-45, -height * 0.8), 45.0 * _growth, LEAF_COLOR.darkened(0.1))
	draw_circle(Vector2(45, -height * 0.8), 45.0 * _growth, LEAF_COLOR.darkened(0.1))
