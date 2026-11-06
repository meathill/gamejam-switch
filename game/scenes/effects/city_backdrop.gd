@tool
class_name CityBackdrop
extends Node2D
## 远景城市剪影（程序生成），作为 Parallax2D 的子节点使用。原点在远景地平线。

@export var width: float = 12000.0
@export var seed_value: int = 7
@export var base_color: Color = Color(0.16, 0.18, 0.24)
@export var max_height: float = 700.0
@export var has_lit_window: bool = false

var _buildings: Array[Rect2] = []
var _time: float = 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var x := -400.0
	while x < width:
		var building_width := rng.randf_range(160.0, 380.0)
		var building_height := rng.randf_range(max_height * 0.35, max_height)
		_buildings.append(Rect2(x, -building_height, building_width, building_height + 900.0))
		x += building_width + rng.randf_range(10.0, 60.0)


func _process(delta: float) -> void:
	if has_lit_window and not Engine.is_editor_hint():
		_time += delta
		queue_redraw()


func _draw() -> void:
	var window_color := base_color.lightened(0.12)
	for building in _buildings:
		draw_rect(building, base_color)
		var y := building.position.y + 40.0
		while y < -60.0:
			var x := building.position.x + 24.0
			while x < building.end.x - 40.0:
				draw_rect(Rect2(x, y, 22, 30), window_color)
				x += 56.0
			y += 70.0
	if has_lit_window and _buildings.size() > 6:
		var target := _buildings[6]
		var blink := 0.5 + 0.5 * sin(_time * 3.0)
		var spot := target.position + Vector2(target.size.x / 2.0, 90.0)
		draw_rect(Rect2(spot - Vector2(14, 16), Vector2(28, 32)), Color(1.0, 0.93, 0.6, 0.4 + 0.6 * blink))
		draw_circle(spot, 70.0, Color(1.0, 0.93, 0.6, 0.12 * blink))
